#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_MT5_INDICATORS_DIR="../MT5/Indicators"
LOCAL_INDICATORS_CONFIG_FILE="$ROOT_DIR/.mt5_indicators_dir"
LOCAL_EXPERTS_CONFIG_FILE="$ROOT_DIR/.mt5_experts_dir"

if [[ -n "${MT5_INDICATORS_DIR:-}" ]]; then
  MT5_INDICATORS_DIR="$MT5_INDICATORS_DIR"
elif git -C "$ROOT_DIR" config --get fxnews.mt5IndicatorsDir >/dev/null; then
  MT5_INDICATORS_DIR="$(git -C "$ROOT_DIR" config --get fxnews.mt5IndicatorsDir)"
elif [[ -f "$LOCAL_INDICATORS_CONFIG_FILE" ]]; then
  MT5_INDICATORS_DIR="$(tr -d '\r\n' < "$LOCAL_INDICATORS_CONFIG_FILE")"
elif [[ -n "${MT5_EXPERTS_DIR:-}" ]]; then
  MT5_INDICATORS_DIR="$(dirname "$MT5_EXPERTS_DIR")/Indicators"
elif git -C "$ROOT_DIR" config --get fxnews.mt5ExpertsDir >/dev/null; then
  MT5_EXPERTS_DIR_FROM_CONFIG="$(git -C "$ROOT_DIR" config --get fxnews.mt5ExpertsDir)"
  MT5_INDICATORS_DIR="$(dirname "$MT5_EXPERTS_DIR_FROM_CONFIG")/Indicators"
elif [[ -f "$LOCAL_EXPERTS_CONFIG_FILE" ]]; then
  MT5_EXPERTS_DIR_FROM_FILE="$(tr -d '\r\n' < "$LOCAL_EXPERTS_CONFIG_FILE")"
  MT5_INDICATORS_DIR="$(dirname "$MT5_EXPERTS_DIR_FROM_FILE")/Indicators"
else
  MT5_INDICATORS_DIR="$DEFAULT_MT5_INDICATORS_DIR"
fi

if [[ "$MT5_INDICATORS_DIR" != /* ]]; then
  MT5_INDICATORS_DIR="$ROOT_DIR/$MT5_INDICATORS_DIR"
fi

TARGET_DIR="$MT5_INDICATORS_DIR/FXNews"
SOURCE_FILE="$ROOT_DIR/FXNews.mq5"
TARGET_FILE="$TARGET_DIR/FXNews.mq5"
mkdir -p "$MT5_INDICATORS_DIR"
MQL5_DIR="$(cd "$(dirname "$MT5_INDICATORS_DIR")" && pwd)"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Missing source file: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE"
rm -f "$TARGET_DIR/ChartOnlyBreakoutRadarEA.mq5" "$TARGET_DIR/ChartOnlyBreakoutRadarEA.ex5"

# FXNews is a custom indicator. Remove stale Expert Advisor copies so MT5 does
# not load the old EA and print misleading "automated trading is disabled" lines.
rm -f "$MQL5_DIR/Experts/FXNews/FXNews.mq5" \
      "$MQL5_DIR/Experts/FXNews/FXNews.ex5" \
      "$MQL5_DIR/Experts/FXNews/build-FXNews.log"

# Remove old disk artifacts from previous versions. Current FXNews has no file
# logging or CSV calibration path.
rm -f "$MQL5_DIR/Files/FXNews_signals.csv" \
      "$MQL5_DIR/Files/FXNews_calibration.csv"

# Remove legacy project names that can keep stale chart indicators/experts alive
# and produce misleading Journal errors such as old NewsScan ATR-handle failures.
for legacy_dir in "$MQL5_DIR/Experts" "$MQL5_DIR/Indicators"; do
  [[ -d "$legacy_dir" ]] || continue
  find "$legacy_dir" -type f \( \
    -name 'NewsScan.mq5' -o \
    -name 'NewsScan.ex5' -o \
    -name 'ChartOnlyBreakoutRadarEA.mq5' -o \
    -name 'ChartOnlyBreakoutRadarEA.ex5' \
  \) -delete
done

echo "Synced $SOURCE_FILE"
echo "to     $TARGET_FILE"
