# Operations and Troubleshooting

## Expected Dashboard

The chart shows an empty spacer row, one activity/status line, another spacer row, then the latest five real signal messages. Empty placeholders are not shown. The status line uses the chart's line color, while signal messages are white and spaced for readability.

```text
FXNews - BREAKOUT RADAR | LIVE scanning 252 profiles | valid=28 invalid=0 active=1 | scan 8.4ms | 2026-05-16 15:35:45
2026-05-16 15:35:45 - EURUSD M15 UP - 75%
2026-05-16 15:32:10 - GBPJPY H1 DOWN - 78%
```

Timestamps use local computer time. The timeframe between symbol and direction is the scan timeframe that generated the message. If there are no active/recent signals yet, only the activity/status line is displayed. Signal messages below `75%` are hidden, message rows refresh at most every 10 seconds, rows are sorted by displayed percentage descending, and duplicate symbol/timeframe/direction rows are suppressed.

## No Signals

Check that the broker symbols exist, Market Watch can select them, the configured timeframe history is loaded, M1/M5/M15 context history is available, and spreads are below the configured filters. If needed, lower `MinDisplayConfidence` temporarily to inspect signal flow.

## Too Many Signals

Raise `MinDisplayConfidence`, increase cooldowns, hide correlated group members with `ShowOnlyGroupLeaders=true`, or tighten spread limits. During rollover, keep `IgnoreRolloverTime` enabled.

## Old EA Still Loads

FXNews is now a custom indicator. If MT5 prints `automated trading is disabled`, an old Expert Advisor copy is still attached or still present in the terminal. Remove old chart/template attachments and use the indicator under `MQL5/Indicators/FXNews`.

## Sync Problems

Run:

```bash
scripts/sync_to_mt5.sh
```

If MetaTrader is installed somewhere else, run with:

```bash
MT5_INDICATORS_DIR="/path/to/MetaTrader 5/MQL5/Indicators" scripts/sync_to_mt5.sh
```

The script removes stale `NewsScan`, `ChartOnlyBreakoutRadarEA`, old Expert Advisor copies of `FXNews`, and old CSV artifacts from earlier versions.

## Disk Writes

FXNews is not allowed to write files. It does not create CSV logs, calibration files, validation reports, or settings files. Validation and Autotune reports render directly on the chart.
