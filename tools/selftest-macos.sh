#!/usr/bin/env bash
# Run the FXNews self-test headlessly on macOS.
#
#   1. compile FXNews.mq5 and tools/mql5/FXNewsSelfTest.mq5 through build-macos.sh
#   2. install the indicator under MQL5/Indicators/FXNews-selftest/ (never the
#      live FXNews/ folder) and the runner under MQL5/Scripts/
#   3. start the terminal with a one-shot config that runs the script and shuts
#      the terminal down again
#   4. read the Experts journal and fail unless it reports "SELFTEST PASSED"
#      with zero failed assertions
#
# Usage:  ./tools/selftest-macos.sh
# Exits 0 on PASSED, 1 on FAILED or timeout, 2 on an environment problem.
# The terminal must not already be running: MetaTrader refuses a second
# instance and the harness would wait on the wrong process.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || dirname "$HERE")"

WINE="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"
export WINEPREFIX="$HOME/Library/Application Support/net.metaquotes.wine.metatrader5"
MT5="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
TERMINAL="$MT5/terminal64.exe"
export WINEDEBUG="${WINEDEBUG:--all}"
TIMEOUT_SECONDS="${FXNEWS_SELFTEST_TIMEOUT:-240}"

[ -x "$WINE" ]     || { echo "selftest: wine64 not found at $WINE" >&2; exit 2; }
[ -f "$TERMINAL" ] || { echo "selftest: terminal64.exe not found at $TERMINAL" >&2; exit 2; }
if pgrep -f 'terminal64.exe' >/dev/null 2>&1; then
  echo "selftest: MetaTrader 5 is already running; close it and retry" >&2
  exit 2
fi

# shellcheck disable=SC1003  # tr '\\' is a literal backslash, not a quote escape
to_win() { printf 'Z:%s' "$(printf '%s' "$1" | tr '/' '\\')"; }

echo "selftest: compiling indicator"
"$HERE/build-macos.sh" "$ROOT/FXNews.mq5" || exit 2
echo "selftest: compiling harness script"
"$HERE/build-macos.sh" "$ROOT/tools/mql5/FXNewsSelfTest.mq5" || exit 2

INSTALL_DIR="$MT5/MQL5/Indicators/FXNews-selftest"
SCRIPT_DIR="$MT5/MQL5/Scripts"
mkdir -p "$INSTALL_DIR" "$SCRIPT_DIR" || exit 2
cp "$ROOT/FXNews.ex5" "$INSTALL_DIR/FXNews.ex5" || exit 2
cp "$ROOT/tools/mql5/FXNewsSelfTest.ex5" "$SCRIPT_DIR/FXNewsSelfTest.ex5" || exit 2

WORK="$(mktemp -d -t fxnews-selftest)"
# shellcheck disable=SC2329  # invoked through the EXIT trap
cleanup() {
  rm -rf "$WORK"
  rm -rf "$INSTALL_DIR"
  rm -f "$SCRIPT_DIR/FXNewsSelfTest.ex5"
}
trap cleanup EXIT

# Windows ini files are read as ANSI; the content is pure ASCII so no BOM is needed.
CONFIG="$WORK/fxnews-selftest.ini"
printf '[StartUp]\r\nSymbol=EURUSD\r\nPeriod=M5\r\nScript=FXNewsSelfTest\r\nShutdownTerminal=1\r\n' > "$CONFIG"

LOG_DIR="$MT5/MQL5/Logs"
STAMP="$(date +%Y%m%d)"
LOG="$LOG_DIR/$STAMP.log"
BEFORE_LINES=0
if [ -f "$LOG" ]; then
  BEFORE_LINES="$(iconv -f UTF-16LE -t UTF-8 "$LOG" 2>/dev/null | wc -l | tr -d ' ')"
fi

echo "selftest: starting terminal (timeout ${TIMEOUT_SECONDS}s)"
"$WINE" "$TERMINAL" /config:"$(to_win "$CONFIG")" >/dev/null 2>&1 &
TERMINAL_PID=$!

WAITED=0
while kill -0 "$TERMINAL_PID" 2>/dev/null; do
  if [ "$WAITED" -ge "$TIMEOUT_SECONDS" ]; then
    echo "selftest: terminal did not shut down within ${TIMEOUT_SECONDS}s; terminating" >&2
    pkill -f 'terminal64.exe' 2>/dev/null
    sleep 3
    break
  fi
  sleep 2
  WAITED=$((WAITED + 2))
done

if [ ! -f "$LOG" ]; then
  echo "selftest: no Experts journal at $LOG" >&2
  exit 2
fi

# MetaTrader writes the journal as UTF-16LE with CRLF endings.
JOURNAL="$(iconv -f UTF-16LE -t UTF-8 "$LOG" 2>/dev/null | tr -d '\r' | tail -n +"$((BEFORE_LINES + 1))")"
printf '%s\n' "$JOURNAL" | grep -E 'FXNews|FXNEWS' | sed 's/^/  journal: /'

VERDICT="$(printf '%s' "$JOURNAL" | grep -o 'FXNEWS_HARNESS: .*' | tail -1)"
RESULT="$(printf '%s' "$JOURNAL" | grep -o 'RESULT: [0-9]* passed, [0-9]* failed' | tail -1)"
FAILED="$(printf '%s' "$RESULT" | sed -n 's/.*, \([0-9]*\) failed/\1/p')"

if [ -z "$VERDICT" ]; then
  echo "selftest: the harness script produced no verdict line" >&2
  exit 1
fi
case "$VERDICT" in
  *"SELFTEST PASSED"*)
    if [ "${FAILED:-1}" -eq 0 ]; then
      echo "selftest: OK ($RESULT)"
      exit 0
    fi
    ;;
esac
echo "selftest: FAILED ($VERDICT; ${RESULT:-no result line})" >&2
exit 1
