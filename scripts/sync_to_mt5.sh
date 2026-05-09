#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_MT5_EXPERTS_DIR="../MT5/Experts"
LOCAL_CONFIG_FILE="$ROOT_DIR/.mt5_experts_dir"

if [[ -n "${MT5_EXPERTS_DIR:-}" ]]; then
  MT5_EXPERTS_DIR="$MT5_EXPERTS_DIR"
elif git -C "$ROOT_DIR" config --get fxnews.mt5ExpertsDir >/dev/null; then
  MT5_EXPERTS_DIR="$(git -C "$ROOT_DIR" config --get fxnews.mt5ExpertsDir)"
elif [[ -f "$LOCAL_CONFIG_FILE" ]]; then
  MT5_EXPERTS_DIR="$(tr -d '\r\n' < "$LOCAL_CONFIG_FILE")"
else
  MT5_EXPERTS_DIR="$DEFAULT_MT5_EXPERTS_DIR"
fi

if [[ "$MT5_EXPERTS_DIR" != /* ]]; then
  MT5_EXPERTS_DIR="$ROOT_DIR/$MT5_EXPERTS_DIR"
fi

TARGET_DIR="$MT5_EXPERTS_DIR/FXNews"
SOURCE_FILE="$ROOT_DIR/FXNews.mq5"
TARGET_FILE="$TARGET_DIR/FXNews.mq5"

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo "Missing source file: $SOURCE_FILE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
cp "$SOURCE_FILE" "$TARGET_FILE"
rm -f "$TARGET_DIR/ChartOnlyBreakoutRadarEA.mq5" "$TARGET_DIR/ChartOnlyBreakoutRadarEA.ex5"

echo "Synced $SOURCE_FILE"
echo "to     $TARGET_FILE"
