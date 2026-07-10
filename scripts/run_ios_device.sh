#!/usr/bin/env bash
# Run MyPlanr on a physical iPhone.
#
# iOS 26 blocks Dart JIT in debug mode on real devices (mprotect error).
# Use profile (default) or release instead. Simulator can still use debug.
#
# Usage:
#   ./scripts/run_ios_device.sh                  # list devices, run on first iPhone
#   ./scripts/run_ios_device.sh <device-id>      # profile mode
#   ./scripts/run_ios_device.sh <device-id> release

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${2:-profile}"
if [[ "$MODE" != "profile" && "$MODE" != "release" ]]; then
  echo "error: mode must be 'profile' or 'release' (got '$MODE')" >&2
  exit 1
fi

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  echo "Available devices:"
  flutter devices
  echo ""
  DEVICE_ID="$(flutter devices --machine 2>/dev/null | python3 -c "
import json, sys
for d in json.load(sys.stdin):
    if d.get('platform') == 'ios' and not d.get('emulator', True):
        print(d['id'])
        break
" 2>/dev/null || true)"
  if [[ -z "$DEVICE_ID" ]]; then
    echo "Pass a device id: ./scripts/run_ios_device.sh <device-id> [$MODE]"
    exit 1
  fi
  echo "Using physical iPhone: $DEVICE_ID"
fi

echo "Running in $MODE mode (required on iOS 26 physical devices)..."
flutter run --"$MODE" -d "$DEVICE_ID"
