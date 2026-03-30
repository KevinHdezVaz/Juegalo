-- ╔══════════════════════════════════════════════════════╗
-- ║       JUEGALO — Ranking Semanal Migration            ║
-- ╚══════════════════════════════════════════════════════╝
-- Ejecutar en Supabase SQL Editor

-- 1. Columna weekly_coins en users
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS weekly_coins INT DEFAULT 0;

-- 2. Índices para ordenar rankings rápido
CREATE INDEX IF NOT EXISTS idx_users_weekly_coins
  ON public.users (weekly_coins DESC);

CREATE INDEX IF NOT EXISTS idx_users_total_earned
  ON public.users (total_earned DESC);

-- 3. Actualizar credit_coins para también sumar weekly_coins
CREATE OR REPLACE FUNCTION public.credit_coins(
  p_user_id     uuid,
  p_coins       int,
  p_source      text,
  p_description text  DEFAULT NULL,
  p_metadata    jsonb DEFAULT '{}'
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.users
  SET
    coins        = coins + p_coins,
    total_earned = total_earned + p_coins,
    daily_coins  = daily_coins + p_coins,
    weekly_coins = weekly_coins + p_coins,
    last_active  = current_date
  WHERE id = p_user_id;

  INSERT INTO public.transactions (user_id, type, coins, source, description, metadata)
  VALUES (p_user_id, 'earn', p_coins, p_source, p_description, p_metadata);
END;
$$;

-- 4. RPC: premiar top 3 y resetear ranking semanal
--    Llamado por Vercel cron cada lunes a las 00:00 UTC
CREATE OR REPLACE FUNCTION public.award_weekly_winners()
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  winner   RECORD;
  prizes   INT[] := ARRAY[5000, 2000, 1000]; -- 🥇$5  🥈$2  🥉$1
  pos      INT   := 1;
  awarded  jsonb := '[]'::jsonb;
BEGIN
  -- Premiar top 3 (solo si tienen monedas > 0 esta semana)
  FOR winner IN (
    SELECT id, username, weekly_coins
    FROM   public.users
    WHERE  weekly_coins > 0
    ORDER  BY weekly_coins DESC
    LIMIT  3
  ) LOOP
    -- Acreditar premio
    UPDATE public.users
    SET
      coins        = coins + prizes[pos],
      total_earned = total_earned + prizes[pos]
    WHERE id = winner.id;

    -- Registrar transacción
    INSERT INTO public.transactions (user_id, type, coins, source, description)
    VALUES (
      winner.id,
      'bonus',
      prizes[pos],
      'ranking_prize',
      'Premio ranking semanal #' || pos || ' 🏆'
    );

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

-- 5. Política RLS: permitir leer datos de ranking a todos los usuarios autenticados
--    (necesario para mostrar el leaderboard global)
DROP POLICY IF EXISTS "users: ver ranking publico" ON public.users;
CREATE POLICY "users: ver ranking publico" ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

-- (Nota: en Supabase las políticas SELECT se combinan con OR,
--  así que "ver propio" + "ver ranking publico" = todos pueden leer todo)

-- 6. Opcional — pg_cron nativo (si está habilitado en tu proyecto Supabase)
--    Supabase Pro: activar en Dashboard → Database → Extensions → pg_cron
--    SELECT cron.schedule('weekly-reset', '0 0 * * 1', $$SELECT award_weekly_winners()$$);
