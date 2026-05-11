# QuickStart: Autolearning Before Live Use

Use this workflow before relying on FXNews as a day-trader radar. The goal is to let the indicator learn from your broker's own M1 history through non-trading Validation and Autotune, then use the live scanner with parameters that were checked on your feed.

FXNews does not write logs or settings files. Validation and Autotune write detailed reports to the MT5 Journal and show only a completion message on the chart.

## 1. Prepare MT5 History

1. Compile and attach `FXNews` from `MQL5/Indicators/FXNews`.
2. Add the pairs from `SymbolsToScan` to Market Watch.
3. Open or scroll enough M1 history for the pairs you plan to scan.
4. Keep the first run practical:
   - `HistoricalLookbackDays = 90`
   - `TimeframesToScan = M1,M5,M15,M30,H1`
   - start with your main day-trading pairs before using 50+ symbols.

If MT5 has thin or missing history, Validation and Autotune can undercount signals or produce weak recommendations.

## 2. Run Baseline Validation

Set:

```text
OperatingMode = FXNEWS_MODE_VALIDATION
```

Recommended first-pass settings:

```text
HistoricalLookbackDays = 90
HistoricalStepMinutes = 1
HistoricalWarmupBars = 500
HistoricalMaxSignalsPerProfile = 250
OutcomeTargetAtr = 0.50
OutcomeStopAtr = 0.35
```

Read the MT5 Journal report before changing anything. Focus on:

- signal count: avoid judging a setting from a tiny sample;
- score edge: higher score buckets should outperform lower buckets;
- 30 minute average R: useful for judging follow-through;
- target-first rate versus stop-first rate;
- profit-factor proxy;
- weak symbols or timeframes that produce noisy alerts.

Do not proceed to live use if high score buckets do not outperform lower buckets on your broker feed.

## 3. Run Autolearning With Autotune

Set:

```text
OperatingMode = FXNEWS_MODE_AUTOTUNE
```

Autotune runs the same closed-M1 historical simulation across a small practical parameter set. Treat it as local autolearning for your broker feed, not as curve-fit proof.

Use:

```text
AutotuneMinSignals = 100
HistoricalLookbackDays = 90
```

The report compares current inputs with the best candidate and shows improvement statistics. Prefer candidates that improve several metrics together:

- higher 30 minute average R;
- better target-first rate;
- better profit-factor proxy;
- clearer score edge;
- enough signals to trust the sample.

Avoid candidates that only improve one metric while reducing sample count too much.

## 4. Apply Recommended Settings Manually

Autotune cannot rewrite MT5 input parameters at runtime because MQL5 inputs are read-only. Apply the recommended settings manually in the indicator input dialog.

Typical settings Autotune may influence:

- `MinDisplayConfidence`
- `RangeLookbackM1`
- `BreakoutBufferATR`
- `MinBreakoutBufferPips`
- `MaxSpreadToAtrRatio`
- `MinImpulseZForSignal`
- `MaxOverextensionAtr`
- `OutcomeTargetAtr`
- `OutcomeStopAtr`

Keep execution gates strict unless you have a clear broker-specific reason to loosen them.

## 5. Re-Validate Out Of Sample

After applying the suggested settings, run Validation again on a different window where possible:

- first pass: last 90 days;
- second pass: shorter recent window, such as 30 days;
- optional: change symbol groups or sessions and confirm the edge is not isolated to one pocket of history.

A usable configuration should show the same general behavior:

- `75+` scores outperform `60-69`;
- `80+` scores are rarer but cleaner;
- high scores are not mostly caused by spread spikes or late overextended moves;
- London and New York results make sense for day trading.

## 6. Switch To Live Scanner Mode

Set:

```text
OperatingMode = FXNEWS_MODE_LIVE
```

Recommended live workflow:

1. Keep `ShowOnlyGroupLeaders=false` for the first session so you can see correlated behavior.
2. If the chart gets noisy, set `ShowOnlyGroupLeaders=true`.
3. Treat `RAW` percentages as ranking strength, not win probability.
4. Prioritize alerts with clean execution, fresh age, normal spread-to-ATR, and confirming flow.
5. Ignore signals during rollover, stale quotes, or abnormal spread conditions.

## 7. Ongoing Routine

Run Autotune again when the market regime or broker feed changes:

- after changing broker or account type;
- after major spread/commission changes;
- after several weeks of noticeably different volatility;
- before trading a new symbol basket;
- before expanding to many timeframes.

Use Autotune to guide inputs, then always validate again. The best live configuration is the one that remains stable across broker data, sessions, symbols, and recent history.
