# Signal Logic

FXNews now separates the raw event-quality score from calibration status:

```text
SYMBOL TIMEFRAME UP|DOWN NN% RAW|CAL|LOW-N|STALE
```

The percentage is an alert-ranking score, not a guaranteed win probability and not an automatic entry instruction.

## Composite Score

The EA decomposes each directional candidate into explicit components:

- Execution quality: spread, median spread, spread z-score, quote age, tick gap, and spread cost versus ATR.
- Breakout structure: range compression, distance past the boundary, candle close location, hold time outside the range, body quality, wick rejection, and snapback risk.
- Impulse quality: robust 5/10/30/60 second speed z-scores, acceleration, scan-timeframe candle expansion, tick rate, tick-volume z-score, continuation, and exhaustion risk.
- Currency flow: base and quote strength, directional edge, weighted basket agreement, and conflict penalty.
- Regime context: session quality, M5/M15 alignment, and volatility regime.
- Calendar context: optional built-in MT5 economic-calendar proximity and high-impact context when enabled.
- Tick quality: CopyTicks sample count, freshness, and coverage when available.
- Calibration metadata: sample count, score bucket, profit-factor proxy, expectancy, and staleness.

The raw component blend is mapped into a 0-100 score, then capped by hard practical rules. One strong feature cannot create an 80+ score by itself. Scores above 80 need good execution, real breakout or impulse quality, and no major context conflict. Scores above 90 require strong hold, strong flow, good regime context, and no serious uncertainty.

## Score Status

- `RAW`: no trusted calibration is active, so the raw composite score is displayed.
- `CAL`: matching symbol/timeframe/session/direction/bucket calibration has enough fresh samples.
- `LOW-N`: the raw score is high, but calibration sample count or expectancy is not strong enough for promotion.
- `STALE`: matching calibration exists but is older than `CalibrationMaxAgeDays`.

Strong alerts can require positive calibrated expectancy through `RequirePositiveExpectancyForStrongAlert`.

## Hard Gates

Signals are blocked before scoring when execution quality is not tradable:

- stale or invalid quote;
- missing M1/M5/M15 context data;
- missing ATR or range data;
- spread above `MaxSpreadPips`;
- spread too high versus recent median spread;
- excessive spread cost versus ATR when `UseStrictExecutionGate=true`;
- excessive tick gap or spread z-score when strict gating is enabled;
- rollover window when `IgnoreRolloverTime=true`.

Severe execution problems are blocks, not small confidence reductions. Mediocre-but-allowed execution caps the final score at 69.

## Breakout And Impulse Engines

The technical breakout engine scores whether price is cleanly escaping a recent scan-timeframe range. It rewards compressed but active ranges, meaningful distance beyond the boundary, a strong close, a useful candle body, and a hold outside the range.

The impulse engine detects tradable repricing from chart behavior only. It rewards abnormal directional speed, acceleration, ATR expansion, tick-rate/tick-volume support, and continuation after the first push. Overextended moves and unsupported speed spikes are capped.

## Currency And Context

Currency flow is calculated from the configured symbol basket with inverse-volatility and spread-aware weighting. UP means the base currency is strengthening against the quote currency. DOWN means the base currency is weakening against the quote currency.

M5 and M15 context are used even when higher timeframes are scanned. Strong short-term rejection caps the score. Missing basket confirmation can still allow signals, but it caps high confidence; active basket conflict caps or blocks depending on settings.

## Optional Calendar Context

`UseEconomicCalendarContext=false` by default. When enabled, FXNews uses only the built-in MT5 economic calendar. It does not use external feeds, `WebRequest`, or DLLs.

Calendar context can cap signals immediately before high-impact releases when configured, slightly support just-released events when price action agrees, or apply uncertainty caps when relevant events are nearby but not yet resolved.

Dashboard calendar tags:

- `NEWS_PRE_BLOCK`
- `NEWS_JUST_RELEASED`
- `NEWS_HIGH_IMPACT_NEAR`
- `NEWS_NONE`
- `NEWS_UNAVAILABLE`

## Alert Grouping

Correlated alerts are grouped by dominant currency flow, such as `USD-` for broad USD weakness. The dashboard marks a group leader using execution quality, score status, score, freshness, flow confirmation, and spread-to-ATR. `ShowOnlyGroupLeaders=true` suppresses correlated member rows.

## Self-Auditing Logs

With `EnableSignalLogging=true`, the EA appends `SIGNAL` rows to `FXNews_signals.csv`. Rows include the visible score, raw score, calibrated score, execution metrics, component scores, cap reasons, and entry reference price.

With `EnableOutcomeLabeling=true`, the EA later appends `OUTCOME` rows for 5, 15, and 30 minute horizons. Outcomes include MFE, MAE, MFE/ATR, MAE/ATR, target-before-stop labeling, `final_outcome_label`, and `continuation_score` fields.

Use the CSV to validate score buckets empirically. Compare 60-69, 70-79, 80-89, and 90+ buckets by continuation score, target-before-stop rate, MFE/ATR, and MAE/ATR. Higher scores should become stronger radar events over enough samples, not guaranteed winners.

Preferred score buckets are now `60-64`, `65-69`, `70-74`, `75-79`, `80-84`, and `85+`.
