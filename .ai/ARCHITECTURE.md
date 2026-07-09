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

# Architecture

## High-level architecture

FXNews is a single-file MQL5 custom indicator that runs inside MetaTrader 5. It does not expose an HTTP API, CLI, database, server process, or frontend application. The runtime boundary is the MT5 terminal/chart: market data and calendar data come from MT5 APIs, and output is chart labels, MT5 Journal lines, optional sound, and optional push notifications.

Evidence:
- `FXNews.mq5`
- `README.md`

## Runtime lifecycle

```text
MT5 loads indicator
  -> OnInit()
       -> effective runtime settings copied from inputs
       -> inputs validated
       -> symbol/timeframe scan profiles built
       -> calendar cache and history buffers initialized
       -> symbols selected/resolved
       -> EventSetTimer(ScanIntervalSeconds)

Timer tick
  -> OnTimer()
       -> RunHistoricalOperatingMode() if Validation/Autotune
       -> ScanAll(false) otherwise

Unload
  -> OnDeinit()
       -> EventKillTimer()
       -> CleanupDashboardObjects()
```

`OnCalculate()` currently returns `rates_total`; the timer path, not the indicator calculation callback, drives scanning.

## Live scan flow

```text
ScanAll
  -> UpdateMarketData for every SymbolProfile
       -> EnsureSymbolReady
       -> SymbolInfoTick
       -> AddSnapshot / AddSpreadSample
       -> UpdateRatesData / UpdateMovementData / UpdateTickQuality
  -> CalculateCurrencyStrength
  -> CalculateScoresAndUpdateState for every profile
       -> BuildCompositeSignalScore UP/DOWN
       -> UpdateSignalState
  -> UpdateAlertGroups
  -> UpdateScanDiagnostics
  -> UpdateDashboard or UpdateActivityStatusLine
```

Important implication: `ScanAll()` is a hot timer path. Changes here should preserve bounded work per scan profile and avoid slow external operations.

## Scoring architecture

`BuildCompositeSignalScore()` constructs a `CompositeSignalScore` from component evaluators:

| Evaluator | Responsibility |
|---|---|
| `EvaluateExecutionQuality` | quote freshness, spreads, spread-to-ATR, spread z-score, tick gap. |
| `EvaluateBreakoutStructure` | range compression, breakout distance, close location, hold score, body quality, wick/fakeout penalty. |
| `EvaluateImpulseQuality` | 5s/10s/30s/60s speed z-scores, ATR expansion, tick rate/volume, continuation, exhaustion. |
| `EvaluateCurrencyFlowQuality` | base/quote currency strength edge, basket agreement, conflict penalty. |
| `EvaluateRegimeContext` | session quality, M5/M15 context, volatility regime, rollover penalty. |
| `EvaluateCalendarContext` | optional MT5 calendar proximity/high-impact context. |

The composite score is then capped by explainability and safety conditions such as no calendar cap, flow conflict, mediocre execution, weak hold/body, MTF rejection, unsupported impulse, overextension, age, calendar uncertainty, single-feature, and elite-score caps.

## Signal state architecture

The state machine uses `BreakoutEventState` values including idle, watch, candidate, active unconfirmed, active confirmed, active signal, expired, failed fast, and cooldown. `UpdateSignalState()` picks the best direction, handles active signal continuation/reversal/expiry, promotes candidates when confirmation rules pass, and starts cooldowns after failed or ended signals.

Confirmation modes are:

- `CONFIRM_LIVE_TICK`
- `CONFIRM_BAR_CLOSE`
- `CONFIRM_HYBRID`

## Historical validation/autotune architecture

Historical modes are timer-driven and one-shot:

```text
RunHistoricalOperatingMode
  -> BuildBaseHistoricalParams
  -> RunHistoricalBacktest + BuildValidationReport       [Validation]
  -> RunAutotuneBacktest + BuildAutotuneReport           [Autotune]
  -> UpdateHistoricalReportDashboard
```

Historical backtests use M1 rates loaded through `CopyRates`, aggregate scan timeframe bars in code, calculate historical signal scores, collect outcome metrics across configured horizons, and print report lines to the MT5 Journal.

Autotune evaluates candidate parameter profiles and may apply better settings to runtime variables for the current session. No generated settings file was found in source; reports are journal/dashboard output.

## Dashboard/output architecture

Dashboard output uses MT5 chart label objects:

- object prefix: `COBR_` plus chart id modulo suffix;
- dashboard constants control row count, font size/name, offsets, and text limits;
- `UpdateDashboard()` renders status plus current active signal rows, falling back to recent displayable signal history;
- `DiagnosticsText()` is used as a tooltip/status diagnostic, optional diagnostics row, and includes `disk_io=disabled`;
- `CleanupDashboardObjects()` deletes dashboard objects on deinit.

## Trust boundaries

| Boundary | Current behavior | Required caution |
|---|---|---|
| Trading account | No trade management claimed by README and no trade execution boundary should be added casually. | Human approval before any order/account logic. |
| Terminal notifications | Optional `SendNotification` can leave the chart/terminal context. | Keep opt-in and document changes. |
| Local machine filesystem | README states no disk output; `.gitignore` excludes runtime artifacts. | Human approval before File* output/logging. |
| Network/external data | README states no WebRequest/external feeds; calendar context uses MT5 calendar APIs when enabled. | Human approval before WebRequest/DLL/external feeds. |
| Financial interpretation | Scores are rankings, not guaranteed probabilities. | Avoid predictive or advisory wording. |

## Source-file references

- `FXNews.mq5`: all runtime/source architecture.
- `README.md`: product-level behavior and explicit boundaries.
- `.gitignore`: generated/runtime artifact policy.
