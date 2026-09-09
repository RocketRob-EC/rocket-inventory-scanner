# Rocket Inventory Scanner

Camera-based barcode inventory for Rocket Cooling. Scan a barcode with a phone or
tablet to add/remove stock and see live counts, backed by a shared Supabase database.

- **Design spec:** [`docs/superpowers/specs/2026-09-09-inventory-scanner-design.md`](docs/superpowers/specs/2026-09-09-inventory-scanner-design.md)
- **Stack:** static web app (HTML/JS) + Supabase (Postgres/Auth/Realtime), hosted on Vercel.

## Setup

1. Create a Supabase project and run [`supabase/schema.sql`](supabase/schema.sql).
2. Put your Supabase URL + anon key in [`config.js`](config.js).
3. Deploy to Vercel (auto-deploys from this repo).

`config.js` is committed on purpose: this is a private repo, and the Supabase
**anon** key is a public client identifier — it grants nothing without a signed-in
session, because Row Level Security requires authentication. Never commit the
`service_role` key (we don't use it here).
