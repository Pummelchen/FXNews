# FXNews

FXNews is a chart-only MetaTrader 5 custom indicator for discretionary FX day traders. It scans many symbols and timeframes from one attached chart and ranks fresh breakout/impulse events for manual triage.

FXNews does not trade. It never opens, closes, modifies, or manages positions, and it does not write CSV logs, calibration files, validation reports, or any other files to disk.

## Files

- `FXNews.mq5`: production MT5 custom indicator.
- `scripts/sync_to_mt5.sh`: mirrors the indicator into the local MT5 `Indicators/FXNews` folder and removes stale legacy EA/indicator copies.
- `wiki/`: GitHub wiki source pages mirrored into the repository.

## Install

1. Run `scripts/sync_to_mt5.sh`.
2. Open MetaEditor.
3. Compile `MQL5/Indicators/FXNews/FXNews.mq5`.
4. Attach `FXNews` from Indicators to one chart, for example `EURUSD`.
5. Configure `SymbolsToScan` and `TimeframesToScan`.
6. Leave `OperatingMode=FXNEWS_MODE_LIVE` for normal scanning.

Machine-specific MT5 paths are kept out of git. Use `MT5_INDICATORS_DIR`, local git config `fxnews.mt5IndicatorsDir`, or an untracked `.mt5_indicators_dir` file for local sync. Existing `MT5_EXPERTS_DIR`, `fxnews.mt5ExpertsDir`, or `.mt5_experts_dir` settings are accepted only to derive the sibling `Indicators` folder.

If MT5 still shows old `NewsScan`, `ChartOnlyBreakoutRadarEA`, or `FXNews` under Experts, remove that old item from the open chart/template and attach the indicator from `MQL5/Indicators/FXNews`.

## Dashboard

The live chart output is intentionally compact: one activity/status line plus the latest five real signal messages. Empty placeholders are not shown. The status line uses the chart's line color; signal messages are white with extra row spacing for readability.

```text
BREAKOUT RADAR | LIVE scanning 252 profiles | valid=28 invalid=0 active=1 | scan 8.4ms | 2026-05-16 15:35:45
2026-05-16 15:35:45 - EURUSD M15 UP - 75%
2026-05-16 15:32:10 - GBPJPY H1 DOWN - 69%
```

`UP` means the base currency is strengthening against the quote currency. `DOWN` means the base currency is weakening against the quote currency.

## What The Score Means

The percentage is an internal alert-quality ranking score. It is not a guaranteed win probability and it is not an automatic entry signal.

The score combines:

- execution quality: spread, median spread, spread-to-ATR, quote age, tick gaps, tick sample quality;
- breakout structure: compression, boundary distance, candle location, body quality, hold time, fakeout/snapback risk;
- impulse quality: 5/10/30/60 second speed z-scores, tick-rate/tick-volume z-scores, candle ATR expansion, continuation, exhaustion;
- currency flow: base/quote strength, directional edge, weighted basket agreement, conflict penalties;
- regime context: session-aware baselines, M5/M15 alignment, volatility regime;
- optional MT5 economic-calendar context: pre-news danger, just-released high-impact events, unavailable calendar handling;
- alert grouping: correlated alerts are grouped by dominant currency flow and a group leader is selected.

Scores are shown as `RAW` because disk-based logging and calibration files are intentionally disabled. Historical validation and autotune reports are generated on the chart only.

## No Disk I/O

FXNews contains no file logging path and does not use `FileOpen`, `FileWrite`, `FileRead`, or CSV calibration. It also does not use `WebRequest`, DLLs, web scraping, or external feeds.

The sync script removes old `FXNews_signals.csv` and `FXNews_calibration.csv` artifacts from the local MT5 files folder if they exist from earlier versions.

## Validation And Autotune Modes

`OperatingMode` controls whether FXNews runs normally or uses closed M1 history for an on-chart historical simulation:

- `FXNEWS_MODE_LIVE`: normal chart scanner.
- `FXNEWS_MODE_VALIDATION`: pulls closed M1 bars from MT5 history for the configured symbols, simulates alerts over the last `HistoricalLookbackDays`, evaluates 5/15/30 minute forward outcomes, and prints the report on the chart.
- `FXNEWS_MODE_AUTOTUNE`: runs the same M1-history simulation across a small parameter set, compares the best candidate against the current inputs, and prints recommended effective settings plus improvement statistics on the chart.

Validation and Autotune do not write report files. They use MT5's local history database, not external feeds.

Autotune cannot permanently rewrite MT5 input parameters because MQL5 inputs are read-only at runtime. It reports the best effective settings so they can be applied deliberately and rechecked on a later out-of-sample period.

## How To Prove The Score Is Useful

1. Run `FXNEWS_MODE_VALIDATION` over at least 90 days of M1 history.
2. Check whether higher score buckets show better 30 minute R, target-first rate, and profit-factor proxy than lower buckets.
3. Run `FXNEWS_MODE_AUTOTUNE` and compare the best candidate against current settings.
4. Apply any recommended settings manually, then validate again on a later out-of-sample period.
5. Forward-test live alerts manually and compare them against later validation runs. Do not treat a high score as an automatic trade.

## Common False Positives

- sudden spread widening around rollover or thin liquidity;
- stale quotes or weak tick samples from the broker feed;
- correlated basket moves where one currency dominates several pairs;
- high-impact news pre-release noise;
- late signals after a move is already overextended;
- higher-timeframe scans that disagree with M5/M15 context.

## Limitations

Broker feeds differ. Tick volume, tick rate, spread behavior, and symbol suffixes are broker-specific. MT5 economic calendar availability also depends on terminal/broker support and can time out. FXNews treats missing calendar or tick context as degraded information, not as a reason to crash.

FXNews is scanner/alert tooling, not a standalone trading system. Manual execution, risk control, spread/slippage assessment, and trade management remain the trader's responsibility.
