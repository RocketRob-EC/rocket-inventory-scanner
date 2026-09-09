# Rocket Inventory Scanner — Design Spec

**Date:** 2026-09-09
**Owner:** Rob Stanford (Rocket Cooling)
**Status:** Approved design, pre-implementation

## Purpose

A camera-based barcode inventory app for Rocket Cooling. Staff scan a barcode
with a phone or tablet camera to add stock, remove stock, and see current counts.
Data lives in a shared cloud database so every device sees the same, live numbers.

## Goals

- Scan barcodes with a device camera (no dedicated scanner hardware required).
- Add new items and adjust quantities in seconds.
- One shared, permanent database across all devices.
- Flag items that need reordering (low stock).
- Installable to a phone home screen; works on iOS and Android.

## Non-goals (this version)

- Multiple stock locations / per-truck inventory (planned as a later phase).
- Individual user accounts and per-user audit trail (using one shared login).
- Purchase orders, supplier integration, cost/valuation reporting.
- Offline-first / sync queue (requires network to read and write).

## Decisions

| Decision | Choice |
|----------|--------|
| Access model | One shared team login (Supabase Auth email/password) |
| Fields tracked | name, barcode, sku (part #), location/bin, qty, min_qty |
| Locations | Single location |
| Source of truth | Private GitHub repo |
| Hosting | Vercel, auto-deploy from GitHub |
| Database | Supabase (free tier) |

## Architecture

```
Phone/Tablet browser
  └─ Static web app (HTML/JS, hosted on Vercel)
       ├─ ZXing (camera barcode decoding, from CDN)
       └─ Supabase JS client (auth + data + realtime, from CDN)
            └─ Supabase project (Postgres + Auth + Realtime)
```

- **Frontend:** a static site (no build server). Vercel serves it over HTTPS,
  which is what unlocks camera access. Config (Supabase URL + anon key) lives in
  a small `config.js`.
- **Auth:** Supabase Auth with a single shared account. The login screen gates
  the app; the session persists so the team logs in rarely.
- **Security:** Row Level Security (RLS) is ON. Policies allow full read/write
  only to the `authenticated` role. The anon key shipped in the client is a
  public identifier — it grants nothing without a valid signed-in session.
- **Realtime:** subscribe to `items` changes so counts update live across devices.

## Data model

Single table `items`:

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | primary key, default gen_random_uuid() |
| barcode | text | unique, not null — the scanned value |
| name | text | not null |
| sku | text | manufacturer/internal part number, nullable |
| location | text | shelf/bin, nullable |
| qty | integer | not null, default 0 |
| min_qty | integer | not null, default 0 — reorder point |
| updated_at | timestamptz | default now(), set on every write |

Low stock = `qty <= min_qty` (and `min_qty > 0`).

## Screens & flow

1. **Login** — shared email + password → Supabase session (persisted).
2. **Scan** — camera (ZXing) or manual barcode entry.
   - Barcode found → action sheet: adjust qty (±), edit fields.
   - Barcode new → action sheet: name, part #, location, starting qty, min qty → insert.
3. **Inventory list** — searchable; low-stock rows flagged; inline qty ±, edit, delete; live-updating.
4. **Low-stock filter** — one tap to list everything at/below its reorder point, with a count badge.

## Error handling

- **Camera blocked/unavailable** → fall back to manual barcode entry (always visible).
- **Network error on write** → show a clear error, keep the sheet input, offer retry; no silent data loss.
- **Duplicate barcode on insert** → unique constraint caught → switch to "adjust existing".
- **Auth expired** → return to login screen.

## Testing

Static app with thin logic; validation is primarily a manual smoke checklist run
on a phone and a desktop:

- Login with shared credentials; session persists on reload.
- Scan a known barcode → adjust qty → count updates and persists.
- Scan an unknown barcode → add item → appears in list.
- Manual entry path works when camera is denied.
- Low-stock flag appears when qty drops to/below min_qty.
- Second device sees changes live.

Any extracted pure logic (e.g. low-stock computation, barcode normalization) gets
small unit tests.

## One-time setup (Rob)

1. Create a free Supabase account + project.
2. Run the provided SQL (creates `items`, enables RLS, adds policies).
3. Create the shared login user in the Supabase dashboard.
4. Send Project URL + anon public key (both safe to share).

Then: connect the GitHub repo to Vercel (two approvals) → live URL.

## Future phases

- Per-location / per-truck quantities.
- Individual accounts + who-changed-what history.
- Reorder reports / export.
- CSV import to seed the catalog.
