#!/usr/bin/env bash
#
# Start `flutter run` for every currently running iOS/Android emulator,
# each in its own zellij tab of a fresh session, so the logs stay separate.
#
# Usage: scripts/run_emulators.sh [-s SESSION] [-w SECONDS] [-f] [-- <extra flutter run args>]
#
#   -s SESSION   zellij session name (default: twonly-run)
#   -w SECONDS   stagger between device starts, avoids build-dir races (default: 15)
#   -f           kill an existing session with the same name instead of aborting
#
# Everything after `--` is appended to each `flutter run` invocation,
# e.g. `scripts/run_emulators.sh -- --flavor dev --dart-define=FOO=bar`

set -euo pipefail

SESSION="twonly-run"
STAGGER=15
FORCE=0

while getopts ":s:w:fh" opt; do
  case "$opt" in
    s) SESSION="$OPTARG" ;;
    w) STAGGER="$OPTARG" ;;
    f) FORCE=1 ;;
    h) sed -n '2,15p' "$0"; exit 0 ;;
    \?) echo "unknown option: -$OPTARG" >&2; exit 2 ;;
    :) echo "option -$OPTARG needs an argument" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

case "$STAGGER" in
  ''|*[!0-9]*) echo "-w needs a non-negative whole number of seconds" >&2; exit 2 ;;
esac

for bin in zellij flutter jq; do
  command -v "$bin" >/dev/null || { echo "missing required tool: $bin" >&2; exit 1; }
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZELLIJ_CONFIG="${ZELLIJ_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/zellij/config.kdl}"

# zellij keeps EXITED sessions around to be resurrected, and they still show up
# in `list-sessions`. Only a genuinely live session should block a fresh start.
SESSION_STATE="$(
  zellij list-sessions -n 2>/dev/null \
    | awk -v s="$SESSION" '$1 == s { print (index($0, "EXITED") ? "exited" : "live"); found = 1 }
                           END { if (!found) print "none" }'
)"

case "$SESSION_STATE" in
  exited)
    echo "clearing exited session '$SESSION'..."
    zellij delete-session --force "$SESSION" >/dev/null 2>&1 || true
    ;;
  live)
    if [ "$FORCE" -eq 1 ]; then
      echo "killing live session '$SESSION'..."
      zellij kill-session "$SESSION" >/dev/null 2>&1 || true
      zellij delete-session --force "$SESSION" >/dev/null 2>&1 || true
    else
      echo "zellij session '$SESSION' is already running. Attach with:" >&2
      echo "  zellij attach $SESSION" >&2
      echo "or re-run with -f to replace it." >&2
      exit 1
    fi
    ;;
esac

echo "querying flutter devices..."
DEVICES_JSON="$(flutter devices --machine)"

# Only running emulators/simulators on the ios or android platforms.
# bash 3.2 (macOS default) has no mapfile, so read the lines manually.
DEVICES=()
while IFS= read -r line; do
  [ -n "$line" ] && DEVICES[${#DEVICES[@]}]="$line"
done < <(
  printf '%s' "$DEVICES_JSON" | jq -r '
    .[]
    | select(.emulator == true and .isSupported == true)
    | select(.targetPlatform | test("^(ios|android)"))
    | "\(.id)\t\(.name)\t\(.targetPlatform)"
  '
)

if [ "${#DEVICES[@]}" -eq 0 ]; then
  echo "no running iOS or Android emulators found." >&2
  echo "start one first, e.g. 'flutter emulators --launch <id>' or open Simulator.app." >&2
  exit 1
fi

RUNDIR="$(mktemp -d "${TMPDIR:-/tmp}/twonly-run-XXXXXX")"
LAYOUT="$RUNDIR/layout.kdl"

# A custom layout replaces zellij's default UI, so re-declare the default tab
# template -- without it the tab bar and status bar are gone and the tabs,
# although they exist, are invisible and unswitchable-looking.
if grep -qE '^[[:space:]]*default_layout[[:space:]]+"compact"' "$ZELLIJ_CONFIG" 2>/dev/null; then
  TAB_TEMPLATE='    default_tab_template {
        children
        pane size=1 borderless=true {
            plugin location="zellij:compact-bar"
        }
    }'
else
  TAB_TEMPLATE='    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }'
fi

{
  echo 'layout {'
  echo "$TAB_TEMPLATE"
} > "$LAYOUT"

index=0
USED_NAMES=()
for entry in "${DEVICES[@]}"; do
  id="${entry%%	*}"
  rest="${entry#*	}"
  name="${rest%%	*}"
  platform="${rest#*	}"

  # Two clones of the same emulator image share a name, so identify Android
  # tabs by their (unique) adb id and fall back to a counter elsewhere.
  case "$platform" in
    ios*) label="ios-$name" ;;
    *) label="android-$id" ;;
  esac
  # tab names must survive KDL quoting; keep them boring
  tab_name="$(printf '%s' "$label" | tr -c 'A-Za-z0-9._-' '-' | cut -c1-30)"
  suffix=2
  while printf '%s\n' ${USED_NAMES+"${USED_NAMES[@]}"} | grep -qx "$tab_name"; do
    tab_name="$(printf '%s' "$label" | tr -c 'A-Za-z0-9._-' '-' | cut -c1-27)-$suffix"
    suffix=$((suffix + 1))
  done
  USED_NAMES[${#USED_NAMES[@]}]="$tab_name"

  wrapper="$RUNDIR/run-$index.sh"
  {
    echo '#!/usr/bin/env bash'
    printf 'cd %q\n' "$PROJECT_ROOT"
    if [ "$index" -gt 0 ] && [ "$STAGGER" -gt 0 ]; then
      delay=$((index * STAGGER))
      printf 'echo "waiting %ss so the builds do not fight over the build directory..."\n' "$delay"
      printf 'sleep %s\n' "$delay"
    fi
    printf 'echo "=== %s (%s) ==="\n' "$name" "$id"
    printf 'exec flutter run -d %q' "$id"
    for arg in "$@"; do printf ' %q' "$arg"; done
    printf '\n'
  } > "$wrapper"
  chmod +x "$wrapper"

  {
    printf '    tab name="%s" {\n' "$tab_name"
    printf '        pane command="bash" {\n'
    printf '            args "%s"\n' "$wrapper"
    printf '        }\n'
    printf '    }\n'
  } >> "$LAYOUT"

  echo "  tab '$tab_name' -> $id"
  index=$((index + 1))
done

echo '}' >> "$LAYOUT"

echo "starting zellij session '$SESSION' with $index tab(s)..."
exec zellij --session "$SESSION" --new-session-with-layout "$LAYOUT"
