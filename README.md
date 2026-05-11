# FXNews

FXNews is a chart-only MetaTrader 5 custom indicator for discretionary FX day traders. It scans many FX pairs and timeframes from one chart and highlights fresh breakout or impulse events for manual triage.

## Benefits

- One indicator watches a full FX basket instead of forcing you to monitor many charts.
- Signals stay simple: status line plus the latest five high-quality messages on the chart.
- Each message includes symbol, timeframe, direction, and a raw event-quality percentage.
- The score considers breakout structure, impulse strength, spread/quote quality, currency-flow confirmation, session context, and fakeout risk.
- Validation and Autotune modes use MT5 M1 history, can apply runtime-tuned settings, and write detailed reports to the MT5 Journal without creating files.
- FXNews never opens, closes, modifies, or manages trades.
- No WebRequest, DLLs, external feeds, CSV logging, or disk output.

The percentage is a scanner ranking score, not a guaranteed win probability and not an automatic trade instruction.

## Documentation

Use the GitHub Wiki for setup and operation:

- [Wiki Home](https://github.com/Pummelchen/FXNews/wiki)
- [Installation](https://github.com/Pummelchen/FXNews/wiki/Installation)
- [QuickStart: Autolearning Before Live Use](https://github.com/Pummelchen/FXNews/wiki/QuickStart-Autolearning)
- [Configuration](https://github.com/Pummelchen/FXNews/wiki/Configuration)
- [Signal Logic](https://github.com/Pummelchen/FXNews/wiki/Signal-Logic)
- [Operations And Troubleshooting](https://github.com/Pummelchen/FXNews/wiki/Operations-and-Troubleshooting)
