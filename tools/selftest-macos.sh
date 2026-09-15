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
# Usage:  ./tools/selftest-macos.sh [--validation | --autotune]
#   default      run the built-in self-test; the result line prints the total
#   --validation run a VALIDATION pass over EURUSD,GBPUSD on M5,H1 and require
#                a complete report (exercises the historical engine end to end)
#   --autotune   the same for an AUTOTUNE sweep
# Exits 0 on PASSED / a complete report, 1 on FAILED, ABORTED or timeout,
# 2 on an environment problem.
# The terminal must not already be running: MetaTrader refuses a second
# instance and the harness would wait on the wrong process.
set -uo pipefail

MODE="selftest"
case "${1:-}" in
  "") ;;
  --validation) MODE="validation" ;;
  --autotune) MODE="autotune" ;;
  *) echo "selftest: unknown option $1" >&2; exit 2 ;;
esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$HERE" rev-parse --show-toplevel 2>/dev/null || dirname "$HERE")"

# Paths and Wine/Rosetta handling live in one place, shared with build-macos.sh.
# shellcheck source=tools/lib-mt5.sh
. "$HERE/lib-mt5.sh" || { echo "selftest: cannot load $HERE/lib-mt5.sh" >&2; exit 2; }
mt5_configure
TIMEOUT_SECONDS="${FXNEWS_SELFTEST_TIMEOUT:-240}"
if [ "$MODE" != "selftest" ]; then
  TIMEOUT_SECONDS="${FXNEWS_SELFTEST_TIMEOUT:-900}"
fi

[ -x "$WINE" ]     || { echo "selftest: wine64 not found at $WINE" >&2; exit 2; }
[ -f "$TERMINAL" ] || { echo "selftest: terminal64.exe not found at $TERMINAL" >&2; exit 2; }
mt5_require_wine "selftest"
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
PRESET_DIR="$MT5/MQL5/Presets"
PRESET="$PRESET_DIR/FXNewsHarness.set"
mkdir -p "$INSTALL_DIR" "$SCRIPT_DIR" "$PRESET_DIR" || exit 2
cp "$ROOT/FXNews.ex5" "$INSTALL_DIR/FXNews.ex5" || exit 2
cp "$ROOT/tools/mql5/FXNewsSelfTest.ex5" "$SCRIPT_DIR/FXNewsSelfTest.ex5" || exit 2

WORK="$(mktemp -d -t fxnews-selftest)"
# shellcheck disable=SC2329  # invoked through the EXIT trap
cleanup() {
  rm -rf "$WORK"
  rm -rf "$INSTALL_DIR"
  rm -f "$SCRIPT_DIR/FXNewsSelfTest.ex5" "$PRESET"
}
trap cleanup EXIT

# The script's inputs travel through a preset file; the historical modes get a
# small basket so a run finishes in minutes rather than the full default sweep.
case "$MODE" in
  selftest)
    printf 'HarnessMode=3\r\nHarnessSymbols=\r\nHarnessTimeframes=\r\nHarnessTimeoutSeconds=90\r\n' > "$PRESET" ;;
  validation)
    printf 'HarnessMode=1\r\nHarnessSymbols=EURUSD,GBPUSD\r\nHarnessTimeframes=M5,H1\r\nHarnessTimeoutSeconds=%d\r\n' "$((TIMEOUT_SECONDS - 60))" > "$PRESET" ;;
  autotune)
    printf 'HarnessMode=2\r\nHarnessSymbols=EURUSD,GBPUSD\r\nHarnessTimeframes=M5,H1\r\nHarnessTimeoutSeconds=%d\r\n' "$((TIMEOUT_SECONDS - 60))" > "$PRESET" ;;
esac

# Windows ini files are read as ANSI; the content is pure ASCII so no BOM is needed.
CONFIG="$WORK/fxnews-selftest.ini"
printf '[StartUp]\r\nSymbol=EURUSD\r\nPeriod=M5\r\nScript=FXNewsSelfTest\r\nScriptParameters=FXNewsHarness.set\r\nShutdownTerminal=1\r\n' > "$CONFIG"

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
if [ -z "$VERDICT" ]; then
  echo "selftest: the harness script produced no verdict line" >&2
  exit 1
fi

if [ "$MODE" = "selftest" ]; then
  RESULT="$(printf '%s' "$JOURNAL" | grep -o 'RESULT: [0-9]* passed, [0-9]* failed' | tail -1)"
  FAILED="$(printf '%s' "$RESULT" | sed -n 's/.*, \([0-9]*\) failed/\1/p')"
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
fi

# A historical run passes when the ready label appeared AND the Journal holds the
# report's signal line AND the run actually read history; ABORTED or a timeout
# fails. The history check exists because a report over no data used to pass: on
# 2026-09-15 a VALIDATION run reported "Symbols 0/2 ... M1 bars=0" and the gate
# still printed OK, so the mode whose whole purpose is to exercise the historical
# engine end to end gave a green result while reading zero bars. A quiet market
# legitimately yields zero signals, so the gate requires loaded bars, not signals.
SIGNALS="$(printf '%s' "$JOURNAL" | grep -o 'signals=[0-9]*\|Signals=[0-9]*' | tail -1)"
BARS="$(printf '%s' "$JOURNAL" | grep -o 'M1 bars=[0-9]*' | tail -1 | grep -o '[0-9]*$')"
LOADED="$(printf '%s' "$JOURNAL" | grep -o 'Symbols [0-9]*/[0-9]*' | tail -1 | sed -n 's#Symbols \([0-9]*\)/.*#\1#p')"
SCANNED="$(printf '%s' "$JOURNAL" | grep -o 'evaluated [0-9]* of' | tail -1 | grep -o '[0-9]*')"
case "$VERDICT" in
  *"VALIDATION ready"*|*"AUTOTUNE ready"*)
    if [ -z "$SIGNALS" ]; then
      echo "selftest: FAILED ($VERDICT; the journal holds no report signal line)" >&2
      exit 1
    fi
    if [ "${LOADED:-0}" -le 0 ] || [ "${BARS:-0}" -le 0 ]; then
      echo "selftest: FAILED ($MODE read no history: ${LOADED:-0} symbol(s) loaded, ${BARS:-0} M1 bar(s), ${SCANNED:-0} boundar(ies) evaluated)" >&2
      echo "  The historical engine cannot be exercised without M1 history: the report" >&2
      echo "  is empty, not quiet. Open an M1 chart for each symbol so the terminal" >&2
      echo "  downloads it, confirm the terminal is connected, then re-run." >&2
      exit 1
    fi
    echo "selftest: OK ($MODE report complete, $SIGNALS, ${LOADED} symbol(s), ${BARS} bar(s), ${SCANNED:-0} boundar(ies))"
    exit 0
    ;;
esac
echo "selftest: FAILED ($VERDICT)" >&2
exit 1
