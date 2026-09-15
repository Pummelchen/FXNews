# FXNews audit — project inventory

Phase A output (§2.1–2.4), committed before any audit pass begins. See §6 of this file for
how the brief's monorepo assumptions map onto this repository.

## 2.1 Projects, languages, build systems, entry points, host class

FXNews is **not** a monorepo. It is a single-artifact MetaTrader 5 indicator plus three
support tools. There is no package manager, no dependency manifest, no container setup and
no CI workflow.

| # | Unit | Language | Build system | Entry points | Host class | Ships to users |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `FXNews.mq5` (8 307 lines) | MQL5 | MetaEditor 64-bit under MetaQuotes Wine | `OnInit`, `OnDeinit`, `OnTimer`, `OnCalculate`, `OnChartEvent`; modes LIVE / VALIDATION / AUTOTUNE / SELFTEST | **macOS only** (x86_64 Wine → Rosetta 2 on arm64) | **yes** — the product |
| 2 | `tools/lib-mt5.sh` (52 lines) | Bash 3.2+ | none (sourced library) | n/a — sourced by both gate scripts | **any** (path-independent) | no — shared environment |
| 3 | `tools/build-macos.sh` (141 lines) | Bash 3.2+ | none (script) | CLI flags `[path] [--install] [-h]` | macOS only | no — build gate |
| 4 | `tools/selftest-macos.sh` (157 lines) | Bash 3.2+ | none (script) | CLI flags `[--validation\|--autotune]` | macOS only | no — test gate |
| 5 | `tools/census.py` (355 lines) | Python 3.14 | none (script, stdlib only) | CLI `[source] [--allow FILE] [--json]` | **any** (cross-platform) | no — analysis gate |
| 6 | `tools/contracts.py` (237 lines) | Python 3.14 | none (script, stdlib only) | CLI `[repo-root]` | **any** (cross-platform) | no — contract gate |
| 7 | `tools/mql5/FXNewsSelfTest.mq5` (86 lines) | MQL5 | MetaEditor 64-bit under Wine | `OnStart` | macOS only | no — test harness |
| 8 | `README.md`, `CLAUDE.md`, `LICENSE`, `.gitignore`, `.github/traffic.json` | Markdown/JSON | n/a | n/a | any | docs/metadata |

Two units were added during this audit: `tools/lib-mt5.sh` by F-014/F-024 (the Wine
prefix, MetaTrader paths and runnability probe the gates used to duplicate, and one
used to omit) and `tools/contracts.py` by F-015 (the cross-file string contracts,
which also pins the F-011 dashboard-refresh call site).

**Language-standard coverage (§1):** Swift — **N/A, none present**. C#/.NET — **N/A, none
present**. C — **N/A, none present**. Python — present in exactly one file
(`tools/census.py`), held to Python 3.14 + full annotations + strict type checking
(`mypy --strict`, see `AUDIT/baseline.md`). MQL5 — the brief specifies no MQL5 standard;
this audit applies the repository's own documented gates plus strict manual review, and
records the missing tooling as `E-2`.

## 2.2 Dependency graph, including implicit coupling

```
                        ┌────────────────────────────┐
                        │  FXNews.mq5  (the product)  │
                        └───────┬────────────┬───────┘
        compiles / gate        │            │  statically analysed by
                 ┌─────────────┘            └──────────────┐
                 ▼                                          ▼
      tools/build-macos.sh  ──uses──▶ MetaEditor64.exe   tools/census.py
                 ▲                    + WINEPREFIX            ▲
                 │                                             │
      tools/selftest-macos.sh ──compiles──▶ tools/mql5/FXNewsSelfTest.mq5
                 │
                 └──drives──▶ terminal64.exe (one-shot [StartUp] ini)
                              └──reads──▶ MQL5/Logs/<date>.log  (UTF-16LE journal)
```

Coupling inventory:

| Coupling | Producer | Consumer(s) | Kind | Failure mode |
| --- | --- | --- | --- | --- |
| `FXNews.mq5` source | repo | `build-macos.sh`, `census.py` | file path | path with a space silently no-ops MetaEditor |
| Compiled `FXNews.ex5` | `build-macos.sh` | `selftest-macos.sh`, MT5 terminal | file path | `--install` target `MQL5/Indicators/FXNews/` is assumed to exist |
| `HARNESS_INDICATOR_PATH` `"FXNews-selftest\FXNews"` | `FXNewsSelfTest.mq5:14` | `selftest-macos.sh:72` install dir | **string contract across two files** | rename in one place only → `iCustom` fails, harness times out |
| Chart label text `"SELFTEST PASSED"` / `"VALIDATION ready"` / `"AUTOTUNE ready"` / `"ABORTED"` | `FXNews.mq5` `SetHistoricalReadyMessage`/`SetHistoricalReportHeader` | `FXNewsSelfTest.mq5:32-34` (verdict poll), `selftest-macos.sh:159-163` | **string contract across three files** | rewording the label in the indicator silently breaks both the harness and the gate |
| `RESULT: N passed, M failed` format | `FXNews.mq5:1725` | `selftest-macos.sh:139` (regex `RESULT: [0-9]* passed, [0-9]* failed`) | **string contract across two files** | format change → `FAILED (no result line)` |
| Journal log path `MQL5/Logs/<YYYYMMDD>.log`, UTF-16LE | MT5 terminal | `selftest-macos.sh:100-107,130` | implicit format | encoding/path assumption |
| Preset file `MQL5/Presets/FXNewsHarness.set` | `selftest-macos.sh:76-96` | harness script parameters | file contract | Windows-ANSI requirement documented at `:88` |
| Object name prefix `COBR_` (+ `ChartID()%1000000` + `GetTickCount()`) | `FXNews.mq5:812-813`, `:729` | `FXNewsSelfTest.mq5:29`, dashboard cleanup | string contract | prefix collision / stale labels |
| WINEPREFIX + hard-coded MT5 app path | `build-macos.sh:40-43` | `selftest-macos.sh:38-40` | duplicated constant | drift between the two scripts |

Explicitly **absent** (verified, not assumed): no network sockets, no HTTP/IPC contracts,
no database tables, no queues, no message broker, no shared schemas, no shared model/LLM
interfaces, no environment variables consumed at runtime (only `WINEDEBUG`,
`BUILD_TIMEOUT`, `FXNEWS_SELFTEST_TIMEOUT` inside the two scripts).

## 2.3 Trust boundaries

| Boundary | Description | Where handled | Severity if wrong |
| --- | --- | --- | --- |
| **Operator input** | 86 `input` parameters, including free-text symbol and timeframe lists | `ValidateInputs()` `:930-1109`; `ParseSymbols()` `:3331`; `ParseTimeframes()` `:3415` | S1 — malformed input must not crash or silently disable a safety filter |
| **Broker/market data (untrusted)** | `SymbolInfoTick`, `CopyRates`, `CopyTicks`, `SymbolInfo*`, spread/tick-volume columns, broker symbol names | `UpdateMarketData` `:4071`, `UpdateRatesData` `:4207`, `UpdateTickQuality` `:7672` | S0 — a bad value propagates into scores and alerts |
| **MT5 economic calendar (untrusted)** | `CalendarValueHistory` event structs, incl. `event.time` and `time_mode` | `RefreshCalendarCache` `:5997` | S1 — an out-of-range read on an empty array was a real past defect (tracker #6) |
| **Terminal/chart environment** | `ChartID`, chart object namespace, `TextGetSize`, journal | `ObjectNamespaceToken` `:8128`, `DashboardCharPixels` `:7432` | S2 |
| **Credentials** | **None held by the product.** No `WebRequest`, no API keys, no accounts, no `.env` | verified by absence | — |
| **Network-reachable surface** | **None.** The indicator cannot perform network I/O | verified by absence | — |

## 2.4 Blast radius

| Unit | Direct consumers | Blast radius | Audit severity multiplier |
| --- | --- | --- | --- |
| `FXNews.mq5` | every chart it is attached to, plus all three gates | **>1** — highest | **elevated** (per §2.4). A wrong score is a *wrong result* on a normal path → S0 by definition. |
| `tools/build-macos.sh` | `selftest-macos.sh`, release process | >1 | elevated |
| `tools/selftest-macos.sh` | release process only | 1 | normal |
| `tools/census.py` | release process only | 1 | normal |
| `tools/mql5/FXNewsSelfTest.mq5` | `selftest-macos.sh` | 1 | normal (not distributed) |

The product ships to third parties with a **1-star public repository** and no CI. Every
fix must be verified by the repository's own gates rather than by a pipeline.

## 2.5 Build host classes and §1b work distribution applied

| Work | Host class required | Host used |
| --- | --- | --- |
| Compile `FXNews.mq5` / `FXNewsSelfTest.mq5` (zero-warning gate) | macOS + Wine + Rosetta | `node3` (dev), `node1` (Phase E) |
| Self-test / VALIDATION / AUTOTUNE harness (needs MT5 account + symbols) | macOS + Wine + Rosetta + configured terminal | `node3` (dev), `node1` (Phase E) |
| `census.py`, `ruff`, `mypy`, `bandit`, `coverage`, shellcheck, secret scans | any | `node3` |
| Phase E "fresh clone on an independent host" | macOS, different machine | `node1` |
| Docker / .NET / C sanitizers / Python matrix | **N/A** — nothing in this repo needs them | — |

## 6. Template sections that cannot apply to this repository

Recorded rather than fabricated, per the brief's rule that scope changes need an explicit
note. No task is closed by narrowing it; these are sections that have no subject matter
here.

| Brief section | Status | Reason |
| --- | --- | --- |
| §1 Swift 6.4 / strict concurrency | **N/A** | no Swift source |
| §1 C# 13 / .NET 10 / nullable | **N/A** | no C# source |
| §1 C99 `-std=c99 -pedantic-errors` | **N/A** | no C source |
| §1 ASan/UBSan + memory checker | **N/A** | no C source. MQL5 memory behaviour is governed by the MetaEditor runtime; `tools/census.py` is Python (memory-safe) |
| §1 dependency/CVE scanner | **satisfied trivially** | zero third-party dependencies; `pip-audit` reports nothing for the repo |
| §2.1 20+ interdependent projects | **N/A** | 1 product + 3 tool units enumerated in §2.1 above |
| §2.2 cross-project HTTP/IPC/queues/DB | **N/A** | the product is prohibited from network, file and DB access by design and by verified absence |
| §6 unused-code rule across projects | **reduced, not skipped** | one consumer universe; reachability is still proven against the MQL5 runtime's dynamic entry points (event handlers), `iCustom` harness loading, and the string contracts tabled in §2.2 |
| §1b Docker pinning for C/.NET/Python matrices | **N/A** | no such toolchain |
| §1b Xcode/Swift builds on the Mac fleet | **N/A** | no Swift |
| §1b Linux/x86 work (VPS) | **not required** | the only Linux-capable gate is `census.py`, run locally; the VPS was reachable but not used, so nothing was installed on it |
