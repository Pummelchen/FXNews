<!--
AI onboarding file.
Mode: bootstrap
Indexed commit: 0677246f53db19f0b34a7b9262e87201dfa33fd0
Last generated: 2026-06-25T11:04:07Z
Generator: generic high-end AI coding agent
Purpose: Help future AI sessions understand this repository quickly.
Audience: Any high-capability AI coding agent, regardless of vendor or model family.
Human edits are allowed. Future refreshes should preserve valid human edits.
-->

# AI Index for FXNews

## Snapshot

| Field | Value |
|---|---|
| Repository | `Pummelchen/FXNews` |
| Purpose | Chart-only MetaTrader 5 custom indicator for discretionary FX day traders. |
| Indexed commit | `0677246f53db19f0b34a7b9262e87201dfa33fd0` |
| Operation mode | `bootstrap` |
| Primary language | MQL5 (`FXNews.mq5`) |
| Runtime | MetaTrader 5 custom indicator runtime |
| Product source files changed by this onboarding run | none |

## Read this first

1. `AI_INDEX.md` for a fast repository overview.
2. `AGENTS.md` for generic agent operating rules.
3. `.ai/START_HERE.md` for the pasteable first-session prompt.
4. `.ai/PROJECT_MAP.md` and `.ai/ARCHITECTURE.md` before editing source.
5. `.ai/COMMANDS.md`, `.ai/TESTING.md`, and `.ai/SECURITY.md` before validating changes.

## Verified repository purpose

FXNews is a single MetaTrader 5 custom indicator. It scans a configurable FX symbol basket and timeframe list from one chart, ranks fresh breakout or impulse events, and renders chart dashboard rows plus optional local sound or terminal push alerts. The README states that it never opens, closes, modifies, or manages trades and that it avoids WebRequest, DLLs, external feeds, CSV logging, and disk output.

Evidence:
- `README.md`
- `FXNews.mq5`

## Architecture summary

FXNews is implemented as a single MQL5 indicator file. The runtime lifecycle starts in `OnInit()`, validates inputs, parses symbols/timeframes, initializes calendar and history buffers, selects symbols, then schedules `OnTimer()` scanning. Live mode repeatedly updates market data, calculates currency strength, builds composite scores, updates signal state, groups correlated alerts, and redraws dashboard status/history. Validation and Autotune modes run a one-shot M1-history backtest from the timer path, print journal reports, then update chart status.

Evidence:
- `FXNews.mq5` (`#property indicator_chart_window`, `OnInit`, `OnTimer`, `ScanAll`, `RunHistoricalOperatingMode`)

## Primary concepts

| Concept | Verified facts | Source |
|---|---|---|
| Operating modes | `LIVE`, `VALIDATION`, `AUTOTUNE`; historical modes run through `RunHistoricalOperatingMode()`. | `FXNews.mq5` |
| Scan profiles | User symbols are combined with parsed timeframes into `SymbolProfile` entries. | `ParseSymbols`, `ParseTimeframes`, `ResetProfile` in `FXNews.mq5` |
| Market data | Uses MT5 symbol/tick/rates APIs such as `SymbolSelect`, `SymbolInfoTick`, `CopyTicks`, and `CopyRates`. | `FXNews.mq5` |
| Score model | Composite score combines execution, breakout, impulse, currency flow, regime, and optional calendar context. | `BuildCompositeSignalScore` and evaluator functions in `FXNews.mq5` |
| Dashboard | Uses chart label objects prefixed by `g_object_prefix`; status line and recent signal history are rendered on-chart. | `UpdateDashboard`, `SetDashboardRow`, `DashboardName` in `FXNews.mq5` |
| Alerts | `PlaySound` and `SendNotification` are gated by `EnableSoundAlert` and `EnablePushNotification`. | `SendOptionalAlert` in `FXNews.mq5` |
| Historical reports | Validation/autotune write report lines to the MT5 Journal and chart dashboard state. | `BuildValidationReport`, `BuildAutotuneReport`, `PrintHistoricalReportToJournal` in `FXNews.mq5` |

## Directory and file map

| Path | Role | Notes |
|---|---|---|
| `FXNews.mq5` | Product implementation | Single-file MQL5 custom indicator; do not split casually without a deliberate refactor plan. |
| `README.md` | Human-facing repository summary and wiki links | AI onboarding block is intentionally near the top. |
| `.gitignore` | Ignores compiled/runtime MT5 artifacts | Includes `*.ex5`, logs, temp files, tester/profile folders. |
| `AI_INDEX.md` | Primary future-agent entrypoint | Generated/refreshable onboarding index. |
| `AGENTS.md` | Generic agent operating instructions | Vendor-neutral. |
| `.ai/*` | Detailed onboarding context | Machine/human-readable repository map, architecture, commands, testing, security, playbooks, manifest. |

## Main entrypoints

| Entrypoint | Runtime role | Caution |
|---|---|---|
| `OnInit()` | Initializes settings, validates input, parses profiles, initializes caches/buffers, selects symbols, sets timer. | Changes here can prevent indicator startup. |
| `OnTimer()` | Dispatches historical mode or live scanning. | Timer cadence is controlled by `ScanIntervalSeconds`. |
| `OnCalculate()` | Indicator calculation callback; currently returns `rates_total`. | Do not move scanning here without performance review. |
| `ScanAll()` | Live scan loop: market data, currency strength, scoring, state, dashboard. | Hot path; preserve bounded work. |
| `BuildCompositeSignalScore()` | Aggregates scoring components and score caps. | Keep score semantics explainable; update docs if weights/caps change. |
| `RunHistoricalOperatingMode()` | Validation/autotune execution path. | Uses historical M1 data; avoid disk output unless intentionally changing product policy. |

## Build, run, and validation commands

No repository-local package manager, shell build system, CI workflow, or Docker setup was found during bootstrap inspection. Use MetaEditor/MetaTrader 5 for compile/runtime validation.

| Task | Command or workflow | Status |
|---|---|---|
| Install dependencies | Install MetaTrader 5 and use its MQL5/Indicators folder. | verified by project type, not scripted |
| Build | Compile `FXNews.mq5` in MetaEditor; expected artifact is `FXNews.ex5`. | manual |
| Local run | Attach compiled indicator to an MT5 chart. | manual |
| Live validation | Use `OperatingMode=FXNEWS_MODE_LIVE` with safe demo/non-production settings. | manual |
| Historical validation | Use `OperatingMode=FXNEWS_MODE_VALIDATION`; inspect MT5 Journal. | manual |
| Autotune | Use `OperatingMode=FXNEWS_MODE_AUTOTUNE`; inspect MT5 Journal and runtime settings. | manual |
| Automated tests | none detected | unknown |
| CI/CD | none detected | unknown |

See `.ai/COMMANDS.md` and `.ai/TESTING.md`.

## Important conventions

- Keep source-grounded claims tied to `FXNews.mq5`, `README.md`, or `.gitignore`.
- Treat the indicator as chart-only unless source code intentionally changes that policy.
- Do not add trade execution calls, disk writes, DLL imports, external web requests, or persistent output without explicit human approval and documentation updates.
- Maintain the distinction between raw scanner ranking score and trade/probability claims.
- Preserve manual MT5 validation details in docs because no automated test harness is currently present.
- Avoid committing compiled `*.ex5`, logs, tester folders, or profile/runtime artifacts ignored by `.gitignore`.

## Security-sensitive areas

| Area | Why it matters | Source |
|---|---|---|
| Trade execution boundary | README says FXNews never manages trades; source should remain indicator-only unless explicitly approved. | `README.md`, `FXNews.mq5` |
| Alerts | Push notifications can send signal data outside the chart terminal when enabled. | `EnablePushNotification`, `SendOptionalAlert` |
| Economic calendar | Uses MT5 calendar APIs, not WebRequest, when enabled. | `RefreshCalendarCache` |
| Runtime artifacts | Compiled files/logs/tester data are ignored. | `.gitignore` |
| Financial wording | Scores are scanner rankings, not guaranteed win probabilities or automatic trade instructions. | `README.md` |

## Common task map

| Task | Start here |
|---|---|
| Change default inputs or thresholds | `FXNews.mq5` input declarations, `ValidateInputs`, `.ai/PLAYBOOKS.md` |
| Change signal scoring | `BuildCompositeSignalScore`, evaluator functions, `.ai/COMPONENTS.md` |
| Change dashboard text/layout | dashboard constants, `UpdateDashboard`, `FormatDashboardSignalText`, `SetDashboardRow` |
| Change historical validation/autotune | `RunHistoricalOperatingMode`, historical stats/report functions |
| Change symbol/timeframe parsing | `ParseSymbols`, `ParseTimeframes`, `ParseTimeframeToken` |
| Add tests | `.ai/TESTING.md`; no existing harness was detected |
| Change docs only | README and `.ai/*`; keep onboarding metadata current |

## Facts, inferences, unknowns, conflicts

| Type | Item |
|---|---|
| verified | Single MQL5 source file `FXNews.mq5` is the product implementation. |
| verified | README describes chart-only MT5 indicator behavior and no trade management. |
| verified | `.gitignore` excludes MT5 compiled/runtime/tester artifacts. |
| verified | No `AI_INDEX.md`, `AGENTS.md`, or `.ai/MANIFEST.json` existed on `main` before bootstrap. |
| inferred | Build validation requires MetaEditor because no repository-local compiler wrapper exists. |
| unknown | Exact supported MetaTrader/MetaEditor build version is not declared in the repo. |
| unknown | Wiki content is linked from README but not versioned in the repository tree inspected here. |
| conflicts | none detected during bootstrap. |

## What changed since last index

Bootstrap mode: no previous index was found, so there is no previous indexed commit to compare. This run added the vendor-neutral onboarding system and README pointer block only.

## Local AI files

- `AGENTS.md`
- `.ai/START_HERE.md`
- `.ai/PROJECT_MAP.md`
- `.ai/ARCHITECTURE.md`
- `.ai/COMPONENTS.md`
- `.ai/COMMANDS.md`
- `.ai/TESTING.md`
- `.ai/SECURITY.md`
- `.ai/PLAYBOOKS.md`
- `.ai/KNOWN_UNKNOWNS.md`
- `.ai/CHANGELOG.md`
- `.ai/MANIFEST.json`
