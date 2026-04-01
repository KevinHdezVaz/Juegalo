-- ╔══════════════════════════════════════════════════════════════╗
-- ║   JUEGALO — Migraciones completas (correr en Supabase)       ║
-- ║   SQL Editor → pegar todo y ejecutar                         ║
-- ║   Se pueden correr varias veces sin error (IF NOT EXISTS)    ║
-- ╚══════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════════
-- 1. COLUMNAS NUEVAS EN USERS
-- ══════════════════════════════════════════════════════════════════

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS weekly_coins      INT  DEFAULT 0,
  ADD COLUMN IF NOT EXISTS referral_code     TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS referrals_count   INT  DEFAULT 0,
  ADD COLUMN IF NOT EXISTS referral_earnings INT  DEFAULT 0;

-- Generar código de referido para usuarios ya existentes
UPDATE public.users
SET referral_code = UPPER(SUBSTRING(id::text, 1, 8))
WHERE referral_code IS NULL;

-- Índices para ranking
CREATE INDEX IF NOT EXISTS idx_users_weekly_coins
  ON public.users (weekly_coins DESC);

CREATE INDEX IF NOT EXISTS idx_users_total_earned
  ON public.users (total_earned DESC);


-- ══════════════════════════════════════════════════════════════════
-- 2. FUNCIÓN: credit_coins (versión completa con weekly_coins)
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.credit_coins(
  p_user_id     UUID,
  p_coins       INT,
  p_source      TEXT,
  p_description TEXT  DEFAULT NULL,
  p_metadata    JSONB DEFAULT '{}'
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users
  SET
    coins        = coins        + p_coins,
    total_earned = total_earned + p_coins,
    daily_coins  = daily_coins  + p_coins,
    weekly_coins = weekly_coins + p_coins,
    last_active  = current_date
  WHERE id = p_user_id;

  INSERT INTO public.transactions (user_id, type, coins, source, description, metadata)
  VALUES (p_user_id, 'earn', p_coins, p_source, p_description, p_metadata);
END;
$$;


-- ══════════════════════════════════════════════════════════════════
-- 3. FUNCIÓN: handle_new_user (genera referral_code al registrarse)
-- ══════════════════════════════════════════════════════════════════

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


-- ══════════════════════════════════════════════════════════════════
-- 4. FUNCIÓN: award_weekly_winners (resetear ranking + premiar top 3)
--    Llamada cada lunes via Vercel cron
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.award_weekly_winners()
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  winner  RECORD;
  prizes  INT[] := ARRAY[5000, 2000, 1000]; -- 🥇$5  🥈$2  🥉$1
  pos     INT   := 1;
  awarded JSONB := '[]'::JSONB;
BEGIN
  FOR winner IN (
    SELECT id, username, weekly_coins
    FROM   public.users
    WHERE  weekly_coins > 0
    ORDER  BY weekly_coins DESC
    LIMIT  3
  ) LOOP
    UPDATE public.users
    SET
      coins        = coins + prizes[pos],
      total_earned = total_earned + prizes[pos]
    WHERE id = winner.id;

    INSERT INTO public.transactions (user_id, type, coins, source, description)
    VALUES (winner.id, 'bonus', prizes[pos], 'ranking_prize',
            'Premio ranking semanal #' || pos || ' 🏆');

    awarded := awarded || jsonb_build_object(
      'rank',         pos,
      'user_id',      winner.id,
      'username',     winner.username,
      'weekly_coins', winner.weekly_coins,
      'prize',        prizes[pos]
    );
    pos := pos + 1;
  END LOOP;

  -- Resetear monedas semanales de todos
  UPDATE public.users SET weekly_coins = 0;

  RETURN awarded;
END;
$$;


-- ══════════════════════════════════════════════════════════════════
-- 5. FUNCIÓN: apply_referral_code
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.apply_referral_code(
  p_user_id UUID,
  p_code    TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_referrer_id UUID;
BEGIN
  SELECT id INTO v_referrer_id
  FROM public.users
  WHERE referral_code = UPPER(TRIM(p_code))
    AND id != p_user_id;

  IF v_referrer_id IS NULL THEN
    RETURN false;
  END IF;

  IF (SELECT referred_by FROM public.users WHERE id = p_user_id) IS NOT NULL THEN
    RETURN false;
  END IF;

  UPDATE public.users SET referred_by = v_referrer_id WHERE id = p_user_id;

  INSERT INTO public.referrals (referrer_id, referred_id)
  VALUES (v_referrer_id, p_user_id)
  ON CONFLICT (referred_id) DO NOTHING;

  RETURN true;
END;
$$;


-- ══════════════════════════════════════════════════════════════════
-- 6. FUNCIÓN: request_cashout (con lógica de referido en primer cobro)
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.request_cashout(
  p_user_id        UUID,
  p_coins          INT,
  p_method         TEXT,
  p_account        TEXT,
  p_amount_usd     NUMERIC DEFAULT NULL,
  p_payment_detail TEXT    DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_request_id    UUID;
  v_amount        NUMERIC(10,2);
  v_cashout_count INT;
  v_referrer_id   UUID;
  v_bonus_paid    BOOL;
BEGIN
  IF (SELECT coins FROM public.users WHERE id = p_user_id) < p_coins THEN
    RAISE EXCEPTION 'Saldo insuficiente';
  END IF;

  v_amount := COALESCE(p_amount_usd, ROUND(p_coins::NUMERIC / 1000, 2));

  UPDATE public.users SET coins = coins - p_coins WHERE id = p_user_id;

  INSERT INTO public.cashout_requests (user_id, coins, amount_usd, method, account)
  VALUES (p_user_id, p_coins, v_amount, p_method,
          COALESCE(p_payment_detail, p_account, ''))
  RETURNING id INTO v_request_id;

  INSERT INTO public.transactions (user_id, type, coins, source, description)
  VALUES (p_user_id, 'cashout', -p_coins, p_method,
          'Cobro de $' || v_amount || ' USD');

  -- Premiar referidor en el primer cobro
  SELECT COUNT(*) INTO v_cashout_count
  FROM public.cashout_requests WHERE user_id = p_user_id;

  IF v_cashout_count = 1 THEN
    SELECT referred_by INTO v_referrer_id
    FROM public.users WHERE id = p_user_id;

    IF v_referrer_id IS NOT NULL THEN
      SELECT bonus_paid INTO v_bonus_paid
      FROM public.referrals WHERE referred_id = p_user_id;

      IF NOT COALESCE(v_bonus_paid, false) THEN
        PERFORM public.credit_coins(
          v_referrer_id, 1000, 'referral',
          'Tu referido completó su primer cobro'
        );
        UPDATE public.users
        SET referrals_count   = referrals_count + 1,
            referral_earnings = referral_earnings + 1000
        WHERE id = v_referrer_id;

        UPDATE public.referrals
        SET bonus_paid = true WHERE referred_id = p_user_id;
      END IF;
    END IF;
  END IF;

  RETURN v_request_id;
END;
$$;


-- ══════════════════════════════════════════════════════════════════
-- 7. RLS — Políticas de seguridad
-- ══════════════════════════════════════════════════════════════════

-- Ranking: todos los usuarios autenticados pueden ver a todos
DROP POLICY IF EXISTS "users: ver ranking publico" ON public.users;
CREATE POLICY "users: ver ranking publico" ON public.users
  FOR SELECT TO authenticated USING (true);

-- Referidos: se puede buscar por referral_code
DROP POLICY IF EXISTS "users: ver referral_code" ON public.users;
CREATE POLICY "users: ver referral_code" ON public.users
  FOR SELECT USING (true);


-- ══════════════════════════════════════════════════════════════════
-- 8. ÍNDICE para deduplicación de postbacks CPX
--    Evita acreditar dos veces la misma transacción CPX
-- ══════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_transactions_cpx_trans_id
  ON public.transactions ((metadata->>'trans_id'))
  WHERE source = 'cpx_research';


-- ══════════════════════════════════════════════════════════════════
-- FIN — Verificar que todo está OK:
--   SELECT routine_name FROM information_schema.routines
--   WHERE routine_schema = 'public' ORDER BY routine_name;
-- ══════════════════════════════════════════════════════════════════
