#!/usr/bin/env bash
# Seed (or reset) the MyPlanr demo family.
#
# Usage:
#   ./supabase/seeds/run_seed.sh          # seed demo_family.sql
#   ./supabase/seeds/run_seed.sh reset    # remove the demo data
#
# Reads SUPABASE_POOLER_URL from the project .env. Requires `psql`.

set -euo pipefail

# Resolve project root (two levels up from this script).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: .env not found at $ENV_FILE" >&2
  exit 1
fi

DB_URL="$(grep -E '^SUPABASE_POOLER_URL=' "$ENV_FILE" | head -n1 | cut -d= -f2-)"
if [[ -z "${DB_URL:-}" ]]; then
  echo "error: SUPABASE_POOLER_URL missing in .env" >&2
  exit 1
fi

# Supabase requires SSL.
if [[ "$DB_URL" != *"sslmode="* ]]; then
  if [[ "$DB_URL" == *"?"* ]]; then
    DB_URL="${DB_URL}&sslmode=require"
  else
    DB_URL="${DB_URL}?sslmode=require"
  fi
fi

if [[ "${1:-seed}" == "reset" ]]; then
  FILE="$SCRIPT_DIR/reset_demo_family.sql"
  echo "Resetting demo family..."
else
  FILE="$SCRIPT_DIR/demo_family.sql"
  echo "Seeding demo family..."
fi

psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$FILE"
echo "Done."
