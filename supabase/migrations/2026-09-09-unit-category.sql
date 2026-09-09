-- Migration: van stock-count model — items carry a unit of measure and a category.
-- Req (par level) maps to min_qty; "short" = qty <= min_qty.
alter table public.items add column if not exists unit text;
alter table public.items add column if not exists category text;
create index if not exists items_category_idx on public.items (category);
