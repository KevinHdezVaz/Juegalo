-- ╔══════════════════════════════════════════════════════╗
-- ║         JUÉGALO — Schema Supabase PostgreSQL         ║
-- ╚══════════════════════════════════════════════════════╝

-- Usuarios
create table public.users (
  id            uuid primary key references auth.users on delete cascade,
  username      text,
  email         text,
  country_code  text default 'MX',
  coins         int  default 0 check (coins >= 0),
  total_earned  int  default 0,
  daily_coins   int  default 0,
  daily_goal    int  default 1500,
  streak_days   int  default 0,
  last_active   date default current_date,
  referred_by   uuid references public.users(id),
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- Transacciones (historial de monedas)
create table public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users(id) on delete cascade,
  type        text not null check (type in ('earn','cashout','bonus','referral')),
  coins       int  not null,
  source      text, -- 'tapjoy' | 'pollfish' | 'admob' | 'referral' | 'streak'
  description text,
  metadata    jsonb default '{}',
  created_at  timestamptz default now()
);

-- Solicitudes de cobro
create table public.cashout_requests (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users(id) on delete cascade,
  coins        int  not null check (coins >= 1000),
  amount_usd   numeric(10,2) not null,
  method       text not null check (method in ('paypal','mercadopago','oxxo','gift_card')),
  account      text not null,
  status       text default 'pending' check (status in ('pending','processing','paid','rejected')),
  notes        text,
  processed_at timestamptz,
  created_at   timestamptz default now()
);

-- Referidos
create table public.referrals (
  id          uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.users(id) on delete cascade,
  referred_id uuid not null references public.users(id) on delete cascade,
  bonus_paid  bool default false,
  created_at  timestamptz default now(),
  unique (referred_id)
);

-- ── Índices ───────────────────────────────────────────────────────
create index on public.transactions (user_id, created_at desc);
create index on public.cashout_requests (user_id, status);

-- ── Función: actualizar updated_at ───────────────────────────────
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger on_user_updated
  before update on public.users
  for each row execute procedure public.handle_updated_at();

-- ── Función: crear usuario al registrarse ─────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.users (id, email, username)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── Función: acreditar monedas (ACID) ────────────────────────────
create or replace function public.credit_coins(
  p_user_id    uuid,
  p_coins      int,
  p_source     text,
  p_description text default null,
  p_metadata   jsonb default '{}'
)
returns void language plpgsql security definer as $$
begin
  -- Actualizar balance
  update public.users
  set
    coins        = coins + p_coins,
    total_earned = total_earned + p_coins,
    daily_coins  = daily_coins + p_coins,
    last_active  = current_date
  where id = p_user_id;

  -- Registrar transacción
  insert into public.transactions (user_id, type, coins, source, description, metadata)
  values (p_user_id, 'earn', p_coins, p_source, p_description, p_metadata);
end;
$$;

-- ── Función: solicitar cobro ──────────────────────────────────────
create or replace function public.request_cashout(
  p_user_id   uuid,
  p_coins     int,
  p_method    text,
  p_account   text
)
returns uuid language plpgsql security definer as $$
declare
  v_request_id uuid;
  v_amount     numeric(10,2);
begin
  -- Validar saldo suficiente
  if (select coins from public.users where id = p_user_id) < p_coins then
    raise exception 'Saldo insuficiente';
  end if;

  -- Calcular USD
  v_amount := round(p_coins::numeric / 1000, 2);

  -- Descontar monedas
  update public.users set coins = coins - p_coins where id = p_user_id;

  -- Crear solicitud
  insert into public.cashout_requests (user_id, coins, amount_usd, method, account)
  values (p_user_id, p_coins, v_amount, p_method, p_account)
  returning id into v_request_id;

  -- Registrar transacción
  insert into public.transactions (user_id, type, coins, source, description)
  values (p_user_id, 'cashout', -p_coins, p_method, 'Cobro de $' || v_amount || ' USD');

  return v_request_id;
end;
$$;

-- ── RLS (Row Level Security) ──────────────────────────────────────
alter table public.users            enable row level security;
alter table public.transactions     enable row level security;
alter table public.cashout_requests enable row level security;
alter table public.referrals        enable row level security;

-- Políticas: cada usuario solo ve y modifica sus propios datos
create policy "users: ver propio" on public.users
  for select using (auth.uid() = id);
create policy "users: actualizar propio" on public.users
  for update using (auth.uid() = id);

create policy "transactions: ver propias" on public.transactions
  for select using (auth.uid() = user_id);

create policy "cashout: ver propias" on public.cashout_requests
  for select using (auth.uid() = user_id);

create policy "referrals: ver propios" on public.referrals
  for select using (auth.uid() = referrer_id or auth.uid() = referred_id);
