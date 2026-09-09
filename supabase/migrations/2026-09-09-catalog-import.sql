-- Migration: support CSV catalog import keyed on part number (sku).
-- Run once in the Supabase SQL Editor on an existing project.

-- Barcodes are attached later by scanning, so they are now optional.
alter table public.items alter column barcode drop not null;

-- Part number becomes the catalog key for import upserts. Unique index allows
-- multiple NULLs, so items added purely by scanning (no part #) still coexist.
create unique index if not exists items_sku_key on public.items (sku);
