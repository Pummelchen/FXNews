# Signal Logic

FXNews displays raw event-quality scores in the latest-five message list:

```text
YYYY-MM-DD HH:MM:SS - SYMBOL TIMEFRAME UP|DOWN - NN%
```

The first line is reserved for activity status, for example:

```text
BREAKOUT RADAR | LIVE scanning 252 profiles | valid=28 invalid=0 active=1 | scan 8.4ms | 2026-05-16 15:35:45
```

No empty placeholders are displayed.

The status line uses the current chart line color, and signal messages are white.

The percentage is an alert-ranking score, not a guaranteed win probability and not an automatic entry instruction. Disk-based calibration and CSV logging are intentionally disabled.

## Composite Score

FXNews decomposes each directional candidate into explicit components:

- Execution quality: spread, median spread, spread z-score, quote age, tick gap, and spread cost versus ATR.
- Breakout structure: range compression, distance past the boundary, candle close location, hold time outside the range, body quality, wick rejection, and snapback risk.
- Impulse quality: robust 5/10/30/60 second speed z-scores, acceleration, scan-timeframe candle expansion, tick rate, tick-volume z-score, continuation, and exhaustion risk.
- Currency flow: base and quote strength, directional edge, weighted basket agreement, and conflict penalty.
- Regime context: session quality, M5/M15 alignment, and volatility regime.
- Calendar context: optional built-in MT5 economic-calendar proximity and high-impact context when enabled.
- Tick quality: CopyTicks sample count, freshness, and coverage when available.

The raw component blend is mapped into a 0-100 score, then capped by hard practical rules. One strong feature cannot create an 80+ score by itself. Scores above 80 need good execution, real breakout or impulse quality, and no major context conflict. Scores above 90 require strong hold, strong flow, good regime context, and no serious uncertainty.

## Status

- `RAW`: chart-only raw composite score. This is the internal score status; the compact latest-five message text only shows the percentage.

Historical validation and autotune reports can help judge whether higher raw buckets are outperforming lower raw buckets for the current broker/feed. FXNews does not read calibration files and does not write score logs.

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

Correlated alerts are grouped by dominant currency flow, such as `USD-` for broad USD weakness. The dashboard marks a group leader using execution quality, score, freshness, flow confirmation, and spread-to-ATR. `ShowOnlyGroupLeaders=true` suppresses correlated member rows.

## Historical Validation Mode

`FXNEWS_MODE_VALIDATION` is an on-chart historical simulation. It pulls closed M1 bars from MT5's local history database for every configured symbol, walks backward-to-forward over the last `HistoricalLookbackDays`, simulates symbol/timeframe alert candidates, evaluates 5/15/30 minute forward MFE/MAE outcomes, and renders the summary on the chart.

This mode does not write CSV logs or report files. The report includes signal count, average score, profit-factor proxy, average R, target-first and stop-first rates, score edge, and bucket quality.

Preferred score buckets are `60-64`, `65-69`, `70-74`, `75-79`, `80-84`, and `85+`.

## Autotune Mode

`FXNEWS_MODE_AUTOTUNE` runs the same M1-history simulation over the current inputs and a small practical candidate set. The report shows the best candidate, the current baseline, and improvement in 30 minute R, hit rate, profit-factor proxy, and score edge.

Autotune reports recommended effective settings. It does not permanently rewrite MT5 inputs, because MQL5 input variables are read-only at runtime and the project intentionally avoids writing settings files.
