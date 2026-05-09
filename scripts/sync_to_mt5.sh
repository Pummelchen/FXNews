#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_MT5_EXPERTS_DIR="/Users/andreborchert/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts"
MT5_EXPERTS_DIR="${MT5_EXPERTS_DIR:-$DEFAULT_MT5_EXPERTS_DIR}"
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
