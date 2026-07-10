# Demo seed data

Reusable seed that fills a full demo household — **"The Sharma Family"** — with
roughly three months of realistic activity across every feature so you can log
in and see how the app looks and behaves with real data.

## What it creates

- **3 login accounts** (password `Demo@1234` for all):
  | Role     | Email                | Username |
  | -------- | -------------------- | -------- |
  | Owner    | `priya@myplanr.test` | `priya`  |
  | Co-owner | `arjun@myplanr.test` | `arjun`  |
  | Member   | `kavya@myplanr.test` | `kavya`  |
- 2 profile-only family members (grandmother Lakshmi, child Rohan) with detail cards
- All modules enabled (pantry, shopping, expenses, plans, recipes, assets, member details, subscriptions, reminders)
- 15 pantry items (some low / out of stock) with stock-movement history
- ~3 months of expenses (groceries, rent, utilities, transport, medical, entertainment)
- 4 recipes with pantry-linked ingredients
- A shopping list (manual, low-stock and recipe items; some checked)
- 6 home assets with warranties (valid / expiring / expired / none) + service records
- 6 subscriptions (monthly & yearly, active & paused, with reminders)
- 12 plans (open, overdue, completed) across all types and members
- 5 standalone reminders
- 2 medicine schedules for the grandmother

## Run it

```bash
# From the project root
./supabase/seeds/run_seed.sh          # seed
./supabase/seeds/run_seed.sh reset    # remove the demo data
```

The script reads `SUPABASE_POOLER_URL` from `.env` and runs the SQL with `psql`.

You can also run the files directly:

```bash
psql "$SUPABASE_POOLER_URL" -f supabase/seeds/demo_family.sql
psql "$SUPABASE_POOLER_URL" -f supabase/seeds/reset_demo_family.sql
```

## Notes

- **Idempotent** — re-running `demo_family.sql` first deletes the previous demo
  users, which cascades the whole household and its data, then recreates
  everything with the same fixed IDs.
- Must run as the `postgres` role (the pooler URL) so row-level security is
  bypassed for inserts.
- Passwords are hashed with `pgcrypto` (`extensions.crypt`), and each user gets a
  matching `auth.identities` row, so normal email/username + password login works.
- Dates are relative to `now()`, so the data always looks "recent" whenever you
  run it.
