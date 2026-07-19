#!/usr/bin/env bash
# Push local supabase/migrations to the remote Supabase project.
# Uses direct DB URL (no `supabase login` required).
#
# Requires: Supabase CLI in ~/.local/share/supabase (see README)
#           .env with SUPABASE_URL and .env.server with SUPABASE_DB_PASSWORD

set -euo pipefail
cd "$(dirname "$0")/.."

export PATH="$HOME/.local/share/supabase:${PATH}"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI not found."
  echo "Install: curl -sL https://github.com/supabase/cli/releases/latest/download/supabase_2.109.0_darwin_arm64.tar.gz | tar -xzf - -C ~/.local/share/supabase"
  exit 1
fi

set -a
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source .env
fi
# Server-only secrets (DB password, SMTP) live here and are never bundled.
if [[ -f .env.server ]]; then
  # shellcheck disable=SC1091
  source .env.server
fi
set +a

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_DB_PASSWORD:-}" ]]; then
  echo "Set SUPABASE_URL and SUPABASE_DB_PASSWORD in .env"
  exit 1
fi

PROJECT_REF="${SUPABASE_URL#https://}"
PROJECT_REF="${PROJECT_REF%%.supabase.co}"

if [[ -n "${SUPABASE_DB_URL:-}" ]]; then
  DB_URL="$SUPABASE_DB_URL"
else
  # Migrations must use the direct connection (5432). The pooler (6543) breaks
  # prepared statements with: "lrupsc_1_0 already exists".
  DB_URL="postgresql://postgres:${SUPABASE_DB_PASSWORD}@db.${PROJECT_REF}.supabase.co:5432/postgres"
fi

echo "Using DB host: ${DB_URL#*@}"

supabase db push --db-url "$DB_URL" --yes
echo "Done. Check: supabase migration list --db-url \"\$DB_URL\""
