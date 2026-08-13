#!/usr/bin/env bash
# Compile FXNews.mq5 with MetaEditor under the MetaQuotes-bundled Wine on macOS.
# Usage:  ./build.sh [path/to/File.mq5]
# Exits non-zero when the compiler reports errors OR warnings.
set -uo pipefail

# Default to the repository's FXNews.mq5 regardless of where this script is
# invoked from, and regardless of how deep tools/ sits under the root.
if [ $# -ge 1 ]; then
  SRC="$1"
else
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || dirname "$HERE")"
  SRC="$ROOT/FXNews.mq5"
fi
[ -f "$SRC" ] || { echo "build: no such source file: $SRC" >&2; exit 2; }
SRC="$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")"

WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
export WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
ME="$MT5/MetaEditor64.exe"
export WINEDEBUG="${WINEDEBUG:--all}"

[ -x "$WINE" ] || { echo "build: wine64 not found at $WINE" >&2; exit 2; }
[ -f "$ME" ]   || { echo "build: MetaEditor64.exe not found at $ME" >&2; exit 2; }

# The Wine prefix maps z: -> / , so any absolute macOS path becomes Z:\...
to_win() { printf 'Z:%s' "$(printf '%s' "$1" | tr '/' '\\')"; }

LOG="$(mktemp -t mql5build).log"
trap 'rm -f "$LOG"' EXIT

"$WINE" "$ME" \
  /compile:"$(to_win "$SRC")" \
  /inc:"$(to_win "$MT5/MQL5")" \
  /log:"$(to_win "$LOG")" >/dev/null 2>&1

# MetaEditor writes its log as UTF-16LE with CRLF endings; strip the BOM and CRs
# or every downstream pattern silently fails to anchor at end-of-line.
OUT="$(iconv -f UTF-16LE -t UTF-8 "$LOG" 2>/dev/null || cat "$LOG")"
OUT="$(printf '%s' "$OUT" | tr -d '\r' | sed '1s/^\xEF\xBB\xBF//')"
printf '%s\n' "$OUT" | grep -vE 'information: (generating code( [0-9]+%)?|code generated)$' | sed '/^[[:space:]]*$/d'

RESULT="$(printf '%s' "$OUT" | grep -o 'Result: [0-9]* errors, [0-9]* warnings' | tail -1)"
ERRORS="$(printf '%s' "$RESULT"  | sed -n 's/Result: \([0-9]*\) errors.*/\1/p')"
WARNINGS="$(printf '%s' "$RESULT" | sed -n 's/.*, \([0-9]*\) warnings/\1/p')"

if [ -z "$RESULT" ]; then
  echo "build: compiler produced no result line — check MetaEditor manually" >&2
  exit 3
fi
if [ "${ERRORS:-1}" -ne 0 ] || [ "${WARNINGS:-1}" -ne 0 ]; then
  echo "build: FAILED gate ($RESULT)" >&2
  exit 1
fi
echo "build: OK ($RESULT)"

# NOTE: a clean result is a weak signal. The MQL5 compiler only warns about a
# variable that is never touched at all — an initialised-but-unread local, a
# dead struct copy, a struct field written but never read, a tautological
# comparison and unreachable code all pass silently. Verified by probe on
# 2026-08-13. Do not treat "0 errors, 0 warnings" as dead-code clearance.
