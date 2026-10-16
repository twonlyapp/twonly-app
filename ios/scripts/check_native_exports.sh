#!/bin/sh
set -eu

# Rust finds these Swift C entry points with dlsym(RTLD_DEFAULT). An internal
# @_cdecl function can disappear during release optimization, even though the
# source compiled successfully. Archive stripping can also remove public entry
# points after build phases have finished. Check exports before and after the
# configured strip operation, not just the unstripped link product.
# Debug builds put app code in Runner.debug.dylib; runtime XCTest covers those.
if [ "${CONFIGURATION:-Release}" = "Debug" ]; then
  exit 0
fi

check_exports() {
  checked_binary=$1
  exports=$(xcrun dyld_info -exports "$checked_binary")
  missing=0
  for symbol in \
  twonly_schedule_direct_media_uploads \
  twonly_begin_background_task \
  twonly_end_background_task \
  twonly_decode_image_to_png \
  twonly_extract_sticker_foreground \
  twonly_render_video \
  twonly_extract_video_frame \
  twonly_save_to_gallery \
  twonly_current_location
  do
    if ! printf '%s\n' "$exports" | awk '{print $NF}' | grep -qx "_$symbol"; then
      echo "error: Rust cannot resolve $symbol in $checked_binary. Swift C callbacks must be public and archive stripping must preserve global symbols." >&2
      missing=1
    fi
  done
  return "$missing"
}

binary=${1:?Usage: check_native_exports.sh path/to/Runner}
check_exports "$binary"

# The normal Release build does not strip Runner, but Archive does. Exercise
# that final step during either build so a passing build cannot hide the bug.
# -T also exercises Swift-symbol stripping used when exporting for App Store.
temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/twonly-native-exports.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM
case "${STRIP_STYLE:-all}" in
  all) strip_flag= ;;
  non-global) strip_flag=-x ;;
  debugging) strip_flag=-S ;;
  *) echo "error: Unsupported STRIP_STYLE: $STRIP_STYLE" >&2; exit 1 ;;
esac
if [ -n "$strip_flag" ]; then
  xcrun strip -D -T "$strip_flag" -o "$temporary_dir/Runner" "$binary"
else
  xcrun strip -D -T -o "$temporary_dir/Runner" "$binary"
fi
check_exports "$temporary_dir/Runner"
