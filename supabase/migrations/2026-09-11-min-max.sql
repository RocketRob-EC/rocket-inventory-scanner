-- Migration: min/max stock levels. Req/par becomes Min (reorder point);
-- add Max (fill-to). Seed Max = current Min so existing behavior is unchanged.
alter table public.items add column if not exists max_qty integer not null default 0;
update public.items set max_qty = min_qty where max_qty < min_qty;
