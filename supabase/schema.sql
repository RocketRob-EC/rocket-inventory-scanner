-- Rocket Inventory Scanner — Supabase schema
-- Paste this whole file into the Supabase SQL Editor and click "Run".

-- 1. The inventory table
create table if not exists public.items (
  id          uuid primary key default gen_random_uuid(),
  barcode     text not null unique,
  name        text not null,
  sku         text,
  location    text,
  qty         integer not null default 0,
  min_qty     integer not null default 0,
  updated_at  timestamptz not null default now()
);

-- 2. Keep updated_at fresh on every change
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists items_set_updated_at on public.items;
create trigger items_set_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

-- 3. Lock it down: only signed-in users can read or write
alter table public.items enable row level security;

drop policy if exists "authenticated read"   on public.items;
drop policy if exists "authenticated insert" on public.items;
drop policy if exists "authenticated update" on public.items;
drop policy if exists "authenticated delete" on public.items;

create policy "authenticated read"
  on public.items for select
  to authenticated using (true);

create policy "authenticated insert"
  on public.items for insert
  to authenticated with check (true);

create policy "authenticated update"
  on public.items for update
  to authenticated using (true) with check (true);

create policy "authenticated delete"
  on public.items for delete
  to authenticated using (true);

-- 4. Broadcast changes so every device updates live
alter publication supabase_realtime add table public.items;

-- 5. Helpful index for searching by name
create index if not exists items_name_idx on public.items (lower(name));
