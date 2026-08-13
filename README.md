# FXNews

FXNews is a chart-only MetaTrader 5 custom indicator for discretionary FX market monitoring. From one chart, it scans a configurable basket of currency pairs and timeframes for fresh breakout and impulse events.

## What It Provides

- Multi-symbol, multi-timeframe scanning from a single attached chart.
- Ranked active-signal rows with symbol, timeframe, direction, score, execution cost, session, calendar context, correlation grouping, and reason tags.
- A recent-signal fallback when no active candidate qualifies for display.
- Composite scoring based on breakout structure, impulse quality, execution conditions, currency flow, market regime, and optional MT5 economic-calendar context.
- Historical Validation reports and advisory fixed-candidate Autotune recommendations using locally available MT5 M1 history.
- Optional sound and terminal push notifications, both disabled by default.

FXNews does not place, modify, or manage trades. It uses no `WebRequest`, DLL, external data feed, CSV logging, or file persistence. The displayed percentage is an event-quality ranking, not a win probability or trade instruction. Autotune never changes the active runtime settings: review its Journal recommendation and validate it on a separate holdout period before entering settings manually.

## Version

Current source version: **2.3** (`#property version "2.300"`). See the [Changelog](https://github.com/Pummelchen/FXNews/wiki/Changelog) for versioned changes.

## Requirements

- MetaTrader 5 with MetaEditor.
- Broker symbols and sufficient M1, M5, M15, and scan-timeframe history for the configured basket.
- A demo or other non-production environment for initial validation.

## Building

Compile `FXNews.mq5` in MetaEditor. On macOS, `tools/build-macos.sh` drives MetaEditor through the Wine bundle inside the MetaQuotes build of MetaTrader 5 and fails on any error **or** warning, so it can gate a commit:

```bash
./tools/build-macos.sh
```

A clean compile is a syntax gate only. The MQL5 compiler warns about a variable only when it is never touched at all — an initialised-but-unread local, a dead struct copy, a struct field written but never read, and unreachable code all compile silently. Run the dead-code census in [Testing and Validation](https://github.com/Pummelchen/FXNews/wiki/Testing-and-Validation) alongside it.

## Documentation

The [GitHub Wiki](https://github.com/Pummelchen/FXNews/wiki) is the complete project manual:

- [Installation](https://github.com/Pummelchen/FXNews/wiki/Installation)
- [Validation and Autotune](https://github.com/Pummelchen/FXNews/wiki/Validation-and-Autotune)
- [Configuration](https://github.com/Pummelchen/FXNews/wiki/Configuration)
- [Signal Logic](https://github.com/Pummelchen/FXNews/wiki/Signal-Logic)
- [Operations and Troubleshooting](https://github.com/Pummelchen/FXNews/wiki/Operations-and-Troubleshooting)
- [Architecture](https://github.com/Pummelchen/FXNews/wiki/Architecture)
- [Development Guide](https://github.com/Pummelchen/FXNews/wiki/Development-Guide)
- [Testing and Validation](https://github.com/Pummelchen/FXNews/wiki/Testing-and-Validation)
- [Safety and Security](https://github.com/Pummelchen/FXNews/wiki/Safety-and-Security)
- [Release Checklist](https://github.com/Pummelchen/FXNews/wiki/Release-Checklist)
- [Known Limitations](https://github.com/Pummelchen/FXNews/wiki/Known-Limitations)
- [Changelog](https://github.com/Pummelchen/FXNews/wiki/Changelog)
