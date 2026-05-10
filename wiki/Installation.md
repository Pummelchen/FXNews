# Installation

## Local Sync Path

By default, the project sync script copies the production indicator to this repo-relative target:

```text
../MT5/Indicators/FXNews/FXNews.mq5
```

Run:

```bash
scripts/sync_to_mt5.sh
```

For a local terminal install in another location, set `MT5_INDICATORS_DIR`, set local git config `fxnews.mt5IndicatorsDir`, or put the path in an untracked `.mt5_indicators_dir` file. Machine-specific paths are intentionally ignored by git.

Old `MT5_EXPERTS_DIR`, `fxnews.mt5ExpertsDir`, and `.mt5_experts_dir` settings are still accepted only to derive the sibling `Indicators` folder.

## Compile

Open MetaEditor and compile:

```text
MQL5/Indicators/FXNews/FXNews.mq5
```

Attach `FXNews` from Indicators to one chart. The attached chart symbol does not need to be the only symbol scanned.

If an old `FXNews` Expert Advisor is still attached to a chart/template, remove it and attach the custom indicator version. The sync script removes stale local Expert Advisor source/compiled copies where it can.

## Broker Symbols

Configure `SymbolsToScan` with the symbols as your broker exposes them. FXNews attempts to resolve common broker suffixes and prefixes by detecting standard FX currency codes:

```text
EUR, USD, GBP, JPY, CHF, AUD, NZD, CAD
```

Configure `TimeframesToScan` with the scan timeframes to evaluate:

```text
M1,M5,M15,M30,H1,H4,H8,H12,D1
```
