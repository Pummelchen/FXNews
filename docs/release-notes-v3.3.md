# FXNews 3.3 — release notes

- **Version** 3.3, from `#property version "3.300"` in `FXNews.mq5` (the single source named in
  `RELEASE.md` Part 2).
- **Tag** `v3.300`, taken verbatim from that property.
- **Artifacts** `FXNews.mq5` (the reviewable source) and `FXNews.ex5` (the bytecode MetaEditor
  compiles from it), with `FXNews-3.300.sha256` covering both.
- **Not a macOS host binary.** The `.ex5` is MetaTrader 5 bytecode; `RELEASE.md` §1.2.1–§1.2.4
  (arm64-only, `lipo`, universal binaries) do not apply and no `lipo` assertion is attached, because
  on this repository it would be a gate that cannot fail.

## The chart symbol no longer disappears from a historical run

The symbol an operator is most likely to be evaluating is the one on their chart, and it was the one
the historical modes could not read. MetaTrader builds the M1 series for the chart symbol **only when
the chart itself is on M1**; on any other timeframe `CopyRates` returns `ERR_HISTORY_NOT_FOUND`
(4401) for that symbol alone while every other symbol downloads on demand. The report said
`Symbols 1/2`, which reads as missing data.

- The self-test gate runs the historical modes on an **M1 chart**, and `FXNEWS_CHART_SYMBOL` moves the
  chart off the evaluated list for windows longer than the chart's own load.
- The indicator warns **before** a long run when the chart symbol is in `SymbolsToScan` and the chart
  is not M1, and its skip message names the remedy instead of suggesting a history download.

*Backing checks:* the same terminal gave `Symbols 1/2` with EURUSD skipped on an M5 chart and
`Symbols 2/2` on M1; the 2900-day run with the chart on a symbol outside the list gave `Symbols 7/7`;
the proactive warning was observed firing before the run in a live M5 run. Opening a temporary M1
chart at runtime was implemented, tested and **removed** — it does not produce the series.

## The historical report compares each bucket against break-even

Average R cannot answer whether a bucket was ever profitable: a bucket can rank badly on average and
still be the only one above the hit rate its own geometry needs. Each bucket now carries its
30-minute target and stop rates, and the section prints the break-even rate for the configured
target/stop and states whether any populated bucket clears it.

*Backing checks:* `./tools/selftest-macos.sh` — 225 assertions, 0 failed, including seven covering
`BreakEvenHitRate`, the per-bucket target and stop rates, and a sample that reaches neither barrier
counting as neither. The `--validation` report prints the rates and the verdict.

## Longer lookback, and the gate's overrides

`MAX_HISTORICAL_LOOKBACK_DAYS` is raised from 365 to 3650, and the gate script exposes
`FXNEWS_HISTORICAL_SYMBOLS`, `FXNEWS_HISTORICAL_LOOKBACK_DAYS`, `FXNEWS_CHART_SYMBOL` and
`FXNEWS_SELFTEST_TIMEOUT`.

*Backing check:* a 2900-day window loaded 2 953 804 M1 bars for a single symbol in one call with no
failure, so the whole-window load is not the bound at the sizes this broker offers. Note the harness
forwards only its first three inputs, so a **lookback override does not reach the indicator** and the
run silently uses the default; this is stated in the script rather than left as a working override.

## Documentation

`AGENTS.md` and `RELEASE.md` are added at the repository root; `CLAUDE.md` becomes the committed
`@AGENTS.md` bridge. No product code changes with them.

## Checks that did not run

Named because a check that cannot run must not be described as passing:

- **MetaEditor build number.** Not readable from this host; `strings` over `MetaEditor64.exe` yields
  no version resource and the MQL5 logs carry none. The MetaTrader 5 application bundle is
  `5.0.4501` (`CFBundleShortVersionString`), which is the recorded toolchain identity.
- **Controlled runtime validation at a demo terminal.** The interactive items in the wiki Release
  Checklist — symbol selection, activity status, the diagnostics panel, the recent-signal list,
  detailed rows, tooltips, row limits, cleanup on removal, sound and push channels, and
  calendar-disabled/enabled behaviour — need a human at a terminal and were not performed. Scan
  duration with the intended production basket was not measured. The headless self-test covers the
  pure helpers, the shared composer, the historical engine, the recent-signal list and the signal
  lifecycle, and **not** correlation grouping, alert dispatch or dashboard rendering.
- **Not checked by design:** the `lipo`/arm64 assertions, which `RELEASE.md` Part 2 excludes.

## Checksums

```
SHA256 (FXNews.mq5)        55cd10e07ec387297b1102f82ef89b2184e8d0040590524d4aae27451994269c
SHA256 (FXNews.ex5)        b0f68a7513a7c5165578f1f357f7f0250e9aa00e1486853c6da114ce6e78c5cf
ARCHIVE_BYTES (mq5 + ex5)  672901
```

## Environment

macOS 27.0 (26A428) arm64; MetaTrader 5 application 5.0.4501 under the MetaQuotes-bundled Wine with
Rosetta 2. Gates at this revision: `build-macos.sh` 0 errors / 0 warnings; `census.py` 0 findings;
`contracts.py` 0 violations across 9; `selftest-macos.sh` 225 passed / 0 failed of 225;
`--validation` complete (2 symbols, 183 897 M1 bars, 6 036 boundaries, 1 181 signals); `--autotune`
complete; `--install` verified. CI gates re-run locally: ruff check, ruff format --check,
`mypy --strict` on 3 files, bandit, shellcheck, shfmt, gitleaks over full history.
