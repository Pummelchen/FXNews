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

# Component Cards

## 1. Runtime bootstrap and profile construction

| Field | Value |
|---|---|
| Responsibility | Initialize effective settings, validate inputs, parse symbols/timeframes, allocate arrays, select symbols, and start timer. |
| Key files/functions | `FXNews.mq5`: input declarations, `InitializeRuntimeSettings`, `ValidateInputs`, `ParseSymbols`, `ParseTimeframes`, `EnsureSymbolReady`, `OnInit` |
| Public interface | Indicator inputs such as `OperatingMode`, `SymbolsToScan`, `TimeframesToScan`, thresholds, cooldowns, calendar/session settings. |
| Dependencies | MT5 indicator lifecycle, symbol metadata APIs. |
| Invariants | Invalid input should return `INIT_PARAMETERS_INCORRECT`; no valid symbol profiles means startup failure. |
| Risks | A default input change can affect all scans and historical backtests. |

## 2. Market data and tick quality

| Field | Value |
|---|---|
| Responsibility | Load live ticks/rates, calculate spreads, ATR/ranges/movement, snapshots, median spread, tick sample quality. |
| Key files/functions | `UpdateMarketData`, `UpdateRatesData`, `UpdateMovementData`, `UpdateTickQuality`, `AddSnapshot`, `AddSpreadSample`, `CalculateMedianSpread` |
| External dependencies | `SymbolInfoTick`, `CopyTicks`, MT5 rates/time-series functions. |
| Invariants | Quotes must be fresh and bid/ask valid; spread and ATR gates protect score quality. |
| Risks | Performance and terminal data availability; thin tick data can degrade impulse scoring. |

## 3. Composite scoring engine

| Field | Value |
|---|---|
| Responsibility | Build directional score, block low-quality signals, explain reasons and caps. |
| Key files/functions | `BuildCompositeSignalScore`, `EvaluateExecutionQuality`, `EvaluateBreakoutStructure`, `EvaluateImpulseQuality`, `EvaluateCurrencyFlowQuality`, `EvaluateRegimeContext`, `EvaluateCalendarContext`, `BuildReasonSummary` |
| Public interface | Dashboard percentage and tags; debug journal output when enabled. |
| Internal dependencies | Current profile market data, snapshots, spread history, currency strength, session/calendar context. |
| Invariants | Scores are raw scanner rankings, not guaranteed probabilities. Caps are part of explainability and risk control. |
| Tests | No automated tests detected; compile plus MT5 runtime/historical validation required. |
| Risks | Weight/cap changes can materially alter signal behavior across all symbols/timeframes. |

## 4. Currency-flow and alert grouping

| Field | Value |
|---|---|
| Responsibility | Estimate base/quote currency strength, basket agreement, flow conflict, and dominant currency grouping. |
| Key files/functions | `CalculateCurrencyStrength`, `EvaluateCurrencyFlowQuality`, `CalculateBasketAgreement`, `DominantCurrencyFlow`, `UpdateAlertGroups` |
| Dependencies | Fresh profiles, ATR, spread quality, movement data, currency code map. |
| Invariants | Disabled currency strength should cap scores; conflicts can block or cap signals. |
| Risks | Basket logic is sensitive to broker symbols and invalid/thin pairs. |

## 5. Signal lifecycle state machine

| Field | Value |
|---|---|
| Responsibility | Promote candidates, maintain active signals, expire stale signals, start cooldowns, push signal history. |
| Key files/functions | `BreakoutEventState`, `UpdateSignalState`, `PickBestDirection`, `IsConfirmedSignal`, `ActivateSignal`, `EndActiveSignal`, `StartCooldown`, `PushSignalHistory` |
| Public interface | Active dashboard signals, recent signal history, optional alert dispatch. |
| Invariants | Cooldowns throttle repeated failed/valid signals; `SignalTTLSeconds` and age caps limit stale events. |
| Risks | State-machine edits can cause duplicate alerts, missing alerts, or stale dashboard rows. |

## 6. Dashboard and diagnostics

| Field | Value |
|---|---|
| Responsibility | Render status, latest high-quality messages, diagnostics, and tooltips as chart labels. |
| Key files/functions | dashboard constants, `UpdateDashboard`, `UpdateActivityStatusLine`, `DiagnosticsText`, `FormatDashboardSignalText`, `SetDashboardRow`, `FitDashboardText`, `CleanupDashboardObjects` |
| External dependencies | MT5 chart object APIs. |
| Invariants | Object names use `g_object_prefix`; deinit should remove dashboard objects. |
| Risks | Layout changes can reduce readability or leave stale chart objects. |

## 7. Alerts

| Field | Value |
|---|---|
| Responsibility | Optional local sound and push notification for new/strong signals. |
| Key files/functions | `SendOptionalAlert`, `EnableSoundAlert`, `EnablePushNotification` |
| External dependencies | `PlaySound`, `SendNotification`, MT5 terminal notification settings. |
| Invariants | Alerts are opt-in by inputs. |
| Risks | Notification text can leave the local chart context; keep concise and non-advisory. |

## 8. Historical validation and autotune

| Field | Value |
|---|---|
| Responsibility | Run M1-history backtests, calculate outcomes, compare parameter candidates, print MT5 Journal reports. |
| Key files/functions | `RunHistoricalOperatingMode`, `RunHistoricalBacktest`, `BuildHistoricalSignalScore`, `BuildValidationReport`, `RunAutotuneBacktest`, `BuildAutotuneReport`, `PrintHistoricalReportToJournal` |
| External dependencies | `CopyRates`, MT5 historical data availability. |
| Invariants | Historical modes do not run live scanning and should report through dashboard/journal. |
| Risks | Historical data quality and broker history gaps affect results; no repository-local test fixture exists. |

## 9. Economic calendar context

| Field | Value |
|---|---|
| Responsibility | Optional scoring/blocking context for nearby high-impact calendar events. |
| Key files/functions | `UseEconomicCalendarContext`, `RefreshCalendarCache`, `EvaluateCalendarContext`, `CalendarPreNewsBlock` |
| External dependencies | MT5 calendar APIs. |
| Invariants | Calendar context is disabled by default in current inputs; no WebRequest dependency is required by this code path. |
| Risks | Calendar availability varies by broker/terminal setup; do not assume it is always present. |
