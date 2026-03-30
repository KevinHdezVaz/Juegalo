-- ╔══════════════════════════════════════════════════════╗
-- ║     JUEGALO — Migración: Sistema de Referidos        ║
-- ║     Corre esto en Supabase SQL Editor                ║
-- ╚══════════════════════════════════════════════════════╝

-- 1. Nuevas columnas en users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS referral_code     TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS referrals_count   INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS referral_earnings INT DEFAULT 0;

-- 2. Generar códigos para usuarios existentes
UPDATE public.users
SET referral_code = UPPER(SUBSTRING(id::text, 1, 8))
WHERE referral_code IS NULL;

-- 3. Actualizar trigger handle_new_user para generar código automáticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.users (id, email, username, referral_code)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1), 'Jugador'),
    UPPER(SUBSTRING(NEW.id::text, 1, 8))
  );
  RETURN NEW;
END;
$$;

-- 4. RPC: aplicar código de referido
CREATE OR REPLACE FUNCTION public.apply_referral_code(
  p_user_id UUID,
  p_code    TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_referrer_id UUID;
BEGIN
  -- Buscar referidor por código
  SELECT id INTO v_referrer_id
  FROM public.users
  WHERE referral_code = UPPER(TRIM(p_code))
    AND id != p_user_id;

  IF v_referrer_id IS NULL THEN
    RETURN false; -- Código no existe
  END IF;

  -- Verificar que no tenga ya un referidor
  IF (SELECT referred_by FROM public.users WHERE id = p_user_id) IS NOT NULL THEN
    RETURN false;
  END IF;

  -- Asignar referidor
  UPDATE public.users SET referred_by = v_referrer_id WHERE id = p_user_id;

  -- Registrar en tabla referrals
  INSERT INTO public.referrals (referrer_id, referred_id)
  VALUES (v_referrer_id, p_user_id)
  ON CONFLICT (referred_id) DO NOTHING;

  RETURN true;
END;
$$;

-- 5. Actualizar request_cashout para premiar al referidor en el primer cobro
CREATE OR REPLACE FUNCTION public.request_cashout(
  p_user_id        UUID,
  p_coins          INT,
  p_method         TEXT,
  p_account        TEXT,
  p_amount_usd     NUMERIC DEFAULT NULL,
  p_payment_detail TEXT DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_request_id    UUID;
  v_amount        NUMERIC(10,2);
  v_cashout_count INT;
  v_referrer_id   UUID;
  v_bonus_paid    BOOL;
BEGIN
  -- Validar saldo
  IF (SELECT coins FROM public.users WHERE id = p_user_id) < p_coins THEN
    RAISE EXCEPTION 'Saldo insuficiente';
  END IF;

  -- Calcular USD
  v_amount := COALESCE(p_amount_usd, ROUND(p_coins::NUMERIC / 1000, 2));

  -- Descontar monedas
  UPDATE public.users SET coins = coins - p_coins WHERE id = p_user_id;

  -- Crear solicitud (acepta tanto 'account' como 'payment_detail')
  INSERT INTO public.cashout_requests (user_id, coins, amount_usd, method, account)
  VALUES (p_user_id, p_coins, v_amount, p_method, COALESCE(p_payment_detail, p_account, ''))
  RETURNING id INTO v_request_id;

  -- Registrar transacción
  INSERT INTO public.transactions (user_id, type, coins, source, description)
  VALUES (p_user_id, 'cashout', -p_coins, p_method,
          'Cobro de $' || v_amount || ' USD');

  -- ── Lógica de referido: premiar en el primer cobro ─────────────
  SELECT COUNT(*) INTO v_cashout_count
  FROM public.cashout_requests
  WHERE user_id = p_user_id;

  IF v_cashout_count = 1 THEN
    SELECT referred_by INTO v_referrer_id
    FROM public.users WHERE id = p_user_id;

    IF v_referrer_id IS NOT NULL THEN
      SELECT bonus_paid INTO v_bonus_paid
      FROM public.referrals WHERE referred_id = p_user_id;

      IF NOT COALESCE(v_bonus_paid, false) THEN
        -- Acreditar 1,000 monedas al referidor
        PERFORM public.credit_coins(
          v_referrer_id, 1000, 'referral',
          'Tu referido completó su primer cobro'
        );
        -- Actualizar estadísticas
        UPDATE public.users
        SET referrals_count   = referrals_count + 1,
            referral_earnings = referral_earnings + 1000
        WHERE id = v_referrer_id;
        -- Marcar bono como pagado
        UPDATE public.referrals SET bonus_paid = true
        WHERE referred_id = p_user_id;
      END IF;
    END IF;
  END IF;

  RETURN v_request_id;
END;
$$;

-- 6. Política RLS: usuarios pueden ver el referral_code de otros (para validar)
CREATE POLICY "users: ver referral_code" ON public.users
  FOR SELECT USING (true);  -- Necesario para buscar por código
