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

# Testing and Validation

## Current test framework status

No automated repository test framework was detected during bootstrap inspection. No CI workflow was found in `.github/workflows/ci.yml`, and no package-manager test scripts were found in common project files.

Current minimum validation for source changes is manual MetaEditor/MetaTrader 5 validation.

Evidence:
- `FXNews.mq5`
- `README.md`
- `.gitignore`

## Minimum validation before a PR

| Change type | Minimum validation |
|---|---|
| Docs-only onboarding change | JSON-valid `.ai/MANIFEST.json`; README links checked; only docs/onboarding files changed; no secret-like values. |
| Any `FXNews.mq5` edit | Compile in MetaEditor and report compiler result. |
| Startup/input edit | Attach to MT5 chart and verify initialization or intended parameter rejection. |
| Scoring edit | Compile, run live/demo chart scan, inspect score/reason behavior, and consider historical validation. |
| Dashboard edit | Compile, attach, resize chart if layout is involved, verify status/history rows and tooltips. |
| Alert edit | Compile, test sound/push intentionally in a safe terminal, verify opt-in behavior. |
| Historical validation/autotune edit | Run the relevant operating mode and inspect MT5 Journal output. |
| Calendar edit | Test with `UseEconomicCalendarContext` both false and true if terminal calendar data is available. |

Do not claim validation passed unless it was actually run.

## Manual test scenarios

### 1. Compile test

```text
Open FXNews.mq5 in MetaEditor -> Compile
```

Record:

- compile result;
- warnings/errors;
- MetaEditor/terminal version if known.

### 2. Basic live startup

1. Attach the compiled indicator to an MT5 chart in a demo/non-production account.
2. Use default inputs first.
3. Confirm the dashboard status line appears.
4. Confirm no unexpected files are created by the indicator.
5. Confirm no orders/trade operations occur.

### 3. Symbol/timeframe parsing

Change `SymbolsToScan` and `TimeframesToScan` in controlled ways:

- semicolon/comma/whitespace-separated symbols;
- duplicate symbols;
- broker suffix/prefix variants if available;
- supported timeframe tokens from `ParseTimeframeToken`.

Expected behavior: unsupported timeframe tokens are skipped, duplicate timeframes are not duplicated, and valid symbol/timeframe profiles initialize.

### 4. Scoring/debug validation

For scoring-related changes:

1. Enable `DebugScoreBreakdown` and `DebugPrintToJournal` only in a local/demo terminal.
2. Observe score component summaries for active signals.
3. Verify block/cap reasons remain explainable.
4. Do not interpret scores as guaranteed probabilities.

### 5. Dashboard validation

Check:

- status line text from `ActivityStatusText`;
- current active signal rows and recent signal history fallback formatting;
- chart width truncation through `FitDashboardText`;
- cleanup after indicator removal through `CleanupDashboardObjects`.

### 6. Historical validation mode

Set `OperatingMode=FXNEWS_MODE_VALIDATION`.

Expected behavior:

- live scanning is not run during historical mode;
- dashboard indicates historical processing/ready state;
- report lines are printed to MT5 Journal.

### 7. Autotune mode

Set `OperatingMode=FXNEWS_MODE_AUTOTUNE`.

Expected behavior:

- candidate parameter profiles are evaluated;
- best settings may be applied to runtime variables only when objective/sample thresholds pass;
- session continues in LIVE mode afterward;
- reports are available in MT5 Journal.

## Fixtures and mocks

No repository-local fixtures, mocks, sample data, or test harness were found. Historical validation depends on MT5 broker/terminal M1 history availability.

## Slow/flaky areas

Potentially slow or environment-sensitive areas:

- `CopyRates` in historical validation/autotune;
- `CopyTicks` for impulse/tick-quality scoring;
- MT5 economic calendar data availability;
- broker symbol naming and history gaps;
- dashboard/chart-object rendering differences across terminal/chart settings.

## Recommended future test investment

If maintainers want stronger automation, consider adding a harness that can exercise pure helper logic outside MT5 where possible, plus a documented MetaEditor compile command or CI-compatible MQL5 compile step if a safe/licensed runner is available. This is a recommendation, not a currently verified capability.
