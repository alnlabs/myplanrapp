# MyPlanr

Family home manager — track pantry stock, plan recipes, manage expenses, and build shopping lists together.

## Features

- **Pantry** — add items, log usage, restock, low-stock alerts
- **Recipes** — save recipes, cook-check against pantry stock
- **Expenses** — household spending with monthly summary
- **Shop list** — manual items + generate from low stock or recipes
- **Family** — shared household with member invites

## Stack

- Flutter + Riverpod + go_router
- Supabase (Auth, Postgres, RLS)
- Local notifications for low-stock alerts

## Setup

### 1. Supabase project

1. Create a project at [supabase.com](https://supabase.com)
2. Copy `.env.example` → `.env` and set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_DB_PASSWORD`
3. Push migrations:

```bash
./scripts/supabase_push.sh
```

Or install the [Supabase CLI](https://github.com/supabase/cli/releases) and run `supabase db push` with your database URL.

4. Enable Email auth in Authentication → Providers

5. **Fix auth email links** (required for mobile — stops `localhost` in confirmation emails):

   In Supabase Dashboard → **Authentication** → **URL Configuration**:

   - **Site URL:** `com.alnlabs.myplanr://login-callback`
   - **Redirect URLs** (add both):
     - `com.alnlabs.myplanr://login-callback`
     - `com.alnlabs.myplanr://login-callback/**`

   The app passes this deep link on sign-up and password reset. Tapping the email link opens MyPlanr and completes verification.

### 2. App config

```bash
cp .env.example .env
```

Edit `.env` with your Supabase URL and anon key:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 3. Run

```bash
flutter pub get
flutter run
```

## Smoke test

1. Register → create family household
2. Add **Dal** 1 kg, low-stock alert at 200 g
3. Use 800 g → check **Low stock** under More
4. Add grocery expense (optionally restock pantry)
5. Create a recipe → **Can I cook this?** → add missing to shop list

## Project structure

```
lib/
  core/          # theme, router, env, labels
  features/      # auth, pantry, recipes, expenses, shopping, alerts
  shared/        # models, widgets, utils
supabase/
  migrations/    # database schema + RLS + RPCs
```
