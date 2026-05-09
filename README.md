# FXNews

FXNews is a chart-only MetaTrader 5 breakout radar for manual FX day traders. The main deliverable is `FXNews.mq5`, an Expert Advisor that scans many configured symbols from one attached chart and writes red chart messages when fresh breakout behavior is detected.

The EA does not trade. It never opens, closes, modifies, or manages positions.

## Files

- `FXNews.mq5`: production MT5 Expert Advisor.
- `scripts/sync_to_mt5.sh`: mirrors the production EA into the local MT5 `Experts/FXNews` folder.
- `wiki/`: GitHub wiki source pages mirrored to the repository for versioned documentation.

## Local MT5 Sync

By default, the sync script copies the EA source into this repo-relative target:

```text
../MT5/Experts/FXNews
```

Run the sync manually when needed:

```bash
scripts/sync_to_mt5.sh
```

For a local terminal install in another location, set `MT5_EXPERTS_DIR` when running the script, set local git config `fxnews.mt5ExpertsDir`, or put the path in an untracked `.mt5_experts_dir` file. Machine-specific paths are intentionally ignored by git.

This repository also includes local git hooks in `.githooks/`. In this checkout, `core.hooksPath` is set to `.githooks` so post-commit, post-checkout, and post-merge operations refresh the synced MT5 copy.

## Install in MetaTrader 5

1. Run `scripts/sync_to_mt5.sh`.
2. Open MetaEditor.
3. Compile `MQL5/Experts/FXNews/FXNews.mq5`.
4. Attach `FXNews` to one chart, for example `EURUSD`.
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

The chart output format is unchanged, but the percentage is now a composite event-quality score for manual radar use. It is not a guaranteed win probability and it is not an auto-entry instruction.

FXNews remains broker-data based. It does not use external feeds, `WebRequest`, or DLLs. Optional built-in MT5 economic calendar context is available through `UseEconomicCalendarContext=false` by default. The score combines:

- Technical range breakout quality on each configured scan timeframe.
- News-like impulse quality from robust short-window speed, acceleration, candle expansion, tick rate, and tick-volume surge.
- Execution quality from spread, median spread, spread z-score, quote freshness, tick gaps, and spread cost versus ATR.
- Currency-flow confirmation across the configured symbol basket.
- Regime and session context, including M5/M15 agreement and volatility regime.
- Optional MT5 economic-calendar context, cached per currency when enabled.
- Fakeout, overextension, weak candle, snapback, context-conflict, aging-event, and execution caps.
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
- `UseStrictExecutionGate`: blocks severe execution-cost problems before scoring. Default `true`.
- `UseEconomicCalendarContext`: optional built-in MT5 calendar context. Default `false`.
- `EnableSignalLogging`: writes signal and outcome audit rows to CSV. Default `true`.
- `UseScoreCalibrationFile`: optionally maps raw score buckets from a calibration CSV. Default `false`.

## Score Audit Logs

When `EnableSignalLogging=true`, FXNews writes `FXNews_signals.csv` in the terminal files area. `SIGNAL` rows include the displayed score, raw score, calibrated score, component scores, execution-cost fields, cap reasons, and entry reference price. If `EnableOutcomeLabeling=true`, later `OUTCOME` rows append 5/15/30 minute MFE and MAE labels for the same `signal_id`.

Use these rows to validate score buckets empirically. For example, compare 60-69, 70-79, 80-89, and 90+ buckets by MFE/MAE, target-before-stop rate, and continuation score. Higher scores should behave like stronger radar events over time, not like automatic trade instructions.

## Safety Boundaries

FXNews is an alerting tool for discretionary manual trading. It does not submit orders and cannot manage risk. During real news conditions spreads can widen, ticks can gap, manual orders can slip, and liquidity can disappear. Treat signals as fast situational awareness, then validate price action, spread, and execution conditions before acting.
