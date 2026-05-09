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

## Practical Tuning

Lower `MinDisplayConfidence` if the radar is too quiet. Raise it if the chart shows too many weak signals. Keep `DisplayUpdateSeconds` at five seconds or higher for calmer chart behavior.

Scanning many pairs across many timeframes increases the number of profiles. With 55 symbols and nine timeframes, the EA evaluates 495 symbol/timeframe profiles, so reduce `TimeframesToScan` if the terminal becomes sluggish.

For brokers with wider spreads, raise `MaxSpreadPips` carefully and watch whether false signals increase during rollovers or thin liquidity.
