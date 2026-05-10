# Configuration

## Important Inputs

- `SymbolsToScan`: comma-separated FX list.
- `TimeframesToScan`: comma-separated timeframe list. Default `M1,M5,M15,M30,H1,H4,H8,H12,D1`.
- `ScanIntervalSeconds`: score recalculation interval. Default `1`.
- `DisplayUpdateSeconds`: dashboard refresh throttle. Default `5`.
- `MinDisplayConfidence`: minimum score displayed. Default `60`.
- `StrongAlertConfidence`: strong alert threshold. Default `70`.
- `RangeLookbackM1`: completed bars used for each scan-timeframe breakout range. Default `30`.
- `ATRPeriod`: ATR window. Default `14`.
- `MaxSpreadPips`: hard spread rejection. Default `5`.
- `UseTechnicalBreakoutEngine`: enables scan-timeframe range breakout scoring.
- `UseImpulseBreakoutEngine`: enables impulse scoring.
- `UseCurrencyStrength`: enables basket confirmation.
- `UseStrictExecutionGate`: blocks severe quote, spread, tick-gap, and spread-to-ATR problems before scoring. Default `true`.
- `MaxSpreadToAtrRatio`: maximum spread cost versus ATR under strict gating. Default `0.45`.
- `MaxTickGapSeconds`: maximum tick gap under strict gating. Default `8`.
- `MaxSpreadZScore`: maximum robust spread z-score under strict gating. Default `3`.
- `MinHoldSecondsForHighScore`: outside-range hold time before higher breakout scores are allowed. Default `3`.
- `FullHoldScoreSeconds`: hold time for full hold credit. Default `12`.
- `MaxOverextensionAtr`: breakout overextension cap threshold. Default `1.8`.
- `MinImpulseZForSignal`: minimum robust impulse z-score. Default `1.25`.
- `MaxExhaustionAtr`: impulse exhaustion cap threshold. Default `2.2`.
- `UseTickRateScoring`: includes snapshot-derived tick-rate support. Default `true`.
- `UseRobustCurrencyStrength`: uses spread-aware inverse-volatility basket weighting. Default `true`.
- `UseEconomicCalendarContext`: enables optional built-in MT5 economic calendar context. Default `false`.
- `BlockImmediatelyBeforeHighImpactNews`: blocks the final minutes before high-impact calendar releases when calendar context is enabled. Default `false`.
- `UseMultiTimeframeContextCaps`: caps scores when M5/M15 context rejects the direction. Default `true`.
- `EnableSignalLogging`: appends score-audit rows to `FXNews_signals.csv`. Default `true`.
- `EnableOutcomeLabeling`: appends 5/15/30 minute outcome rows for displayed signals. Default `true`.
- `UseScoreCalibrationFile`: applies optional empirical score-bucket calibration from `FXNews_calibration.csv`. Default `false`.

## Practical Tuning

Lower `MinDisplayConfidence` if the radar is too quiet. Raise it if the chart shows too many weak signals. Keep `DisplayUpdateSeconds` at five seconds or higher for calmer chart behavior.

Scanning many pairs across many timeframes increases the number of profiles. With 55 symbols and nine timeframes, the EA evaluates 495 symbol/timeframe profiles, so reduce `TimeframesToScan` if the terminal becomes sluggish.

For brokers with wider spreads, raise `MaxSpreadPips` carefully and watch whether false signals increase during rollovers or thin liquidity.

Use `FXNews_signals.csv` to validate score buckets before tightening thresholds. A practical workflow is to collect enough samples, group by displayed score bucket and timeframe, then compare continuation score, MFE/ATR, MAE/ATR, and target-before-stop rate.
