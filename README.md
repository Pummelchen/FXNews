# FXNews

FXNews is a chart-only MetaTrader 5 scanner for discretionary FX day traders. The main deliverable is `FXNews.mq5`, an Expert Advisor that scans many symbols/timeframes from one attached chart and ranks breakout/impulse alerts for manual triage.

The EA does not trade. It never opens, closes, modifies, or manages positions.

## Files

- `FXNews.mq5`: production MT5 Expert Advisor.
- `scripts/sync_to_mt5.sh`: mirrors the EA into the local MT5 `Experts/FXNews` folder.
- `wiki/`: GitHub wiki source pages mirrored into the repository.

## Install

1. Run `scripts/sync_to_mt5.sh`.
2. Open MetaEditor.
3. Compile `MQL5/Experts/FXNews/FXNews.mq5`.
4. Attach `FXNews` to one chart, for example `EURUSD`.
5. Configure `SymbolsToScan` and `TimeframesToScan`.

Machine-specific MT5 paths are kept out of git. Use `MT5_EXPERTS_DIR`, local git config `fxnews.mt5ExpertsDir`, or an untracked `.mt5_experts_dir` file for local sync.

## Dashboard

The dashboard is a scanner table, not a trade blotter:

```text
BREAKOUT RADAR | # SYMBOL TF DIR SCORE ST SESSION AGE SPR/ATR NEWS TAG GROUP REASON
01 EURUSD     M5   UP    76% CAL    LONDON      14s 0.18 NEWS_NONE          LEAD:USD- BRK+ IMP+ FLOW+ EXEC+ CAL
02 GBPUSD     M5   UP    71% RAW    LONDON      11s 0.22 NEWS_NONE          MEM:USD-  IMP+ FLOW+ RAW
03 USDCHF     M15  DOWN  68% LOW-N  LONDON      28s 0.20 NEWS_HIGH_IMPACT   LEAD:USD- BRK+ LOW-N
```

`UP` means the base currency is strengthening against the quote currency. `DOWN` means the base currency is weakening against the quote currency.

## What The Score Means

The percentage is an alert-quality ranking score. It combines raw market-structure evidence with calibration metadata when enough forward outcome data exists.

- `RAW`: raw heuristic score, uncalibrated.
- `CAL`: calibrated score from enough matching symbol/timeframe/session/direction samples.
- `LOW-N`: raw score shown because the matching calibration bucket has too few samples or insufficient expectancy for promotion.
- `STALE`: raw score shown because matching calibration data is older than `CalibrationMaxAgeDays`.

The score is not a guaranteed win probability. It is only a scanner ranking metric for deciding what deserves human attention first.

## Scoring Model

FXNews uses MT5-native broker/chart data only. It does not use `WebRequest`, DLLs, web scraping, or any external feed. Optional MT5 economic-calendar context is disabled by default.

The score combines:

- execution quality: spread, median spread, spread-to-ATR, quote age, tick gaps, tick sample quality;
- breakout structure: compression, boundary distance, candle location, body quality, hold time, fakeout/snapback risk;
- impulse quality: 5/10/30/60 second speed z-scores, tick-rate/tick-volume z-scores, candle ATR expansion, continuation, exhaustion;
- currency flow: base/quote strength, directional edge, weighted basket agreement, conflict penalties;
- regime context: session-aware baselines, M5/M15 alignment, volatility regime;
- optional calendar context: pre-news danger, just-released high-impact events, unavailable calendar handling;
- alert grouping: correlated alerts are grouped by dominant currency flow and a group leader is selected.

## CSV Logging

With `EnableSignalLogging=true`, FXNews writes `FXNews_signals.csv` in the terminal files area. It appends `SIGNAL` and `OUTCOME` rows keyed by `signal_id`.

Key fields include:

```text
signal_id,server_time,local_time,symbol,timeframe,direction,raw_score,calibrated_score,displayed_score,score_status,score_bucket,session_name,spread_pips,median_spread_pips,spread_to_atr,spread_z,quote_age_sec,tick_gap_sec,atr_pips,range_width_pips,breakout_distance_atr,hold_seconds,impulse_z_5s,impulse_z_10s,impulse_z_30s,impulse_z_60s,tick_rate_z,tick_volume_z,base_strength,quote_strength,directional_edge,basket_agreement,m5_context,m15_context,calendar_state,news_proximity_min,entry_mid,mfe_5m_pips,mae_5m_pips,result_5m_R,hit_target_5m,hit_stop_5m,mfe_15m_pips,mae_15m_pips,result_15m_R,hit_target_15m,hit_stop_15m,mfe_30m_pips,mae_30m_pips,result_30m_R,hit_target_30m,hit_stop_30m,final_outcome_label,continuation_score,reason_summary,human_reason
```

Example rows:

```csv
SIGNAL,1715330001_EURUSD_M5_12,2026.05.10 09:13:21,2026-05-10 16:13:21,EURUSD,M5,UP,72.40,72.40,72,RAW,70,LONDON,0.8,0.7,0.16,0.42,1.0,0.3,5.1,18.4,0.32,7,1.44,1.21,0.88,0.52,1.10,1.36,0.28,-0.31,0.59,0.68,0.44,0.31,NEWS_NONE,0.00,1.08342,,,,,,,,,,,,,,,,,positive=exec|impulse|flow,Clean directional breakout: strong 10s/30s impulse
OUTCOME,1715330001_EURUSD_M5_12,2026.05.10 09:18:22,2026-05-10 16:18:22,EURUSD,M5,UP,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1.08342,4.2,1.6,0.51,1,0,,,,,,,,,,TARGET_BEFORE_STOP,0.73,,
```

## Calibration File

Set `UseScoreCalibrationFile=true` only after collecting enough forward data. `FXNews_calibration.csv` uses this format:

```csv
symbol,timeframe,session,direction,score_bucket,calibrated_score,sample_count,profit_factor,expectancy_R,last_updated
EURUSD,M5,LONDON,UP,70,74,184,1.31,0.07,2026-05-10 00:00:00
```

Calibration is separated by symbol, timeframe, session, direction, and score bucket. Tiny or stale buckets do not override raw scores.

## How To Prove The Score Is Useful

1. Run in logging mode for at least 2-4 weeks.
2. Collect at least 300-1,000 signals across the sessions you actually trade.
3. Compare expectancy by score bucket: 60-64, 65-69, 70-74, 75-79, 80-84, 85+.
4. Confirm that 75+ buckets outperform 60-69 buckets after spread/slippage assumptions.
5. Only then enable calibrated-score display.

## Common False Positives

- sudden spread widening around rollover or thin liquidity;
- stale quotes or weak tick samples from the broker feed;
- correlated basket moves where one currency dominates several pairs;
- high-impact news pre-release noise;
- late signals after a move is already overextended;
- higher-timeframe scans that disagree with M5/M15 context.

## Limitations

Broker feeds differ. Tick volume, tick rate, spread behavior, and symbol suffixes are broker-specific. MT5 economic calendar availability also depends on terminal/broker support and can time out. FXNews treats missing calendar/tick/calibration data as context, not as a reason to crash.

FXNews is scanner/alert tooling, not a standalone trading system. Manual execution, risk control, spread/slippage assessment, and trade management remain the trader's responsibility.
