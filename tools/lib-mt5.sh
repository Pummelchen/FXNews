#!/usr/bin/env bash
# The MetaTrader 5 / Wine environment shared by the gate scripts.
#
# Sourced, never executed:  . "$HERE/lib-mt5.sh"
#
# It exists because build-macos.sh and selftest-macos.sh each carried their own
# copy of every path below and could drift apart, and because "the file exists" was
# the only check either of them made. The bundled wine64 is an x86_64 Mach-O, so on
# Apple Silicon it needs Rosetta 2; with Rosetta absent a compile wrote no log and
# build-macos.sh reported "the compiler produced no result line" (exit 3), which
# blames the compiler for an environment problem and hid an entirely unrunnable
# build gate across the whole fleet. mt5_require_wine() turns that into exit 2 with
# the real cause, on both gates.
#
# Overridable for a fleet install or for exercising the checks themselves:
#   FXNEWS_WINE        path to the wine64 binary
#   FXNEWS_WINEPREFIX  path to the Wine prefix

MT5_WINE_DEFAULT="/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64"

# Sets WINE, WINEPREFIX, MT5, ME and TERMINAL for the caller. They are exported
# because that is the library's contract - the sourcing script consumes them - and
# because an exported variable is legitimately used externally, which is also what
# keeps the static analyser honest instead of silenced with a disable directive.
mt5_configure() {
  WINE="${FXNEWS_WINE:-$MT5_WINE_DEFAULT}"
  WINEPREFIX="${FXNEWS_WINEPREFIX:-$HOME/Library/Application Support/net.metaquotes.wine.metatrader5}"
  MT5="$WINEPREFIX/drive_c/Program Files/MetaTrader 5"
  ME="$MT5/MetaEditor64.exe"
  TERMINAL="$MT5/terminal64.exe"
  export WINE WINEPREFIX MT5 ME TERMINAL
  export WINEDEBUG="${WINEDEBUG:--all}"
}

# Exits 2 with an actionable message when Wine cannot actually run.
# $1 is the message prefix, e.g. "build" or "selftest".
mt5_require_wine() {
  local prefix="$1"
  if "$WINE" --version >/dev/null 2>&1; then
    return 0
  fi

  echo "$prefix: wine64 exists but cannot run: $WINE" >&2
  case "$(uname -m)" in
    arm64)
      echo "$prefix:        This host is Apple Silicon and the bundled Wine is x86_64, so it needs Rosetta 2." >&2
      echo "$prefix:        Install it with:  sudo softwareupdate --install-rosetta --agree-to-license" >&2
      ;;
    *)
      echo "$prefix:        The binary is not executable, or its loader is missing." >&2
      ;;
  esac
  exit 2
}
