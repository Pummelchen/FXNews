# Configuration

## Important Inputs

- `SymbolsToScan`: comma-separated FX list.
- `ScanIntervalSeconds`: score recalculation interval. Default `1`.
- `DisplayUpdateSeconds`: dashboard refresh throttle. Default `5`.
- `MinDisplayConfidence`: minimum score displayed. Default `60`.
- `StrongAlertConfidence`: strong alert threshold. Default `70`.
- `RangeLookbackM1`: completed M1 candles used for breakout range. Default `30`.
- `ATRPeriod`: ATR window. Default `14`.
- `MaxSpreadPips`: hard spread rejection. Default `5`.
- `UseTechnicalBreakoutEngine`: enables M1 range breakout scoring.
- `UseImpulseBreakoutEngine`: enables impulse scoring.
- `UseCurrencyStrength`: enables basket confirmation.

## Practical Tuning

Lower `MinDisplayConfidence` if the radar is too quiet. Raise it if the chart shows too many weak signals. Keep `DisplayUpdateSeconds` at five seconds or higher for calmer chart behavior.

For brokers with wider spreads, raise `MaxSpreadPips` carefully and watch whether false signals increase during rollovers or thin liquidity.
