# Installation

## Local Sync Path

By default, the project sync script copies the production EA to this repo-relative target:

```text
../MT5/Experts/FXNews/FXNews.mq5
```

Run:

```bash
scripts/sync_to_mt5.sh
```

For a local terminal install in another location, set `MT5_EXPERTS_DIR` when running the script, set local git config `fxnews.mt5ExpertsDir`, or put the path in an untracked `.mt5_experts_dir` file. Machine-specific paths are intentionally ignored by git.

## Compile

Open MetaEditor and compile:

```text
MQL5/Experts/FXNews/FXNews.mq5
```

Attach `FXNews` to one chart. The attached chart symbol does not need to be the only symbol scanned.

## Broker Symbols

Configure `SymbolsToScan` with the symbols as your broker exposes them. The EA attempts to resolve common broker suffixes and prefixes by detecting standard FX currency codes:

```text
EUR, USD, GBP, JPY, CHF, AUD, NZD, CAD
```

Configure `TimeframesToScan` with the scan timeframes to evaluate:

```text
M1,M5,M15,M30,H1,H4,H8,H12,D1
```
