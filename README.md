# FXNews

FXNews is a chart-only MetaTrader 5 breakout radar for manual FX day traders. The main deliverable is `ChartOnlyBreakoutRadarEA.mq5`, an Expert Advisor that scans many configured symbols from one attached chart and writes red chart messages when fresh breakout behavior is detected.

The EA does not trade. It never opens, closes, modifies, or manages positions.

## Files

- `ChartOnlyBreakoutRadarEA.mq5`: production MT5 Expert Advisor.
- `NewsScan.mq5`: legacy indicator source kept for reference.
- `scripts/sync_to_mt5.sh`: mirrors the production EA into the local MT5 `Experts/FXNews` folder.
- `wiki/`: GitHub wiki source pages mirrored to the repository for versioned documentation.

## Local MT5 Sync

This checkout is configured to sync the EA source into:

```text
/Users/andreborchert/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/FXNews
```

Run the sync manually when needed:

```bash
scripts/sync_to_mt5.sh
```

This repository also includes local git hooks in `.githooks/`. In this checkout, `core.hooksPath` is set to `.githooks` so post-commit, post-checkout, and post-merge operations refresh the synced MT5 copy.

## Install in MetaTrader 5

1. Run `scripts/sync_to_mt5.sh`.
2. Open MetaEditor.
3. Compile `MQL5/Experts/FXNews/ChartOnlyBreakoutRadarEA.mq5`.
4. Attach `ChartOnlyBreakoutRadarEA` to one chart, for example `EURUSD`.
5. Configure `SymbolsToScan` with the FX pairs your broker exposes.
6. Configure `TimeframesToScan` with the scan timeframes you want, for example `M1,M5,M15,M30,H1,H4,H8,H12,D1`.

## Output

The chart dashboard keeps the last five signal messages. The newest message is on top and older messages shift down. Timestamps use the user's local computer time via `TimeLocal()`, not broker/server time.

```text
BREAKOUT RADAR

2026-05-16 15:35:45 - EURUSD M15 UP - 75%
2026-05-16 15:32:10 - GBPJPY H1 DOWN - 69%
2026-05-16 15:28:41 - AUDJPY M5 UP - 65%
```

`UP` means the base currency is strengthening against the quote currency. `DOWN` means the base currency is weakening against the quote currency. The timeframe between the symbol and direction is the scan timeframe that produced the signal. The percentage is the EA's internal signal-quality score, not a guaranteed win probability.

## Detection Logic

FXNews is price-action based only. It does not use the MT5 economic calendar, external news feeds, `WebRequest`, or DLLs. It combines:

- Technical range breakout scoring on each configured scan timeframe.
- News-like impulse scoring from short-term price speed, scan-timeframe candle expansion, and tick-volume surge.
- Currency-strength confirmation across the configured symbol basket.
- Spread, stale quote, rollover, fakeout, M5, and M15 context filters.
- Per-symbol cooldowns to avoid repeated chart spam.

Important inputs:

- `SymbolsToScan`: comma-separated symbol list.
- `TimeframesToScan`: comma-separated timeframe list. Default `M1,M5,M15,M30,H1,H4,H8,H12,D1`.
- `ScanIntervalSeconds`: calculation interval. Default `1`.
- `DisplayUpdateSeconds`: chart refresh throttle. Default `5`.
- `MinDisplayConfidence`: minimum score shown on chart. Default `60`.
- `StrongAlertConfidence`: strong alert threshold. Default `70`.
- `RangeLookbackM1`: completed bars used for each scan-timeframe range box. The name is retained for settings compatibility. Default `30`.
- `MaxSpreadPips`: hard spread rejection. Default `5`.

## Safety Boundaries

FXNews is an alerting tool for discretionary manual trading. It does not submit orders and cannot manage risk. During real news conditions spreads can widen, ticks can gap, manual orders can slip, and liquidity can disappear. Treat signals as fast situational awareness, then validate price action, spread, and execution conditions before acting.
