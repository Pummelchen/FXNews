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

# Project Playbooks

## Playbook: Change scanner inputs or defaults

1. Inspect input declarations near the top of `FXNews.mq5`.
2. Inspect `InitializeRuntimeSettings()` for effective runtime variables.
3. Inspect `ValidateInputs()` for allowed bounds.
4. Update README/wiki-facing docs if user-visible behavior changes.
5. Compile in MetaEditor.
6. Attach to an MT5 chart and verify startup status.
7. If historical behavior is affected, run validation/autotune mode.

Caution: Defaults affect every symbol/timeframe profile and historical validation baseline.

## Playbook: Add or change supported timeframe tokens

1. Inspect `TimeframesToScan`, `ParseTimeframes()`, `ParseTimeframeToken()`, and `TimeframeMinutes()`.
2. Add or adjust token parsing and label mapping consistently.
3. Ensure historical aggregation supports the timeframe length.
4. Validate with a controlled `TimeframesToScan` list.
5. Compile and run a demo chart scan.

Caution: unsupported or duplicate timeframes are intentionally skipped/deduplicated.

## Playbook: Change scoring behavior

1. Identify the affected evaluator:
   - execution: `EvaluateExecutionQuality`;
   - breakout: `EvaluateBreakoutStructure`;
   - impulse: `EvaluateImpulseQuality`;
   - currency flow: `EvaluateCurrencyFlowQuality`;
   - regime: `EvaluateRegimeContext`;
   - calendar: `EvaluateCalendarContext`.
2. Inspect `BuildCompositeSignalScore()` for weights and caps.
3. Update reason summaries/tags if explanations change.
4. Compile.
5. Use debug journal output in a local/demo terminal if needed.
6. Run historical validation for material changes.

Caution: scoring changes can alter signal frequency and ranking across all instruments.

## Playbook: Change dashboard layout or text

1. Inspect dashboard constants near the top of `FXNews.mq5`.
2. Inspect `UpdateDashboard()`, `ActivityStatusText()`, `DiagnosticsText()`, `FormatDashboardSignalText()`, `FormatSignalHistoryText()`, and `FitDashboardText()`.
3. Preserve truncation behavior for narrow charts.
4. Compile and test on different chart widths.
5. Confirm `CleanupDashboardObjects()` removes objects on unload.

Caution: chart label object names are generated from `g_object_prefix`.

## Playbook: Change alerts

1. Inspect `EnableSoundAlert`, `EnablePushNotification`, and `SendOptionalAlert()`.
2. Keep alert behavior opt-in unless a human explicitly approves a default change.
3. Ensure alert text remains non-advisory and concise.
4. Compile.
5. Test in a demo/local terminal with notifications deliberately configured.

Caution: push notifications can leave the local chart context.

## Playbook: Change historical validation/autotune

1. Inspect `RunHistoricalOperatingMode()` and `RunHistoricalBacktest()`.
2. For scoring changes, inspect `BuildHistoricalSignalScore()` and keep it aligned with live scoring intent where appropriate.
3. For autotune candidates, inspect `BuildAutotuneCandidate()`, `AutotuneObjective()`, and `ApplyAutotuneParamsToRuntime()`.
4. Compile.
5. Run `FXNEWS_MODE_VALIDATION` and/or `FXNEWS_MODE_AUTOTUNE`.
6. Inspect MT5 Journal report lines.

Caution: historical results depend on broker/terminal M1 history quality and availability.

## Playbook: Add automated tests or tooling

1. Do not assume a current harness exists.
2. Decide whether the tooling can run outside MT5 or requires MetaEditor/terminal access.
3. Add clear commands to `.ai/COMMANDS.md` and `.ai/TESTING.md`.
4. Add CI only if the environment can legally/safely compile MQL5.
5. Keep generated MT5 artifacts ignored.

Caution: avoid adding brittle automation that depends on a local terminal path without documentation.

## Playbook: Refresh AI onboarding docs

1. Read `.ai/MANIFEST.json` and previous indexed commit if available.
2. Compare changed source/docs since that commit.
3. Update facts in `AI_INDEX.md`, `AGENTS.md`, and relevant `.ai/*` files.
4. Preserve valid human edits.
5. Keep docs vendor-neutral.
6. Validate manifest JSON and links.
7. Confirm no model-specific files were created.

Caution: onboarding docs must follow current source, not stale generated content.
