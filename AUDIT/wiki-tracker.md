## Pre-production audit (2026-09-15)

Independent pre-production audit of the whole repository, run on branch `audit/2026-09-15` from base commit `71ce980`, and merged by pull request only after the final phase passed. The authoritative ledger lives in the repository at `AUDIT/ledger.md` / `AUDIT/ledger.json`; this page mirrors it and the ledger wins on any conflict.

**total 47 | done 8 | open 39 | blocked 0 | S0:1 S1:9 S2:17 S3:20**

### Open items

| # | Sev | Status | Area | What |
| --- | --- | --- | --- | --- |
| F-001 | S1 | START | scoring | Breakout hold_score is imputed at 0 with a full 0.20 weight when the price is not outside the box, instead of leaving the normaliser |
| F-003 | S1 | START | scoring | movement_5m_pips falls back to a 0.0 sentinel when the M1 copy fails and is then consumed as a measured value by three components |
| F-006 | S1 | START | historical | Two composite caps are structurally inert in history, so historical scores are systematically less penalised than live scores |
| F-007 | S1 | START | tests | The availability-and-composer self-test assertion cannot detect an exclusion regression |
| F-008 | S1 | START | tests | The live signal lifecycle, correlation grouping, alert dispatch and dashboard rendering have no automated coverage |
| F-010 | S2 | START | historical | The 85+ bucket in the historical report is unreachable dead code |
| F-011 | S2 | START | dashboard | g_signal_history_dirty is never cleared while active signal rows are rendered, forcing a full dashboard rebuild every scan |
| F-012 | S2 | START | scoring | wick_rejection_penalty is subtracted from the breakout blend without its weight being added to the normaliser |
| F-013 | S2 | START | dashboard | DominantCurrencyFlow's own_group key makes every timeframe of one symbol share a correlation group, so at most one of them can ever alert |
| F-014 | S2 | START | tooling | The Wine path, WINEPREFIX and MT5 path constants are duplicated across the two gate scripts and can drift |
| F-015 | S2 | START | tooling | The indicator, the harness and the gate script are coupled by undocumented string literals with no contract test |
| F-016 | S2 | START | ops | No CI workflow: the three release gates are never run automatically |
| F-017 | S2 | START | validation | MaxQuoteAgeSeconds and FullHoldScoreSeconds have no upper bound, so extreme values silently disable the freshness gate or make the HYBRID hold clause unreachable |
| F-018 | S2 | START | scoring | single_feature_cap is applied without checking that the feature it measures was evaluated |
| F-019 | S2 | START | scoring | The +0.05 synergy bonus is awarded on component scores without checking that either engine passed or was measured |
| F-020 | S2 | START | scoring | RobustZ returns 0 for degenerate dispersion while the caller still reports the z as available |
| F-021 | S2 | START | dashboard | WrapLabelText wraps report lines at 63 characters but SetDashboardRow re-clips them to the measured pixel limit, truncating the wrapped tail |
| F-022 | S2 | START | dashboard | UpdateActivityStatusLine recomputes CountDashboardObjects (up to 40 ObjectFind calls) on every scan that skips the full dashboard |
| F-023 | S2 | START | tests | No test exercises any ValidateInputs rejection path |
| F-024 | S2 | START | tooling | build-macos.sh cannot distinguish 'Wine cannot execute' from 'the compiler produced no result line', and reports the wrong exit code |
| F-025 | S2 | START | ops | A live-looking GitHub PAT was supplied in plaintext and is present in the agent session transcript |
| F-026 | S3 | START | tooling | ruff F541: two f-strings without placeholders |
| F-027 | S3 | START | tooling | ruff format drift: the only Python file is not formatted to the formatter's standard |
| F-028 | S3 | START | tooling | shfmt drift in both shell scripts |
| F-029 | S3 | START | tooling | tools/census-allow.txt is documented and defaulted to but does not exist |
| F-030 | S3 | START | tooling | .coverage is not ignored, so the coverage artifact required by the audit brief can be committed by accident |
| F-031 | S3 | START | repo | One contributor appears under three different author identities |
| F-034 | S3 | START | docs | Known-Limitations calls all three gates macOS-only, but census.py is cross-platform |
| F-035 | S3 | START | docs | Development-Guide both denies and documents the release process, and lists 'test' among commands that do not exist |
| F-036 | S3 | START | docs | The tracker describes itself as open tasks and known bugs while showing 120/120 done, and its line-number baseline still says version 2.3 |
| F-037 | S3 | START | docs | The documented version-bump procedure requires a deployment clone at MQL5/Indicators/FXNews/ that does not exist on this machine |
| F-038 | S3 | START | scoring | Unreachable guard: total_weight can never be zero |
| F-039 | S3 | START | docs | The age_free_score field comment understates what the value excludes |
| F-040 | S3 | START | logic | The hard 95 ceiling is the only cap that records no reason string |
| F-041 | S3 | START | logic | Redundant threshold re-check in IsConfirmedSignal for CONFIRM_BAR_CLOSE |
| F-042 | S3 | START | dashboard | PushSignalHistory's shift loop copies empty slots when the list is not yet full |
| F-043 | S3 | START | logic | SmoothStep silently re-orients reversed edges instead of surfacing a configuration error |
| F-044 | S3 | START | docs | The ATR definition (simple mean of true range, not Wilder smoothing) is undocumented |
| F-045 | S3 | START | tooling | --install creates the destination directory silently and never verifies the terminal can load the binary |

### Blocked items

_None._

### Completed audit tasks

| # | Sev | Area | What | Evidence |
| --- | --- | --- | --- | --- |
| E-1 | S0 | tooling | Build and self-test gates cannot execute: bundled wine64 is x86_64 and Rosetta 2 was absent on all four Macs | Rosetta install finished successfully; arch -x86_64 /usr/bin/true OK; wine64 --version -> wine-9.14; ./tools/build-macos.sh -> 0 errors, 0 warnings, exit 0; ./tools/selftest-macos.sh -> 117 passed, 0 failed |
| E-2 | S1 | tooling | No MQL5 formatter, linter, static analyzer, SAST scanner or coverage tool exists | AUDIT/environment.md section 2 records the gap and the compensating controls |
| F-002 | S1 | scoring | UpdateSessionBaseline folds active_trigger_tick_volume into the tick-volume baseline unguarded, while the adjacent line explicitly guards the tick rate | New self-test group 'session baselines'. BEFORE (temporary restore of shared-counter readiness): 'session baseline: a single rate sample is not yet a baseline' FAILED; RESULT 122 passed, 1 failed of 123 assertions; selftest exit 1. AFTER: RESULT 123 passed, 0 failed of 123; exit 0. Build 0 errors/0 warnings; census 0 findings; shellcheck clean; ruff/mypy --strict/bandit clean. |
| F-004 | S1 | historical | Historical impulse evaluation forces acceleration_available and continuation_available to true, hard-coding weights for inputs that may be unmeasurable | New self-test group 'impulse availability'. BEFORE (forced flags restored): 1 assertion FAILED - 'impulse blend: unavailable terms leave the normaliser (got 0.600000, expected 1.000000)'; RESULT 129 passed, 1 failed of 130; exit 1. AFTER: RESULT 130 passed, 0 failed of 130; exit 0. Build 0/0; census 0 findings; shellcheck clean. |
| F-005 | S1 | historical | Historical execution gate applies cost_to_atr unconditionally, so VALIDATION/AUTOTUNE do not reproduce the live filter set when UseStrictExecutionGate is off | New self-test group 'execution gate'. BEFORE (unconditional ceiling restored): 2 assertions FAILED ('a high cost-to-ATR passes when the strict gate is off', 'the spread-z ceiling is strict-gated as well'); RESULT 126 passed, 2 failed of 128; exit 1. AFTER: RESULT 128 passed, 0 failed of 128; exit 0. Build 0/0; census 0 findings. |
| F-009 | S2 | scoring | session_baseline_ready is a single flag for three independent baselines, so a z-score can be reported as measured when its own baseline never received samples | New self-test group 'session baselines'. BEFORE (temporary restore of shared-counter readiness): 'session baseline: a single rate sample is not yet a baseline' FAILED; RESULT 122 passed, 1 failed of 123 assertions; selftest exit 1. AFTER: RESULT 123 passed, 0 failed of 123; exit 0. Build 0 errors/0 warnings; census 0 findings; shellcheck clean; ruff/mypy --strict/bandit clean. |
| F-032 | S3 | docs | The gate script's header comment states the wrong assertion count (72; actual 117) | grep -rnE '[0-9]+ (pure-helper )?assertions' README.md CLAUDE.md tools/ returns no match; the gate still reports its total at runtime ('RESULT: 130 passed, 0 failed of 130 assertions'). |
| F-033 | S3 | docs | The wiki Testing page hard-codes the assertion total on the same page that promises it never has to | Wiki commit 'docs: stop hard-coding the self-test assertion total'; Testing-and-Validation.md:11 and Architecture.md:49 reworded. |
