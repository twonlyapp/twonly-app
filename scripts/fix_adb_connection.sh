#!/usr/bin/env bash
#
# Recover an Android wireless-debugging connection when `adb connect` fails
# even though the device's TCP port is reachable. If Android has forgotten the
# host certificate, the script guides you through pairing again.
#
# Usage:
#   scripts/fix_adb_connection.sh [PORT]
#   scripts/fix_adb_connection.sh [HOST:PORT]
#
# The defaults below are the most recently used development device.

set -u

DEFAULT_HOST="10.99.0.213"
DEFAULT_PORT="34483"
MAX_ATTEMPTS=3

usage() {
  sed -n '2,10p' "$0"
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

HOST="$DEFAULT_HOST"
PORT="$DEFAULT_PORT"

if [ "$#" -gt 2 ]; then
  usage >&2
  exit 2
fi

if [ "$#" -eq 2 ]; then
  HOST="$1"
  PORT="$2"
elif [ "$#" -eq 1 ]; then
  case "$1" in
    *:*)
      HOST="${1%:*}"
      PORT="${1##*:}"
      ;;
    *[!0-9]*) HOST="$1" ;;
    *) PORT="$1" ;;
  esac
fi

case "$PORT" in
  ''|*[!0-9]*)
    echo "invalid port: $PORT" >&2
    exit 2
    ;;
esac

if [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  echo "port must be between 1 and 65535" >&2
  exit 2
fi

command -v nc >/dev/null || {
  echo "missing required tool: nc" >&2
  exit 1
}

# Prefer the platform-tools installation used by Flutter/Android Studio. Using
# a Homebrew adb client against an Android SDK adb daemon (or vice versa) makes
# daemon ownership and diagnostics unnecessarily unpredictable.
if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]; then
  ADB="$ANDROID_SDK_ROOT/platform-tools/adb"
elif [ -n "${ANDROID_HOME:-}" ] && [ -x "$ANDROID_HOME/platform-tools/adb" ]; then
  ADB="$ANDROID_HOME/platform-tools/adb"
elif [ -x "$HOME/Library/Android/sdk/platform-tools/adb" ]; then
  ADB="$HOME/Library/Android/sdk/platform-tools/adb"
else
  ADB="$(command -v adb || true)"
fi

if [ -z "$ADB" ]; then
  echo "missing required tool: adb" >&2
  exit 1
fi

ENDPOINT="$HOST:$PORT"

echo "Checking $ENDPOINT directly..."
if [ "$(uname -s)" = "Darwin" ]; then
  NC_ARGS=(-G 3 -z)
else
  NC_ARGS=(-w 3 -z)
fi

if ! nc "${NC_ARGS[@]}" "$HOST" "$PORT" >/dev/null 2>&1; then
  echo "The TCP port is not reachable, so restarting ADB cannot fix it." >&2
  echo "Check that Wireless debugging is enabled and that $PORT is the current connection port." >&2
  exit 1
fi
echo "TCP port is reachable."

# Prevent Bonjour/mDNS from adding a second transport for the same device while
# this script establishes the explicit host:port connection.
export ADB_MDNS_AUTO_CONNECT=0

LAST_OUTPUT=""
PAIRING_REQUIRED=0
ADB_LOG="${TMPDIR:-/tmp}/adb.$(id -u).log"
attempt=1
while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  echo "ADB reconnect attempt $attempt/$MAX_ATTEMPTS..."

  # `adb kill-server` sometimes leaves the macOS daemon alive. Killing only
  # this user's exact `adb` processes clears that stale network-permission
  # state without requiring sudo or affecting other users.
  "$ADB" kill-server >/dev/null 2>&1 || true
  pkill -x -u "$(id -u)" adb >/dev/null 2>&1 || true

  "$ADB" start-server >/dev/null 2>&1
  "$ADB" disconnect "$ENDPOINT" >/dev/null 2>&1 || true

  LAST_OUTPUT="$("$ADB" connect "$ENDPOINT" 2>&1)"
  echo "$LAST_OUTPUT"

  if "$ADB" -s "$ENDPOINT" get-state 2>/dev/null | grep -qx device; then
    echo
    echo "Connected successfully: $ENDPOINT"
    "$ADB" -s "$ENDPOINT" shell getprop ro.product.model 2>/dev/null \
      | sed 's/^/Device: /'
    exit 0
  fi

  if [ -f "$ADB_LOG" ] \
    && tail -80 "$ADB_LOG" | grep -qE 'CERTIFICATE_UNKNOWN|certificate unknown'; then
    PAIRING_REQUIRED=1
    break
  fi

  attempt=$((attempt + 1))
  [ "$attempt" -le "$MAX_ATTEMPTS" ] && sleep 1
done

if [ "$PAIRING_REQUIRED" -eq 1 ]; then
  echo
  echo "Android rejected this computer's ADB certificate. Pairing is required."
  echo "On the phone, open:"
  echo "  Settings > System > Developer options > Wireless debugging"
  echo "  Pair device with pairing code"

  if [ ! -t 0 ]; then
    echo "Run this script in an interactive terminal to enter the pairing port and code." >&2
    exit 1
  fi

  printf "Pairing port: "
  IFS= read -r PAIRING_PORT
  case "$PAIRING_PORT" in
    ''|*[!0-9]*)
      echo "invalid pairing port: $PAIRING_PORT" >&2
      exit 2
      ;;
  esac
  if [ "$PAIRING_PORT" -lt 1 ] || [ "$PAIRING_PORT" -gt 65535 ]; then
    echo "pairing port must be between 1 and 65535" >&2
    exit 2
  fi

  printf "Pairing code: "
  IFS= read -r PAIRING_CODE
  case "$PAIRING_CODE" in
    ''|*[!0-9]*)
      echo "invalid pairing code" >&2
      exit 2
      ;;
  esac

  PAIR_OUTPUT="$(printf '%s\n' "$PAIRING_CODE" | "$ADB" pair "$HOST:$PAIRING_PORT" 2>&1)"
  PAIRING_CODE=""
  echo "$PAIR_OUTPUT"
  if ! printf '%s' "$PAIR_OUTPUT" | grep -q "Successfully paired"; then
    echo "Pairing failed. Reopen the pairing dialog for a fresh port and code." >&2
    exit 1
  fi

  LAST_OUTPUT="$("$ADB" connect "$ENDPOINT" 2>&1)"
  echo "$LAST_OUTPUT"
  if "$ADB" -s "$ENDPOINT" get-state 2>/dev/null | grep -qx device; then
    echo
    echo "Paired and connected successfully: $ENDPOINT"
    "$ADB" -s "$ENDPOINT" shell getprop ro.product.model 2>/dev/null \
      | sed 's/^/Device: /'
    exit 0
  fi

  echo "Pairing succeeded, but the connection port failed. Check that $PORT is still current." >&2
  exit 1
fi

echo >&2
echo "ADB could not connect after $MAX_ATTEMPTS clean restarts." >&2
if printf '%s' "$LAST_OUTPUT" | grep -q "No route to host"; then
  echo "The port is reachable, but the ADB daemon is being denied local-network access." >&2
  if [ "$(uname -s)" = "Darwin" ]; then
    echo "Toggle your terminal app under System Settings > Privacy & Security > Local Network," >&2
    echo "then run this script again." >&2
  fi
fi
exit 1
