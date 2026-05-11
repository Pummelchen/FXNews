# Installation

## Manual Install

Copy the production indicator source to:

```text
MQL5/Indicators/FXNews/FXNews.mq5
```

Open MetaEditor and compile:

```text
MQL5/Indicators/FXNews/FXNews.mq5
```

Attach `FXNews` from Indicators to one chart. The attached chart symbol does not need to be the only symbol scanned.

## Broker Symbols

Configure `SymbolsToScan` with the symbols as your broker exposes them. FXNews attempts to resolve common broker suffixes and prefixes by detecting standard FX currency codes:

```text
EUR, USD, GBP, JPY, CHF, AUD, NZD, CAD
```

Configure `TimeframesToScan` with the scan timeframes to evaluate:

```text
M1,M5,M15,M30,H1,H4,H8,H12,D1
```
