# FXNews audit — finding enumeration (Phase B)

Generated from `AUDIT/ledger.json` by `AUDIT/render.py` — do not edit by hand.
Branch `audit/2026-09-15`, base commit `71ce980`.

**total 47 | done 10 | open 37 | blocked 0 | S0:1 S1:8 S2:18 S3:20**

Severity follows the audit brief §7. Work order: all S0, then S1, S2, S3.

| id | sev | area | status | file:line | title |
| --- | --- | --- | --- | --- | --- |
| E-1 | S0 | tooling | DONE | `tools/build-macos.sh:40` | Build and self-test gates cannot execute: bundled wine64 is x86_64 and Rosetta 2 was absent on all four Macs |
| E-2 | S1 | tooling | DONE | `tools/selftest-macos.sh:34` | No MQL5 formatter, linter, static analyzer, SAST scanner or coverage tool exists |
| F-002 | S1 | scoring | DONE | `FXNews.mq5:4502` | UpdateSessionBaseline folds active_trigger_tick_volume into the tick-volume baseline unguarded, while the adjacent line explicitly guards the tick rate |
| F-003 | S1 | scoring | START | `FXNews.mq5:4268,4704,5418,5917` | movement_5m_pips falls back to a 0.0 sentinel when the M1 copy fails and is then consumed as a measured value by three components |
| F-004 | S1 | historical | DONE | `FXNews.mq5:2728` | Historical impulse evaluation forces acceleration_available and continuation_available to true, hard-coding weights for inputs that may be unmeasurable |
| F-005 | S1 | historical | DONE | `FXNews.mq5:2667` | Historical execution gate applies cost_to_atr unconditionally, so VALIDATION/AUTOTUNE do not reproduce the live filter set when UseStrictExecutionGate is off |
| F-006 | S1 | historical | START | `FXNews.mq5:2693,5310-5318,4984-4989` | Two composite caps are structurally inert in history, so historical scores are systematically less penalised than live scores |
| F-007 | S1 | tests | DONE | `FXNews.mq5:1455-1459` | The availability-and-composer self-test assertion cannot detect an exclusion regression |
| F-008 | S1 | tests | START | `README.md:50; FXNews.mq5` | The live signal lifecycle, correlation grouping, alert dispatch and dashboard rendering have no automated coverage |
| F-001 | S2 | scoring | DONE | `FXNews.mq5:5222,5310,5324` | ComputeBreakoutStructure did not initialise its own output, so the documented pure shared function returned garbage to a direct caller (originally filed as a hold_score imputation) |
| F-009 | S2 | scoring | DONE | `FXNews.mq5:4476-4477,7956-7957` | session_baseline_ready is a single flag for three independent baselines, so a z-score can be reported as measured when its own baseline never received samples |
| F-010 | S2 | historical | START | `FXNews.mq5:2926-2930,3039` | The 85+ bucket in the historical report is unreachable dead code |
| F-011 | S2 | dashboard | START | `FXNews.mq5:3788,6802-6804,7182` | g_signal_history_dirty is never cleared while active signal rows are rendered, forcing a full dashboard rebuild every scan |
| F-012 | S2 | scoring | START | `FXNews.mq5:5330-5331` | wick_rejection_penalty is subtracted from the breakout blend without its weight being added to the normaliser |
| F-013 | S2 | dashboard | START | `FXNews.mq5:6325,6246` | DominantCurrencyFlow's own_group key makes every timeframe of one symbol share a correlation group, so at most one of them can ever alert |
| F-014 | S2 | tooling | START | `tools/build-macos.sh:40-43; tools/selftest-macos.sh:38-40` | The Wine path, WINEPREFIX and MT5 path constants are duplicated across the two gate scripts and can drift |
| F-015 | S2 | tooling | START | `FXNews.mq5:1725; tools/mql5/FXNewsSelfTest.mq5:14,32-34; tools/selftest-macos.sh:72,139,159-163` | The indicator, the harness and the gate script are coupled by undocumented string literals with no contract test |
| F-016 | S2 | ops | START | `.github/` | No CI workflow: the three release gates are never run automatically |
| F-017 | S2 | validation | START | `FXNews.mq5:942,988-995` | MaxQuoteAgeSeconds and FullHoldScoreSeconds have no upper bound, so extreme values silently disable the freshness gate or make the HYBRID hold clause unreachable |
| F-018 | S2 | scoring | START | `FXNews.mq5:5026-5031` | single_feature_cap is applied without checking that the feature it measures was evaluated |
| F-019 | S2 | scoring | START | `FXNews.mq5:4958-4959` | The +0.05 synergy bonus is awarded on component scores without checking that either engine passed or was measured |
| F-020 | S2 | scoring | START | `FXNews.mq5:8266-8270,4661,5114-5116` | RobustZ returns 0 for degenerate dispersion while the caller still reports the z as available |
| F-021 | S2 | dashboard | START | `FXNews.mq5:7482,7419` | WrapLabelText wraps report lines at 63 characters but SetDashboardRow re-clips them to the measured pixel limit, truncating the wrapped tail |
| F-022 | S2 | dashboard | START | `FXNews.mq5:6817-6825,6747` | UpdateActivityStatusLine recomputes CountDashboardObjects (up to 40 ObjectFind calls) on every scan that skips the full dashboard |
| F-023 | S2 | tests | START | `FXNews.mq5:930-1109` | No test exercises any ValidateInputs rejection path |
| F-024 | S2 | tooling | START | `tools/build-macos.sh:47,116-120` | build-macos.sh cannot distinguish 'Wine cannot execute' from 'the compiler produced no result line', and reports the wrong exit code |
| F-025 | S2 | ops | START | `session credential handling` | A live-looking GitHub PAT was supplied in plaintext and is present in the agent session transcript |
| F-026 | S3 | tooling | START | `tools/census.py:273,274` | ruff F541: two f-strings without placeholders |
| F-027 | S3 | tooling | START | `tools/census.py` | ruff format drift: the only Python file is not formatted to the formatter's standard |
| F-028 | S3 | tooling | START | `tools/build-macos.sh; tools/selftest-macos.sh` | shfmt drift in both shell scripts |
| F-029 | S3 | tooling | START | `tools/census.py:17,338` | tools/census-allow.txt is documented and defaulted to but does not exist |
| F-030 | S3 | tooling | START | `.gitignore` | .coverage is not ignored, so the coverage artifact required by the audit brief can be committed by accident |
| F-031 | S3 | repo | START | `git history` | One contributor appears under three different author identities |
| F-032 | S3 | docs | DONE | `tools/selftest-macos.sh:13` | The gate script's header comment states the wrong assertion count (72; actual 117) |
| F-033 | S3 | docs | DONE | `_fxnews-wiki/Testing-and-Validation.md:11,30` | The wiki Testing page hard-codes the assertion total on the same page that promises it never has to |
| F-034 | S3 | docs | START | `_fxnews-wiki/Known-Limitations.md:7` | Known-Limitations calls all three gates macOS-only, but census.py is cross-platform |
| F-035 | S3 | docs | START | `_fxnews-wiki/Development-Guide.md:23` | Development-Guide both denies and documents the release process, and lists 'test' among commands that do not exist |
| F-036 | S3 | docs | START | `_fxnews-wiki/Project-Tracker.md:3,7,9` | The tracker describes itself as open tasks and known bugs while showing 120/120 done, and its line-number baseline still says version 2.3 |
| F-037 | S3 | docs | START | `CLAUDE.md:24-30` | The documented version-bump procedure requires a deployment clone at MQL5/Indicators/FXNews/ that does not exist on this machine |
| F-038 | S3 | scoring | START | `FXNews.mq5:4948-4949` | Unreachable guard: total_weight can never be zero |
| F-039 | S3 | docs | START | `FXNews.mq5:396,5012-5041` | The age_free_score field comment understates what the value excludes |
| F-040 | S3 | logic | START | `FXNews.mq5:5044-5045` | The hard 95 ceiling is the only cap that records no reason string |
| F-041 | S3 | logic | START | `FXNews.mq5:6187,6410` | Redundant threshold re-check in IsConfirmedSignal for CONFIRM_BAR_CLOSE |
| F-042 | S3 | dashboard | START | `FXNews.mq5:7261-7262` | PushSignalHistory's shift loop copies empty slots when the list is not yet full |
| F-043 | S3 | logic | START | `FXNews.mq5:8198-8208` | SmoothStep silently re-orients reversed edges instead of surfacing a configuration error |
| F-044 | S3 | docs | START | `FXNews.mq5:4401-4425` | The ATR definition (simple mean of true range, not Wilder smoothing) is undocumented |
| F-045 | S3 | tooling | START | `tools/build-macos.sh:150-156` | --install creates the destination directory silently and never verifies the terminal can load the binary |

## Detail

### E-1 (S0, tooling) — Build and self-test gates cannot execute: bundled wine64 is x86_64 and Rosetta 2 was absent on all four Macs

- **Status:** DONE  |  **Category:** deps  |  **Host:** node3  |  **Commit:** f439c3f
- **Location:** `tools/build-macos.sh:40`
- **Discovered by:** Phase A environment probe
- **Evidence (before):**

  > arch -x86_64 /usr/bin/true -> 'Bad CPU type in executable' on node1..node4; file wine64 -> 'Mach-O 64-bit executable x86_64'; build-macos.sh exited 3 ('MetaEditor wrote no log') instead of 2

- **Fix:** Installed Rosetta 2 on node3: sudo softwareupdate --install-rosetta --agree-to-license
- **Evidence (after):** Rosetta install finished successfully; arch -x86_64 /usr/bin/true OK; wine64 --version -> wine-9.14; ./tools/build-macos.sh -> 0 errors, 0 warnings, exit 0; ./tools/selftest-macos.sh -> 117 passed, 0 failed
- **Notes:** Environment remediation, not a source change. The repo-side defect is F-024.

### E-2 (S1, tooling) — No MQL5 formatter, linter, static analyzer, SAST scanner or coverage tool exists

- **Status:** DONE  |  **Category:** deps  |  **Host:** node3  |  **Commit:** f439c3f
- **Location:** `tools/selftest-macos.sh:34`
- **Discovered by:** Phase A toolchain probe
- **Evidence (before):**

  > No MQL5 tooling in Homebrew, pip or the system toolchain; MQL5 has no public parser

- **Fix:** Documented as a tooling gap with compensating controls: MetaEditor compiler as the only analyzer, tools/census.py for dead-code/placeholder coverage, manual evidence-based L4/L5 review for every finding
- **Evidence (after):** AUDIT/environment.md section 2 records the gap and the compensating controls
- **Notes:** Not BLOCKED: a real substitute exists and was used.

### F-002 (S1, scoring) — UpdateSessionBaseline folds active_trigger_tick_volume into the tick-volume baseline unguarded, while the adjacent line explicitly guards the tick rate

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 2388b22
- **Location:** `FXNews.mq5:4502`
- **Discovered by:** Phase B L2 + scoring audit
- **Evidence (before):**

  > ':4499-4501' comments 'An unmeasured tick rate must not be folded into the baseline as zero' and guards it with tick_rate_known; ':4502' folds tick_volume unconditionally. active_trigger_tick_volume is only assigned when has_trigger (:4237) and is not reset on the failure branch (:4240-4248), so a profile with no trigger-timeframe data folds either a stale value or the initial 0 into the baseline. The baseline feeds session_tick_volume_z, which TickVolumeDeviation consumes (:7969-7972) as a measured reading into the impulse blend and unsupported_impulse_cap.

- **Fix:** SessionBaseline now carries spread_samples / tick_rate_samples / tick_volume_samples instead of one shared sample_count, and SymbolProfile carries session_spread_z_ready / session_tick_rate_z_ready / session_tick_volume_z_ready instead of one session_baseline_ready. Each series' EWMA uses its own counter and each counter advances only when that series was actually folded; a z-score is published only when its own series is ready. All reset paths and all three consumers updated.
- **Evidence (after):** New self-test group 'session baselines'. BEFORE (temporary restore of shared-counter readiness): 'session baseline: a single rate sample is not yet a baseline' FAILED; RESULT 122 passed, 1 failed of 123 assertions; selftest exit 1. AFTER: RESULT 123 passed, 0 failed of 123; exit 0. Build 0 errors/0 warnings; census 0 findings; shellcheck clean; ruff/mypy --strict/bandit clean.
- **Notes:** Found independently by this audit and by the scoring audit; also not carried across the sibling-context path (:4252-4257 vs CopyContextRatesData :4353-4363). Fixed together with F-009: one root cause, one change.

### F-003 (S1, scoring) — movement_5m_pips falls back to a 0.0 sentinel when the M1 copy fails and is then consumed as a measured value by three components

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:4268,4704,5418,5917`
- **Discovered by:** Phase B L3
- **Evidence (before):**

  > ':4268' sets movement_5m_pips = 0.0 when copied_m1 <= 5; there is no availability flag. It is consumed at ':4704' (currency-strength five-minute normaliser n5m), ':5418' (impulse exhaustion_penalty) and ':5917' (basket-agreement pair_move). A zero reads as 'no move', which suppresses exhaustion and biases both the flow and agreement terms.

- **Notes:** Same class as the tracker's closed tasks 21-29 (exclude-don't-impute); this instance was missed.

### F-004 (S1, historical) — Historical impulse evaluation forces acceleration_available and continuation_available to true, hard-coding weights for inputs that may be unmeasurable

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 2e8430c
- **Location:** `FXNews.mq5:2728`
- **Discovered by:** Phase B L2 + historical audit
- **Evidence (before):**

  > ':2728' calls BlendImpulseScore(..., true, true, continuation) unconditionally, while the live path computes genuine flags at ':5393' (SnapshotWindowCovered) and ':5415' (ContinuationScore out-param). acceleration_up is 0.0 when index5<0||index30<0 (:2629-2630) and move5_atr_up is 0.0 when index5<0 (:2628), so a neutral 0.0 enters both the numerator and the normaliser with 0.30 of weight (:5445-5459).

- **Fix:** HistoricalBoundaryFeatures carries acceleration_available and continuation_available derived from whether the 5- and 30-minute lookups resolved; the call site passes them instead of the hard-coded true/true, so an unavailable term leaves the blend and the normaliser.
- **Evidence (after):** New self-test group 'impulse availability'. BEFORE (forced flags restored): 1 assertion FAILED - 'impulse blend: unavailable terms leave the normaliser (got 0.600000, expected 1.000000)'; RESULT 129 passed, 1 failed of 130; exit 1. AFTER: RESULT 130 passed, 0 failed of 130; exit 0. Build 0/0; census 0 findings; shellcheck clean.
- **Notes:** Breaches the exclude-don't-impute invariant in the validator/autotune path, whose output is used to advise settings.

### F-005 (S1, historical) — Historical execution gate applies cost_to_atr unconditionally, so VALIDATION/AUTOTUNE do not reproduce the live filter set when UseStrictExecutionGate is off

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 57abd8c
- **Location:** `FXNews.mq5:2667`
- **Discovered by:** Phase B L2 + historical audit
- **Evidence (before):**

  > ':2667' includes 'features.cost_to_atr > params.max_spread_to_atr' in the unconditional rejection condition, whereas the live gate applies cost_to_atr only inside 'if(UseStrictExecutionGate)' (:5159-5173). With strict off, history rejects boundaries the live scanner accepts.

- **Fix:** Extracted ExecutionSpreadBlock(execution, max_spread_to_atr, strict) as one pure predicate covering the spread, cost-to-ATR and spread-z ceilings, and called it from both the live EvaluateExecutionQuality and the historical ScoreHistoricalBoundary. This removes the duplicated gate and the drift: the validator now honours UseStrictExecutionGate exactly as the live path does.
- **Evidence (after):** New self-test group 'execution gate'. BEFORE (unconditional ceiling restored): 2 assertions FAILED ('a high cost-to-ATR passes when the strict gate is off', 'the spread-z ceiling is strict-gated as well'); RESULT 126 passed, 2 failed of 128; exit 1. AFTER: RESULT 128 passed, 0 failed of 128; exit 0. Build 0/0; census 0 findings.

### F-006 (S1, historical) — Two composite caps are structurally inert in history, so historical scores are systematically less penalised than live scores

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:2693,5310-5318,4984-4989`
- **Discovered by:** Phase B L2 + historical audit
- **Evidence (before):**

  > ':2693' always passes outside_seconds=60.0 when distance>0 (hold_score saturates to 1.0 against FullHoldScoreSeconds=12) and reentered_seconds=-1.0 (fakeout_penalty stays 0.0). Consequently weak_hold_cap (:4984) and range_snapback_cap (:4988) can never bind in a historical run, while they do bind live. Re-entry is genuinely untrackable in history (documented at :2685-2687), but the consequence for the reported score distribution is not documented.

- **Notes:** Affects the fidelity of the report that Autotune ranks candidates on.

### F-007 (S1, tests) — The availability-and-composer self-test assertion cannot detect an exclusion regression

- **Status:** DONE  |  **Category:** test  |  **Host:** node3  |  **Commit:** eb29ef7
- **Location:** `FXNews.mq5:1455-1459`
- **Discovered by:** Phase B L6 + scoring audit
- **Evidence (before):**

  > With the weights in force (0.76 total when flow and calendar are absent), excluding an unmeasured component and imputing 0 for it both produce a displayed score of 84 because flow_absent_cap binds first, so the assertion passes under either implementation. This is the exact class of defect the self-test exists to catch (CLAUDE.md:44-48).

- **Fix:** The composer exclusion assertion now drives every measured component at equal quality and asserts on raw_score, taken before the cap ladder, so exclusion (uniform average unchanged) is numerically distinct from imputation (dragged down by the excluded weight's share). Flow is the component under test so the breakout/impulse synergy term cancels.
- **Evidence (after):** BEFORE (imputing weight restored): the new assertion FAILED - 'leaves the blend unchanged when a component is unmeasured (got 27.257710, expected 53.943724)'; RESULT 129 passed, 2 failed of 131; exit 1. AFTER: RESULT 131 passed, 0 failed of 131; exit 0. Build 0/0; census 0 findings; shellcheck clean.
- **Notes:** Must be strengthened with an assertion that distinguishes exclusion from imputation, e.g. on raw_score or on the normaliser directly. Refined by experiment: the pre-existing assertion did react to a flow imputation (because a second component had shifted), but is blind to an impulse imputation, which is the case the scoring audit analysed. The new assertion distinguishes imputation directly on raw_score rather than depending on a cap binding.

### F-008 (S1, tests) — The live signal lifecycle, correlation grouping, alert dispatch and dashboard rendering have no automated coverage

- **Status:** START  |  **Category:** test  |  **Host:** node3  |  **Commit:** -
- **Location:** `README.md:50; FXNews.mq5`
- **Discovered by:** Phase B L6; already disclosed in Known-Limitations.md:8 and CLAUDE.md:52-54
- **Evidence (before):**

  > Known-Limitations.md:8 and CLAUDE.md:52-54 state these areas are verified only by manual runtime observation. Several of the audit's behaviour findings (F-011, F-013, F-018) live exactly in that uncovered region, which is why they survived the 3.0 audit.

- **Notes:** Disclosed honestly by the project, but the audit brief treats a missing critical test as S1. Scope: at minimum a deterministic lifecycle state-machine test driven from synthetic scores.

### F-001 (S2, scoring) — ComputeBreakoutStructure did not initialise its own output, so the documented pure shared function returned garbage to a direct caller (originally filed as a hold_score imputation)

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** e3c87f6
- **Location:** `FXNews.mq5:5222,5310,5324`
- **Discovered by:** Phase B L2/L3 + scoring audit
- **Evidence (before):**

  > EvaluateBreakoutStructure resets hold_score=0.0 at :5222; outside_seconds is -1.0 when the price is not outside (:5237); ComputeBreakoutStructure assigns hold_score only inside 'if(outside_seconds >= 0.0)' (:5310); the blend nevertheless always puts hold_score*0.20 in the numerator and 0.20 in total_weight (:5324-5325). A profile whose impulse engine passes while the breakout is measured-but-not-outside therefore carries a worst-case zero for an unmeasured term. This contradicts CLAUDE.md:75-86 ('A component that could not be measured is excluded ... This applies inside every component too').

- **Fix:** ComputeBreakoutStructure now initialises all eleven output fields from its own arguments, making it genuinely pure; hold_score is assigned as one explicit either/or instead of a guarded write.
- **Evidence (after):** New self-test group 'breakout hold'. BEFORE (caller-dependent form restored): 2 assertions FAILED ('an unbroken box is measured, not passing, zero hold', 'weights a sustained hold above a zero hold'); RESULT 131 passed, 2 failed of 133; exit 1. AFTER: RESULT 133 passed, 0 failed of 133; exit 0. Build 0/0; census 0 findings.
- **Notes:** SCOPE NOTE, recorded on the original finding rather than by narrowing it. The filed S1 reading (hold_score imputed at 0 instead of excluded) was REJECTED by reachability analysis: atr_trigger > 0 implies has_trigger, so UpdateOutsideTimers has already classified inside/outside, and a negative outside_seconds is a genuine measurement of zero hold. Weighting it is intended, so the invariant is not violated and severity drops to S2. Writing the characterisation test for that intended behaviour exposed a different real defect at the same site - the uninitialised output - which is what this task now fixes. Both facts are recorded; nothing was dropped.

### F-009 (S2, scoring) — session_baseline_ready is a single flag for three independent baselines, so a z-score can be reported as measured when its own baseline never received samples

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 2388b22
- **Location:** `FXNews.mq5:4476-4477,7956-7957`
- **Discovered by:** Phase B L2 + scoring audit
- **Evidence (before):**

  > 'sample_count' is incremented unconditionally (:4503-4504) regardless of which series was folded (spread always :4498, tick volume always :4502, tick rate only when known :4500-4501). readiness is then derived from that one counter (:4476-4477) and gates all three z-scores (:7956-7957, :7969-7972). After 50 spread samples with no tick-rate sample, session_tick_rate_z is computed from mean=0,var=0 and BaselineZ returns 0.0 (:4527-4532), which TickRateZ reports as available.

- **Fix:** SessionBaseline now carries spread_samples / tick_rate_samples / tick_volume_samples instead of one shared sample_count, and SymbolProfile carries session_spread_z_ready / session_tick_rate_z_ready / session_tick_volume_z_ready instead of one session_baseline_ready. Each series' EWMA uses its own counter and each counter advances only when that series was actually folded; a z-score is published only when its own series is ready. All reset paths and all three consumers updated.
- **Evidence (after):** New self-test group 'session baselines'. BEFORE (temporary restore of shared-counter readiness): 'session baseline: a single rate sample is not yet a baseline' FAILED; RESULT 122 passed, 1 failed of 123 assertions; selftest exit 1. AFTER: RESULT 123 passed, 0 failed of 123; exit 0. Build 0 errors/0 warnings; census 0 findings; shellcheck clean; ruff/mypy --strict/bandit clean.
- **Notes:** Shares one root cause with F-002 and is fixed by the same change, committed once under audit(F-002,F-009).

### F-010 (S2, historical) — The 85+ bucket in the historical report is unreachable dead code

- **Status:** START  |  **Category:** dead  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:2926-2930,3039`
- **Discovered by:** Phase B L1 + historical audit
- **Evidence (before):**

  > Flow is never populated in a historical run, so ComposeSignalScore always applies flow_absent_cap at 84.0 (:4969-4972); ScoreBucketFloor can therefore never return 85 for a historical score, AddHistoricalBucketStats never increments bucket85_count (:2926-2930), and the report row (:3039) always prints zero.

- **Notes:** Either remove the bucket from the report or state the 84 ceiling explicitly next to it.

### F-011 (S2, dashboard) — g_signal_history_dirty is never cleared while active signal rows are rendered, forcing a full dashboard rebuild every scan

- **Status:** START  |  **Category:** perf  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:3788,6802-6804,7182`
- **Discovered by:** Phase B L5 + dashboard audit
- **Evidence (before):**

  > The flag is set at ':7240' and ':7265' and cleared only in RefreshVisibleSignalHistory (:7182), which is reachable only through RefreshVisibleSignalHistoryIfDue (:7135-7145) from the 'if(row == first_row)' branch of UpdateDashboard (:6802-6804). With ShowActiveSignalRows=true and at least one ranked row, that branch is skipped, the flag stays true, and ScanAll's condition at ':3788' forces UpdateDashboard every scan, defeating DisplayUpdateSeconds. Verified by grepping every write site of the flag.

- **Notes:** The default ShowActiveSignalRows=false masks it.

### F-012 (S2, scoring) — wick_rejection_penalty is subtracted from the breakout blend without its weight being added to the normaliser

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:5330-5331`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':5330' subtracts wick_rejection_penalty*0.15 from 'weighted' but ':5331' adds only 0.17+0.17 to total_weight; the 0.15 never enters the denominator, so the penalty acts at an effective 0.15/0.95 weight outside the normaliser.

- **Notes:** May be intentional (penalties are not weight-normalised) but is undocumented; decide and document.

### F-013 (S2, dashboard) — DominantCurrencyFlow's own_group key makes every timeframe of one symbol share a correlation group, so at most one of them can ever alert

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:6325,6246`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > The comment at ':6318-6320' says a signal with no basket reading 'groups only with itself', but own_group is symbol + '_' + direction (:6325), which is identical across the timeframes of that symbol. CanDispatchAlert (:6246) admits only the group leader, so the remaining same-symbol timeframes stay pending for the life of the signal (:6642-6646).

- **Notes:** Grouping is in the manually-verified region (F-008). Confirm intended behaviour before changing; the comment at minimum is wrong.

### F-014 (S2, tooling) — The Wine path, WINEPREFIX and MT5 path constants are duplicated across the two gate scripts and can drift

- **Status:** START  |  **Category:** dead  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/build-macos.sh:40-43; tools/selftest-macos.sh:38-40`
- **Discovered by:** Phase B L1
- **Evidence (before):**

  > Both scripts independently hard-code '/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64' and the same WINEPREFIX; the MT5 sub-path is repeated in build-macos.sh:42 and selftest-macos.sh:39-40. Extracting them into one sourced file is the standard fix.


### F-015 (S2, tooling) — The indicator, the harness and the gate script are coupled by undocumented string literals with no contract test

- **Status:** START  |  **Category:** unsafe  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:1725; tools/mql5/FXNewsSelfTest.mq5:14,32-34; tools/selftest-macos.sh:72,139,159-163`
- **Discovered by:** Phase B L1
- **Evidence (before):**

  > Four implicit contracts: the verdict labels 'SELFTEST PASSED'/'VALIDATION ready'/'AUTOTUNE ready'/'ABORTED'; the result line 'RESULT: N passed, M failed'; the harness indicator path 'FXNews-selftest\FXNews'; and the install directory. Rewording a label in the indicator silently turns the gate into a timeout failure with no indication of the cause.

- **Notes:** Fix is a contract test that asserts the literals agree across all three files, so a rename fails loudly at the gate instead of timing out.

### F-016 (S2, ops) — No CI workflow: the three release gates are never run automatically

- **Status:** START  |  **Category:** deps  |  **Host:** node3  |  **Commit:** -
- **Location:** `.github/`
- **Discovered by:** Phase B L0/L7
- **Evidence (before):**

  > .github contains only traffic.json; there is no workflow. Known-Limitations.md:7 lists this. The MQL5 compile gate cannot run on a stock GitHub runner, but census.py, shellcheck, ruff, mypy, the secret scan and the new contract test all can, and they are exactly the gates that catch the classes of defect this audit found.

- **Notes:** Scope the workflow to the Linux-runnable gates and state explicitly in the README that the compile and self-test gates remain manual.

### F-017 (S2, validation) — MaxQuoteAgeSeconds and FullHoldScoreSeconds have no upper bound, so extreme values silently disable the freshness gate or make the HYBRID hold clause unreachable

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:942,988-995`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > ValidateInputs checks only MaxQuoteAgeSeconds >= 1 (:942) and FullHoldScoreSeconds >= MinHoldSecondsForHighScore (:988-995). A very large MaxQuoteAgeSeconds disables quote-freshness enforcement (:4116, :5201); a very large FullHoldScoreSeconds drives hold_score below the 0.35 HYBRID clause (:6196) while weak_hold_cap (:4984) penalises every profile.

- **Notes:** Every other numeric input in this file has both bounds; these two are the outliers.

### F-018 (S2, scoring) — single_feature_cap is applied without checking that the feature it measures was evaluated

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:5026-5031`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':5026-5031' caps at 79 when execution.score < 0.78 or max(breakout.score, impulse.score) < 0.60, with no gate on the engine being enabled or the component being measured, while the very next cap block (:5033-5035) is explicitly gated and comments on that reasoning. With UseTechnicalBreakoutEngine=false and impulse unmeasured, an unmeasured 0 caps a strong score.


### F-019 (S2, scoring) — The +0.05 synergy bonus is awarded on component scores without checking that either engine passed or was measured

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:4958-4959`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':4958-4959' adds 0.05 to raw01 when breakout.score >= 0.45 and impulse.score >= 0.45. Nothing guarantees those scores came from measured components; the zeroing in ResetCompositeSignalScore makes values from a previous evaluation sticky only for measured paths, so the interaction with F-001/F-018 is a real risk.


### F-020 (S2, scoring) — RobustZ returns 0 for degenerate dispersion while the caller still reports the z as available

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:8266-8270,4661,5114-5116`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > RobustZ returns 0.0 when the denominator is below 1e-7 (:8269-8270). spread_z_available is set from median/session readiness alone (:5114) and spread_z is then a genuine-looking 0.0 (:5115-5116, :4661) which BlendExecutionScore weights at 0.14 (:5196).

- **Notes:** The RobustZ doc comment itself says degenerate dispersion carries no information; the availability flag should follow that.

### F-021 (S2, dashboard) — WrapLabelText wraps report lines at 63 characters but SetDashboardRow re-clips them to the measured pixel limit, truncating the wrapped tail

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:7482,7419`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > WrapLabelText's width is the character cap (:7482) while SetDashboardRow applies FitDashboardText and the pixel-derived limit (:7419, :7469). On a narrow chart the second line of an already-wrapped report loses its tail to an ellipsis rather than wrapping again.

- **Notes:** Tracker task 118 introduced the 63-character budget; the pixel fit and the character wrap disagree.

### F-022 (S2, dashboard) — UpdateActivityStatusLine recomputes CountDashboardObjects (up to 40 ObjectFind calls) on every scan that skips the full dashboard

- **Status:** START  |  **Category:** perf  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:6817-6825,6747`
- **Discovered by:** Phase B L5 + dashboard audit
- **Evidence (before):**

  > 'UpdateActivityStatusLine' calls BuildDiagnosticsLines (:6821), which reaches CountDashboardObjects (:6747) and its 40 ObjectFind calls, identically to the full path. Tracker task 69 removed exactly this cost from the full path (:6769) but the lighter path still pays it on every scan.


### F-023 (S2, tests) — No test exercises any ValidateInputs rejection path

- **Status:** START  |  **Category:** test  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:930-1109`
- **Discovered by:** Phase B L6
- **Evidence (before):**

  > ValidateInputs contains roughly 20 distinct rejection blocks and is invoked only from OnInit (:809). The self-test does not call it at all, and SELFTEST mode still runs it, so an input-validation regression can only be observed by attaching the indicator interactively.

- **Notes:** A pure-function refactor of the bound checks would make this testable without a terminal.

### F-024 (S2, tooling) — build-macos.sh cannot distinguish 'Wine cannot execute' from 'the compiler produced no result line', and reports the wrong exit code

- **Status:** START  |  **Category:** bug  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/build-macos.sh:47,116-120`
- **Discovered by:** Finding E-1
- **Evidence (before):**

  > The script checks only '[ -x "$WINE" ]' (:47), which is true for an x86_64 binary on an arm64 host without Rosetta. When Wine then fails to exec, the log is empty and the script exits 3 ('compiler produced no result line'), which the header documents as a compiler problem, not the environment problem (exit 2) it actually is. Observed on all four Macs.

- **Notes:** Fix: probe that Wine can actually execute before compiling, and report exit 2 with an actionable message.

### F-025 (S2, ops) — A live-looking GitHub PAT was supplied in plaintext and is present in the agent session transcript

- **Status:** START  |  **Category:** unsafe  |  **Host:** node3  |  **Commit:** -
- **Location:** `session credential handling`
- **Discovered by:** Phase B L4
- **Evidence (before):**

  > The token authenticates as the repository owner with admin/push rights. It is not in the repository, not in git history (gitleaks and trufflehog both clean over all 78 commits), and was not committed. It is, however, recorded in the session transcript and was used once for authentication.

- **Notes:** Not a repository defect. Recommendation: rotate the token and use a scoped, short-lived credential stored in a secrets manager; this audit held no secret on disk except in a 0600 file outside the repository that is deleted at the end.

### F-026 (S3, tooling) — ruff F541: two f-strings without placeholders

- **Status:** START  |  **Category:** style  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/census.py:273,274`
- **Discovered by:** Phase B baseline (ruff check)
- **Evidence (before):**

  > ruff check tools/census.py -> 'Found 2 errors' (F541 at :273 and :274); both are auto-fixable by removing the extraneous f prefix.


### F-027 (S3, tooling) — ruff format drift: the only Python file is not formatted to the formatter's standard

- **Status:** START  |  **Category:** style  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/census.py`
- **Discovered by:** Phase B baseline (ruff format --check)
- **Evidence (before):**

  > ruff format --check reports '1 file would be reformatted'.


### F-028 (S3, tooling) — shfmt drift in both shell scripts

- **Status:** START  |  **Category:** style  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/build-macos.sh; tools/selftest-macos.sh`
- **Discovered by:** Phase B baseline (shfmt -d)
- **Evidence (before):**

  > shfmt -d -i 2 -ci reports differences in both files: one-line brace guards expanded, case arms split, redirect spacing normalised.

- **Notes:** Cosmetic only; shellcheck is already clean. Applying it is safe but should be its own commit.

### F-029 (S3, tooling) — tools/census-allow.txt is documented and defaulted to but does not exist

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/census.py:17,338`
- **Discovered by:** Phase B L0 + docs audit
- **Evidence (before):**

  > census.py's docstring and its argparse default reference tools/census-allow.txt, and the wiki Testing page tells users to put exceptions there. The file is absent. read_allow() tolerates absence, so this is a documentation gap, not a failure.


### F-030 (S3, tooling) — .coverage is not ignored, so the coverage artifact required by the audit brief can be committed by accident

- **Status:** START  |  **Category:** style  |  **Host:** node3  |  **Commit:** -
- **Location:** `.gitignore`
- **Discovered by:** Phase B L0
- **Evidence (before):**

  > Running the mandated coverage measurement creates an untracked .coverage in the repository root; .gitignore lists *.ex5, *.log, *.out, *.tmp, *.bak and the MT5 runtime directories but not coverage data.


### F-031 (S3, repo) — One contributor appears under three different author identities

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `git history`
- **Discovered by:** Phase B L0
- **Evidence (before):**

  > git log shows 26 commits as 'Andre Borchert <andreborchert@MacBook-AB.local>', 27 as '<andreborchert@macbook-ab.tail1c3b90.ts.net>', 25 as 'Pummelchen <0xa0b1@gmail.com>' and 1 as 'Pummelchen <andreborchert@MacBook-AB.local>'. Attribution and contributor statistics are split.

- **Notes:** Fix is an additive .mailmap; no history rewrite. Never force-push.

### F-032 (S3, docs) — The gate script's header comment states the wrong assertion count (72; actual 117)

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 895ad9d
- **Location:** `tools/selftest-macos.sh:13`
- **Discovered by:** Phase B baseline
- **Evidence (before):**

  > ':13' says 'default run the built-in self-test (72 pure-helper assertions)'. The baseline run reports 'RESULT: 117 passed, 0 failed of 117 assertions'. README:50, CLAUDE.md:45, Architecture.md:49 and Testing-and-Validation.md:11 all say 117.

- **Fix:** tools/selftest-macos.sh's header no longer states an assertion count; it says the result line prints the total. README.md and CLAUDE.md likewise stopped duplicating the number.
- **Evidence (after):** grep -rnE '[0-9]+ (pure-helper )?assertions' README.md CLAUDE.md tools/ returns no match; the gate still reports its total at runtime ('RESULT: 130 passed, 0 failed of 130 assertions').

### F-033 (S3, docs) — The wiki Testing page hard-codes the assertion total on the same page that promises it never has to

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** wiki
- **Location:** `_fxnews-wiki/Testing-and-Validation.md:11,30`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > Line 11 states '117 assertions in eight groups'; line 30 states 'The result line prints the assertion total, so this page never has to.' Tracker task 110 asked for exactly the opposite.

- **Fix:** The wiki Testing and Architecture pages no longer hard-code the assertion total, honouring the same page's own promise that the result line prints it. The count changed twice during this audit (117 -> 123 -> 130) while regression tests were added, which is exactly the rot the hard-coded copies suffered. Committed in the wiki repository, not this one.
- **Evidence (after):** Wiki commit 'docs: stop hard-coding the self-test assertion total'; Testing-and-Validation.md:11 and Architecture.md:49 reworded.

### F-034 (S3, docs) — Known-Limitations calls all three gates macOS-only, but census.py is cross-platform

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `_fxnews-wiki/Known-Limitations.md:7`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > ':7' states 'The three gates ... are macOS-only'. tools/census.py requires only Python 3.14 (verified running on macOS but with no platform-specific code), and Development-Guide.md:9-10 correctly pairs it with the macOS-only self-test.


### F-035 (S3, docs) — Development-Guide both denies and documents the release process, and lists 'test' among commands that do not exist

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `_fxnews-wiki/Development-Guide.md:23`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > ':23' says 'there is no repository-local install, lint, typecheck, format, test, migration, Docker, or deployment command' and 'The release and distribution process is not currently documented', while Release-Checklist.md exists and the same page describes the census and self-test gates as commands.


### F-036 (S3, docs) — The tracker describes itself as open tasks and known bugs while showing 120/120 done, and its line-number baseline still says version 2.3

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `_fxnews-wiki/Project-Tracker.md:3,7,9`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > ':3' calls the page 'Open tasks and known bugs'; ':7' records 'Progress: 120 of 120 done'; ':9' states line numbers refer to commit 9069ca3 (version 2.3) although the page was rewritten for 3.0.


### F-037 (S3, docs) — The documented version-bump procedure requires a deployment clone at MQL5/Indicators/FXNews/ that does not exist on this machine

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `CLAUDE.md:24-30`
- **Discovered by:** Phase B L0
- **Evidence (before):**

  > CLAUDE.md step 2 tells the developer to fetch and reset a separate clone at MQL5/Indicators/FXNews/. That directory does not exist in the WINEPREFIX and no FXNews artifact exists anywhere in the MT5 tree; 'build-macos.sh --install' would create it.


### F-038 (S3, scoring) — Unreachable guard: total_weight can never be zero

- **Status:** START  |  **Category:** dead  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:4948-4949`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > execution_weight (0.18) and regime_weight (0.14) are unconditional (:4941, :4943), so total_weight is at least 0.32 and the 'if(total_weight <= 0.0) total_weight = 1.0' branch at ':4948-4949' cannot be taken.

- **Notes:** Defensive but provably dead; census.py does not have an unreachable-branch category, which is why it was not caught.

### F-039 (S3, docs) — The age_free_score field comment understates what the value excludes

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:396,5012-5041`
- **Discovered by:** Phase B L3 + scoring agent
- **Evidence (before):**

  > ':396' documents age_free_score as 'displayed score before the event-age caps', but it is captured at ':5012' before the calendar-uncertainty, single-feature and elite caps are also applied (:5023-5042).


### F-040 (S3, logic) — The hard 95 ceiling is the only cap that records no reason string

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:5044-5045`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > Every other cap goes through ApplyScoreCap and appends to cap_reasons (:4963-5042); the final 'if(capped > 95.0) capped = 95.0' at ':5044-5045' bypasses the helper, so a 95 score's cap_reasons does not mention the ceiling.


### F-041 (S3, logic) — Redundant threshold re-check in IsConfirmedSignal for CONFIRM_BAR_CLOSE

- **Status:** START  |  **Category:** dead  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:6187,6410`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > ':6187' re-tests MeetsThreshold(score, MinDisplayConfidence) although every call site already gated on it (:6410 and the candidate path), so the branch is unreachable in the failing direction.


### F-042 (S3, dashboard) — PushSignalHistory's shift loop copies empty slots when the list is not yet full

- **Status:** START  |  **Category:** perf  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:7261-7262`
- **Discovered by:** Phase B L5 + dashboard audit
- **Evidence (before):**

  > ':7261-7262' shifts from evict down to index 1 even when evict is far beyond the used count, copying unused entries. Correct but wasted work; the loop should start at min(evict, count).


### F-043 (S3, logic) — SmoothStep silently re-orients reversed edges instead of surfacing a configuration error

- **Status:** START  |  **Category:** logic  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:8198-8208`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':8198-8208' swaps the edges when edge0 > edge1. Every caller derives edges from validated inputs today, but a future reversed bound would silently invert a scoring ramp rather than failing — the exact defect class the self-test was created for.


### F-044 (S3, docs) — The ATR definition (simple mean of true range, not Wilder smoothing) is undocumented

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `FXNews.mq5:4401-4425`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > CalculateATRFromRates returns the arithmetic mean of true range over ATRPeriod. No wiki page states whether ATR is Wilder-smoothed; Configuration.md and Signal-Logic.md both discuss ATR thresholds without defining it.

- **Notes:** Every threshold expressed in ATR inherits this definition, so it belongs in the wiki.

### F-045 (S3, tooling) — --install creates the destination directory silently and never verifies the terminal can load the binary

- **Status:** START  |  **Category:** docs  |  **Host:** node3  |  **Commit:** -
- **Location:** `tools/build-macos.sh:150-156`
- **Discovered by:** Phase B L7
- **Evidence (before):**

  > ':152' runs 'mkdir -p "$DEST"' and ':153' copies the .ex5, printing success. CLAUDE.md warns that a stale .ex5 beside a current .mq5 is a trap because MT5 loads the binary, but nothing in the workflow reports which one the terminal will see.

- **Notes:** A post-install check that the copied .ex5 is newer than its .mq5, or at least an explicit printed warning, closes the trap.
