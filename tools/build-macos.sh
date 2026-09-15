#!/usr/bin/env bash
# Compile an MQL5 source file with MetaEditor under the MetaQuotes-bundled Wine
# on macOS.
#
# Usage:  ./tools/build-macos.sh [path/to/File.mq5] [--install]
#
#   With no path the repository's FXNews.mq5 is compiled. --install copies the
#   resulting FXNews.ex5 into the terminal's MQL5/Indicators/FXNews/ folder
#   after a clean build (that folder is the terminal's live copy).
#
# Exit codes:
#   0  clean compile (0 errors, 0 warnings)
#   1  the compiler reported errors or warnings
#   2  environment problem (missing source, wine, MetaEditor, path with a space)
#   3  MetaEditor produced no result line
#   4  MetaEditor did not finish within BUILD_TIMEOUT seconds (default 300)
set -uo pipefail

SRC=""
INSTALL=0
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=1 ;;
    -h | --help)
      sed -n '2,19p' "$0"
      exit 0
      ;;
    *) SRC="$arg" ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 2

if [ -z "$SRC" ]; then
  # tools/ sits directly under the repository root; git resolves it in a clone,
  # the fallback covers an exported tree.
  ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || dirname "$HERE")"
  SRC="$ROOT/FXNews.mq5"
fi
[ -f "$SRC" ] || {
  echo "build: no such source file: $SRC" >&2
  exit 2
}
SRC_DIR="$(cd "$(dirname "$SRC")" && pwd)" || {
  echo "build: cannot resolve $SRC" >&2
  exit 2
}
SRC="$SRC_DIR/$(basename "$SRC")"

# Paths and Wine/Rosetta handling live in one place, shared with selftest-macos.sh.
# shellcheck source=tools/lib-mt5.sh
. "$HERE/lib-mt5.sh" || {
  echo "build: cannot load $HERE/lib-mt5.sh" >&2
  exit 2
}
mt5_configure
BUILD_TIMEOUT="${BUILD_TIMEOUT:-300}"

[ -x "$WINE" ] || {
  echo "build: wine64 not found at $WINE" >&2
  exit 2
}
[ -f "$ME" ] || {
  echo "build: MetaEditor64.exe not found at $ME" >&2
  exit 2
}
mt5_require_wine "build"

# The work directory is created under a space-free location: MetaEditor's
# /compile: and /log: switches cannot handle a path containing a space (they
# exit silently, write no log and report no error; verified in isolation on
# 2026-08-13). The /inc: path below does contain spaces and works, so only the
# source and log paths are guarded. Compiling in place under
# "MQL5/Indicators/..." is therefore impossible; compile from the repository
# and copy the .ex5 across (see --install), or press F7 in MetaEditor.
WORK="$(mktemp -d /tmp/mql5build.XXXXXX)" || {
  echo "build: mktemp failed" >&2
  exit 2
}
trap 'rm -rf "$WORK"' EXIT
LOG="$WORK/build.log"
for guarded in "$SRC" "$LOG"; do
  case "$guarded" in
    *\ *)
      echo "build: MetaEditor cannot compile a path containing a space:" >&2
      echo "         $guarded" >&2
      echo "       Compile from a space-free path and copy FXNews.ex5 to the" >&2
      echo "       MQL5/Indicators/FXNews/ folder, or press F7 in MetaEditor." >&2
      exit 2
      ;;
  esac
done

# The Wine prefix maps z: -> / , so any absolute macOS path becomes Z:\...
# shellcheck disable=SC1003  # tr '\\' is a literal backslash, not a quote escape
to_win() { printf 'Z:%s' "$(printf '%s' "$1" | tr '/' '\\')"; }

"$WINE" "$ME" \
  /compile:"$(to_win "$SRC")" \
  /inc:"$(to_win "$MT5/MQL5")" \
  /log:"$(to_win "$LOG")" >"$WORK/wine.out" 2>&1 &
WINE_PID=$!
WAITED=0
while kill -0 "$WINE_PID" 2>/dev/null; do
  if [ "$WAITED" -ge "$BUILD_TIMEOUT" ]; then
    echo "build: MetaEditor did not finish within ${BUILD_TIMEOUT}s; terminating" >&2
    kill "$WINE_PID" 2>/dev/null
    sleep 1
    kill -9 "$WINE_PID" 2>/dev/null
    exit 4
  fi
  sleep 1
  WAITED=$((WAITED + 1))
done
wait "$WINE_PID"
WINE_STATUS=$?

if [ ! -s "$LOG" ]; then
  echo "build: MetaEditor wrote no log (wine exit status $WINE_STATUS)" >&2
  tail -n 5 "$WORK/wine.out" >&2
  exit 3
fi

# MetaEditor writes its log as UTF-16LE with CRLF endings; strip the BOM and CRs
# or every downstream pattern silently fails to anchor at end-of-line. A partial
# iconv failure must not leave raw UTF-16 bytes behind the decoded prefix, so
# decode into a file first and fall back to the raw log only when that fails.
if iconv -f UTF-16LE -t UTF-8 "$LOG" >"$WORK/build.utf8" 2>/dev/null; then
  OUT="$(cat "$WORK/build.utf8")"
else
  OUT="$(cat "$LOG")"
fi
OUT="$(printf '%s' "$OUT" | tr -d '\r' | sed '1s/^\xEF\xBB\xBF//')"
printf '%s\n' "$OUT" | grep -vE 'information: (generating code( [0-9]+%)?|code generated)$' | sed '/^[[:space:]]*$/d'

RESULT="$(printf '%s' "$OUT" | grep -o 'Result: [0-9]* errors, [0-9]* warnings' | tail -1)"
ERRORS="$(printf '%s' "$RESULT" | sed -n 's/Result: \([0-9]*\) errors.*/\1/p')"
WARNINGS="$(printf '%s' "$RESULT" | sed -n 's/.*, \([0-9]*\) warnings/\1/p')"

if [ -z "$RESULT" ]; then
  echo "build: compiler produced no result line (wine exit status $WINE_STATUS) - check MetaEditor manually" >&2
  exit 3
fi
if [ "${ERRORS:-1}" -ne 0 ] || [ "${WARNINGS:-1}" -ne 0 ]; then
  echo "build: FAILED gate ($RESULT)" >&2
  exit 1
fi
echo "build: OK ($RESULT)"

# NOTE: a clean result is a weak signal. The MQL5 compiler only warns about a
# variable that is never touched at all: an initialised-but-unread local, a
# dead struct copy, a struct field written but never read, a tautological
# comparison and unreachable code all pass silently (verified by probe on
# 2026-08-13). Run tools/census.py and tools/selftest-macos.sh alongside it.

if [ "$INSTALL" -eq 1 ]; then
  EX5="${SRC%.mq5}.ex5"
  DEST="$MT5/MQL5/Indicators/FXNews"
  [ -f "$EX5" ] || {
    echo "build: expected $EX5 after a clean compile" >&2
    exit 2
  }
  # Report whether the destination already existed. Creating it silently hid the case of an
  # install aimed at the wrong terminal: an empty indicator folder appears, MT5 shows nothing,
  # and the build reports success (F-045).
  if [ -d "$DEST" ]; then
    echo "build: install target exists: $DEST"
  else
    echo "build: install target absent, creating: $DEST"
    mkdir -p "$DEST" || exit 2
  fi
  cp "$EX5" "$DEST/" || exit 2

  # An install is not complete until the binary is there at full length. A short copy is what
  # a full disk or a permissions problem produces, and MT5 would load a truncated indicator,
  # so the size is checked rather than assumed.
  SRC_BYTES=$(wc -c <"$EX5" | tr -d ' ')
  INSTALLED="$DEST/$(basename "$EX5")"
  DST_BYTES=$(wc -c <"$INSTALLED" 2>/dev/null | tr -d ' ')
  if [ "${DST_BYTES:-0}" != "$SRC_BYTES" ]; then
    echo "build: installed copy is ${DST_BYTES:-0} bytes, expected $SRC_BYTES - install incomplete" >&2
    exit 2
  fi

  # A stale .mq5 beside a fresh .ex5 is a documented trap: MT5 loads the binary, so the pair
  # disagrees silently. Report it rather than failing, because installing a binary whose source
  # is not kept in step is a legitimate manual workflow.
  MQ5_INSTALLED="$DEST/$(basename "${SRC%.mq5}.mq5")"
  if [ -f "$MQ5_INSTALLED" ] && ! cmp -s "$SRC" "$MQ5_INSTALLED"; then
    echo "build: WARNING - $MQ5_INSTALLED differs from the source that produced the installed .ex5" >&2
  fi

  echo "build: installed $(basename "$EX5") to $DEST ($SRC_BYTES bytes, verified)"
fi
