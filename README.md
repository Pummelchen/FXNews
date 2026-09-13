# FXNews

[![Stars](https://img.shields.io/github/stars/Pummelchen/FXNews?style=flat-square&logo=github&label=Stars&color=e3b341)](https://github.com/Pummelchen/FXNews/stargazers)
[![Profile Visitors](https://komarev.com/ghpvc/?username=Pummelchen&label=Profile%20Visitors&color=blueviolet&style=flat-square)](https://github.com/Pummelchen)
[![Last Commit](https://img.shields.io/github/last-commit/Pummelchen/FXNews?style=flat-square&logo=git&label=Last%20Commit&color=2ea44f)](https://github.com/Pummelchen/FXNews/commits/main)
[![Contact](https://img.shields.io/badge/Contact-0xa0b1%40gmail.com-blue?style=flat-square&logo=gmail&logoColor=white)](mailto:0xa0b1@gmail.com)

FXNews is a chart-only MetaTrader 5 custom indicator for discretionary FX market monitoring. From one chart, it scans a configurable basket of currency pairs and timeframes for fresh breakout and impulse events.

## What It Provides

- Multi-symbol, multi-timeframe scanning from a single attached chart.
- A timestamped list of the best recent signals by default, or ranked live rows with symbol, timeframe, direction, score, age, session and reason tags; cost, calendar context and correlation group in the tooltip.
- Composite scoring based on breakout structure, impulse quality, execution conditions, currency flow, market regime, and optional MT5 economic-calendar context. A component that could not be measured leaves the score instead of being imputed.
- Historical Validation reports and advisory fixed-candidate Autotune recommendations that replay locally available MT5 M1 history through the same scoring composer as the live scanner.
- Optional sound and terminal push notifications, both disabled by default.

FXNews does not place, modify, or manage trades. It uses no `WebRequest`, DLL, external data feed, CSV logging, or file persistence. The displayed percentage is an event-quality ranking, not a win probability or trade instruction. Autotune never changes the active runtime settings: review its Journal recommendation and validate it on a separate holdout period before entering settings manually.

## Version

Current source version: **3.0** (`#property version "3.000"`). See the [Changelog](https://github.com/Pummelchen/FXNews/wiki/Changelog) for versioned changes.

## Requirements

- MetaTrader 5 with MetaEditor.
- Broker symbols and sufficient M1, M5, M15, and scan-timeframe history for the configured basket.
- A demo or other non-production environment for initial validation.

## Building

Compile `FXNews.mq5` in MetaEditor. On macOS, `tools/build-macos.sh` drives MetaEditor through the Wine bundle inside the MetaQuotes build of MetaTrader 5 and fails on any error **or** warning, so it can gate a commit (`--install` also copies the binary into the terminal's indicator folder):

```bash
./tools/build-macos.sh
```

A clean compile is a syntax gate only. The MQL5 compiler warns about a variable only when it is never touched at all — an initialised-but-unread local, a dead struct copy, a struct field written but never read, and unreachable code all compile silently. Two more gates cover that gap:

```bash
tools/census.py
```

runs the dead-code and placeholder census (Python 3.14) and exits non-zero on any finding, and

```bash
./tools/selftest-macos.sh
```

compiles the indicator, runs its built-in self-test (117 assertions) headlessly in the terminal and exits non-zero unless every assertion passes; `--validation` and `--autotune` run a short historical pass the same way. See [Testing and Validation](https://github.com/Pummelchen/FXNews/wiki/Testing-and-Validation).

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
- [Project Tracker](https://github.com/Pummelchen/FXNews/wiki/Project-Tracker)

## License

MIT — see [LICENSE](LICENSE).

## Contact

Questions, bug reports and suggestions are always welcome. You can contact André Borchert by email at [0xa0b1@gmail.com](mailto:0xa0b1@gmail.com).
