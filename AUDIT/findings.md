# FXNews audit — finding enumeration (Phase B)

Generated from `AUDIT/ledger.json` by `AUDIT/render.py` — do not edit by hand.
Branch `audit/2026-09-15`, base commit `71ce980`.

**total 59 | done 58 | open 0 | blocked 1 | S0:1 S1:14 S2:18 S3:26**

Severity follows the audit brief §7. Work order: all S0, then S1, S2, S3.

| id | sev | area | status | file:line | title |
| --- | --- | --- | --- | --- | --- |
| E-1 | S0 | tooling | DONE | `tools/build-macos.sh:40` | Build and self-test gates cannot execute: bundled wine64 is x86_64 and Rosetta 2 was absent on all four Macs |
| E-2 | S1 | tooling | DONE | `tools/selftest-macos.sh:34` | No MQL5 formatter, linter, static analyzer, SAST scanner or coverage tool exists |
| E-3 | S1 | verification | DONE | `n/a (environment)` | The historical end-to-end gates cannot reach green in this environment until M1 history is available at run time |
| E-4 | S1 | verification | DONE | `n/a (fleet)` | Provision an independent macOS host for Phase E |
| E-5 | S1 | verification | DONE | `n/a (fleet)` | Phase E's self-test gate could not run over SSH: the spare Macs' terminal exits when launched outside the Aqua session |
| E-6 | S1 | verification | DONE | `n/a (fleet)` | Phase E final verification from a fresh clone on a host that did not develop the fixes |
| F-002 | S1 | scoring | DONE | `FXNews.mq5:4502` | UpdateSessionBaseline folds active_trigger_tick_volume into the tick-volume baseline unguarded, while the adjacent line explicitly guards the tick rate |
| F-003 | S1 | scoring | DONE | `FXNews.mq5:4268,4704,5418,5917` | movement_5m_pips falls back to a 0.0 sentinel when the M1 copy fails and is then consumed as a measured value by three components |
| F-004 | S1 | historical | DONE | `FXNews.mq5:2728` | Historical impulse evaluation forces acceleration_available and continuation_available to true, hard-coding weights for inputs that may be unmeasurable |
| F-005 | S1 | historical | DONE | `FXNews.mq5:2667` | Historical execution gate applies cost_to_atr unconditionally, so VALIDATION/AUTOTUNE do not reproduce the live filter set when UseStrictExecutionGate is off |
| F-006 | S1 | historical | DONE | `FXNews.mq5:2693,5310-5318,4984-4989` | Two composite caps are structurally inert in history, so historical scores are systematically less penalised than live scores |
| F-007 | S1 | tests | DONE | `FXNews.mq5:1455-1459` | The availability-and-composer self-test assertion cannot detect an exclusion regression |
| F-008 | S1 | tests | DONE | `README.md:50; FXNews.mq5` | The live signal lifecycle, correlation grouping, alert dispatch and dashboard rendering have no automated coverage |
| F-046 | S1 | tooling | DONE | `tools/selftest-macos.sh:145-156` | The historical gate passed a VALIDATION report that had read no data at all |
| F-047 | S1 | historical | DONE | `FXNews.mq5:2140 (LoadHistoricalM1Rates), 2060 (ProcessHistoricalProfile)` | The historical modes treat the first empty M1 copy as final, so a history download in progress yields an empty report |
| F-001 | S2 | scoring | DONE | `FXNews.mq5:5222,5310,5324` | ComputeBreakoutStructure did not initialise its own output, so the documented pure shared function returned garbage to a direct caller (originally filed as a hold_score imputation) |
| F-009 | S2 | scoring | DONE | `FXNews.mq5:4476-4477,7956-7957` | session_baseline_ready is a single flag for three independent baselines, so a z-score can be reported as measured when its own baseline never received samples |
| F-011 | S2 | dashboard | DONE | `FXNews.mq5:3788,6802-6804,7182` | g_signal_history_dirty is never cleared while active signal rows are rendered, forcing a full dashboard rebuild every scan |
| F-014 | S2 | tooling | DONE | `tools/build-macos.sh:40-43; tools/selftest-macos.sh:38-40` | The Wine path, WINEPREFIX and MT5 path constants are duplicated across the two gate scripts and can drift |
| F-015 | S2 | tooling | DONE | `FXNews.mq5:1725; tools/mql5/FXNewsSelfTest.mq5:14,32-34; tools/selftest-macos.sh:72,139,159-163` | The indicator, the harness and the gate script are coupled by undocumented string literals with no contract test |
| F-016 | S2 | ops | DONE | `.github/` | No CI workflow: the three release gates are never run automatically |
| F-017 | S2 | validation | DONE | `FXNews.mq5:942,988-995` | MaxQuoteAgeSeconds and FullHoldScoreSeconds have no upper bound, so extreme values silently disable the freshness gate or make the HYBRID hold clause unreachable |
| F-018 | S2 | scoring | DONE | `FXNews.mq5:5026-5031` | single_feature_cap is applied without checking that the feature it measures was evaluated |
| F-019 | S2 | scoring | DONE | `FXNews.mq5:4958-4959` | The +0.05 synergy bonus is awarded on component scores without checking that either engine passed or was measured |
| F-021 | S2 | dashboard | DONE | `FXNews.mq5:7482,7419` | WrapLabelText wraps report lines at 63 characters but SetDashboardRow re-clips them to the measured pixel limit, truncating the wrapped tail |
| F-023 | S2 | tests | DONE | `FXNews.mq5:930-1109` | No test could reach any ValidateInputs rejection path |
| F-024 | S2 | tooling | DONE | `tools/build-macos.sh:47,116-120` | build-macos.sh cannot distinguish 'Wine cannot execute' from 'the compiler produced no result line', and reports the wrong exit code |
| F-025 | S2 | ops | BLOCKED | `session credential handling` | A live-looking GitHub PAT was supplied in plaintext and is present in the agent session transcript |
| F-048 | S2 | historical | DONE | `FXNews.mq5 (BuildAutotuneReport / BuildValidationReport interpretation lines)` | The historical reports print the same generic interpretation whether or not higher score buckets actually produced better outcomes |
| F-049 | S2 | tests | DONE | `FXNews.mq5 (UpdateAlertGroups, DispatchPendingAlerts, UpdateDashboard, BuildDiagnosticsLines)` | Alert dispatch, correlation grouping and dashboard rendering still have no automated coverage |
| F-050 | S2 | tooling | DONE | `.github/workflows/ci.yml; tools/selftest-macos.sh:89-96` | The CI workflow pinned every analysis tool except shellcheck, and the unpinned one failed the build |
| F-052 | S2 | reporting | DONE | `FXNews.mq5 (historical bucket aggregation and ranking verdict)` | The ranking evaluation could not say WHY the ranking failed - caps or the score |
| F-053 | S2 | scoring | DONE | `FXNews.mq5 (rank evaluation, measured not changed)` | MEASURED: the score does not rank 30m outcomes on the audit sample, and the caps are not the cause |
| F-010 | S3 | historical | DONE | `FXNews.mq5:2926-2930,3039` | The 85+ bucket in the historical report is unreachable (now empirically confirmed; the wiki already documents the empty bucket, so only the unannotated report row remains) |
| F-012 | S3 | scoring | DONE | `FXNews.mq5:5330-5331` | DISPROVED: the wick penalty's missing denominator entry is the correct arrangement |
| F-013 | S3 | dashboard | DONE | `FXNews.mq5:6325,6246` | DOMINANT FLOW's fallback group id is shared by every timeframe of a symbol - deliberate, not a defect |
| F-020 | S3 | scoring | DONE | `FXNews.mq5:8266-8270,4661,5114-5116` | RobustZ returning 0 on degenerate dispersion is the correct z, not an imputation (filed as a false-measured spread_z; disproved) |
| F-022 | S3 | dashboard | DONE | `FXNews.mq5:6817-6825,6747` | BuildDiagnosticsLines recounts the dashboard objects on every scan, including the light path |
| F-026 | S3 | tooling | DONE | `tools/census.py:273,274` | ruff F541: two f-strings without placeholders |
| F-027 | S3 | tooling | DONE | `tools/census.py` | ruff format drift: the only Python file is not formatted to the formatter's standard |
| F-028 | S3 | tooling | DONE | `tools/build-macos.sh; tools/selftest-macos.sh` | shfmt drift in both shell scripts |
| F-029 | S3 | tooling | DONE | `tools/census.py:17,338` | tools/census-allow.txt is documented and defaulted to but does not exist |
| F-030 | S3 | tooling | DONE | `.gitignore` | .coverage is not ignored, so the coverage artifact required by the audit brief can be committed by accident |
| F-031 | S3 | repo | DONE | `git history` | One contributor appears under three different author identities |
| F-032 | S3 | docs | DONE | `tools/selftest-macos.sh:13` | The gate script's header comment states the wrong assertion count (72; actual 117) |
| F-033 | S3 | docs | DONE | `_fxnews-wiki/Testing-and-Validation.md:11,30` | The wiki Testing page hard-codes the assertion total on the same page that promises it never has to |
| F-034 | S3 | docs | DONE | `_fxnews-wiki/Known-Limitations.md:7` | Known-Limitations calls all three gates macOS-only, but census.py is cross-platform |
| F-035 | S3 | docs | DONE | `_fxnews-wiki/Development-Guide.md:23` | Development-Guide both denies and documents the release process, and lists 'test' among commands that do not exist |
| F-036 | S3 | docs | DONE | `_fxnews-wiki/Project-Tracker.md:3,7,9` | The tracker describes itself as open tasks and known bugs while showing 120/120 done, and its line-number baseline still says version 2.3 |
| F-037 | S3 | docs | DONE | `CLAUDE.md:24-30` | The documented version-bump procedure requires a deployment clone at MQL5/Indicators/FXNews/ that does not exist on this machine |
| F-038 | S3 | scoring | DONE | `FXNews.mq5:4948-4949` | Unreachable guard: total_weight can never be zero |
| F-039 | S3 | docs | DONE | `FXNews.mq5:396,5012-5041` | The age_free_score field comment understates what the value excludes |
| F-040 | S3 | logic | DONE | `FXNews.mq5:5044-5045` | The hard 95 ceiling is the only cap that records no reason string |
| F-041 | S3 | logic | DONE | `FXNews.mq5:6187,6410` | The BAR_CLOSE confirmation rule was unreachable by any test, and its threshold clause is redundant |
| F-042 | S3 | dashboard | DONE | `FXNews.mq5:7261-7262` | PushSignalHistory's shift loop copies empty slots when the list is not yet full |
| F-043 | S3 | logic | DONE | `FXNews.mq5:8198-8208` | DISPROVED: SmoothStep's edge re-orientation is a tested fix for a pre-1.4 defect |
| F-044 | S3 | docs | DONE | `FXNews.mq5:4401-4425` | The ATR definition (simple mean of true range, not Wilder smoothing) is undocumented |
| F-045 | S3 | tooling | DONE | `tools/build-macos.sh:150-156` | --install creates the destination directory silently and never verifies the terminal can load the binary |
| F-051 | S3 | testing | DONE | `FXNews.mq5 (UpdateDashboard, SetDashboardRow, DeleteDashboardRowsFrom)` | Dashboard row rendering and the signal-history eviction dwell still have no automated coverage |

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

### E-3 (S1, verification) — The historical end-to-end gates cannot reach green in this environment until M1 history is available at run time

- **Status:** DONE  |  **Category:** deps  |  **Host:** node3  |  **Commit:** 81b79d4
- **Location:** `n/a (environment)`
- **Discovered by:** Phase D, diagnosing F-046
- **Evidence (before):**

  > After F-046 the gate correctly fails any VALIDATION or AUTOTUNE run that reads no history. In this environment every such run reads zero bars because of the download race described in F-047, so the historical end-to-end gates are red for a truthful reason rather than passing falsely.

- **Fix:** Resolved by the F-047 fix. The historical end-to-end gates now reach green in this environment and the historical engine was exercised on real broker history for the first time in this audit.
- **Evidence (after):** Both historical modes now run end to end on real broker history. --validation exit 0: 50000 M1 bars, 2589 boundaries evaluated, Signals=601 (reproduced twice). --autotune exit 0: 9 candidates over 2584 boundaries, 'Current: signals=603 avgScore=74.7 PF=0.79 AvgR30=-0.134 Hit30=35.7%', a ranked best candidate, recommended settings printed, and 'Applied: no runtime change' - the advisory boundary holds. The AUTOTUNE wait also exercised the timeout branch: EURUSD consumed its full 60 s budget and was skipped while GBPUSD loaded ('2/2 symbols processed (GBPUSD, 50000 M1 bars, 48.8 days)').
- **Notes:** Was filed BLOCKED with three options for a human. Option (1) - fix F-047 - was implemented and removed the blocker, so no human decision is outstanding. Residual, not blocking: a symbol needing more than the budget still reports unavailable; HistoricalHistoryWaitSeconds is tunable to 600. Observation for a human, outside code-correctness scope: on this single-symbol 48.8-day sample the score does not rank outcomes - bucket AvgR30 is -0.068, -0.105, -0.075, -0.237, -0.110 across <65 to 80-84, i.e. higher scores did not produce better R, and no candidate beat CURRENT. The report's own interpretation line says a useful score should show better R/PF in higher buckets, yet it prints the same text whether or not that holds. Filed as F-048. A go-live decision should treat the absence of a demonstrated ranking edge on this sample as material.

### E-4 (S1, verification) — Provision an independent macOS host for Phase E

- **Status:** DONE  |  **Category:** deps  |  **Host:** node1, node2  |  **Commit:** cec2a11
- **Location:** `n/a (fleet)`
- **Discovered by:** Phase E
- **Evidence (before):**

  > All four Macs lacked Rosetta 2, so no Mac in the fleet could execute the x86_64 Wine bundle and therefore none of them could run any gate. node1 and node2 additionally had no fresh clone of the repository.

- **Fix:** Installed Rosetta 2 on node1 and node2 (the exact command is logged in AUDIT/environment.md); cloned the audit branch fresh on both. node1's bundled Wine was 9.8 (app 5.0.4330) and its terminal refused to start, so a copy of node3's newer app was staged into node1's home and used through the FXNEWS_WINE override added by F-024 rather than touching /Applications, which would have needed sudo. node2 turned out to already have app 5.0.4501 — the same version as the working development host — and was made the Phase E host.
- **Evidence (after):** Fresh clone on node2: 21 tracked files, working tree clean at 64060cc. Zero-warning compile verified on the independent host: 'Result: 0 errors, 0 warnings'. contracts 0 violations and census 0 open findings verified on node1 and again on node2.
- **Notes:** The compile gate is the one most likely to differ between machines, and it was reproduced on two hosts that did none of the development. The staged app on node1 was removed afterwards; node2's clone is retained for the retry described in E-5.

### E-5 (S1, verification) — Phase E's self-test gate could not run over SSH: the spare Macs' terminal exits when launched outside the Aqua session

- **Status:** DONE  |  **Category:** deps  |  **Host:** node1, node2  |  **Commit:** 99d5251
- **Location:** `n/a (fleet)`
- **Discovered by:** Phase E
- **Evidence (before):**

  > On node2, from a fresh clone at 64060cc with Rosetta 2 installed and Wine 9.14 available, './tools/selftest-macos.sh' compiles both files with 0 errors and 0 warnings and then reports 'no Experts journal at .../MQL5/Logs/20260915.log'. The terminal log shows the cause: the terminal logs 'unstable and unsupported Wine 9.14' and 'exit with code 0' 0.05 s later, before the script or the indicator is loaded. On the working development host node3 the identical warning is followed 2.3 s later by 'script FXNewsSelfTest (EURUSD,M5) loaded successfully' and 'custom indicator FXNews (EURUSD,M5) loaded succesfully'. node1 fails identically. PRISTINE-BASELINE PROOF: a fresh clone of main (fa68540, no audit changes) fails identically on node1, and node1's terminal exits the same way when launched with NO startup config at all, so this is not caused by any change in this audit and not by the harness configuration.

- **Fix:** Root cause was the launchd session type, not MetaTrader and not broker authorization. macOS does not let a process in a Background launchd session connect to WindowServer, and MetaTrader 5 is a windowed application: started over SSH it initialises graphics and exits cleanly with code 0 before loading any script. The remedy is to run the gate inside the console user's GUI session: `sudo launchctl asuser "$(id -u)" sudo -u <user> /bin/bash -lc '<command>'`. No product change was needed; the launchctl wrapper is recorded in AUDIT/environment.md as the Phase E procedure.
- **Evidence (after):** Independent host node2, fresh clone at 64060cc, 21 tracked files, working tree clean, all four gates green inside the Aqua session: contracts 0 violations across 6; census 0 open findings (zero placeholders); zero-warning compile 'Result: 0 errors, 0 warnings'; self-test 'RESULT: 149 passed, 0 failed of 149 assertions' with 'SELFTEST PASSED'. Scanner suite on the same host: ruff check, ruff format --check, mypy --strict, bandit, shellcheck, shfmt -d and a full-history gitleaks scan all PASS. Coverage: census.py 86%, contracts.py 77%, total 84%. Diagnostic evidence: `launchctl managername` returns Aqua on the working host and Background over SSH on the spare, and the terminal's own log shows it exiting 0.05 s after the Wine warning on the spare versus loading the script 2.3 s later on the working host.
- **Notes:** WRONG HYPOTHESIS, recorded because it was in the ledger: E-5 was first filed with 'the strongest remaining signal is broker authorization', inferred from node3's log holding an 'authorized on' line while the spares held none. That inference was wrong - broker authorization had nothing to do with it, and a Wine-level launch with errors visible showed no fatal fault either. The launchd session check (`launchctl managername`) settled it in one command. The lesson is that two hosts differing in several ways were compared on the first difference noticed rather than on a direct test of the mechanism, which the managername check is. PHASE E STATUS: the verification machinery is now proven and reproducible, but Phase E must be re-run on the FINAL commit after Phase C finishes, because it verifies the final state and 22 findings are still open.

### E-6 (S1, verification) — Phase E final verification from a fresh clone on a host that did not develop the fixes

- **Status:** DONE  |  **Category:** deps  |  **Host:** node2  |  **Commit:** 98c608c
- **Location:** `n/a (fleet)`
- **Discovered by:** Phase E
- **Evidence (before):**

  > Phase E verifies the final state, so it could not run until Phase C finished. It also needs a machine that did none of the development, and the earlier attempt established that this requires the gate to run inside the console user's Aqua launchd session (E-5).

- **Fix:** Fresh clone of the audit branch on node2 (app 5.0.4501, Wine 9.14, Rosetta 2 installed by E-4), with all four gates run inside the Aqua session via launchctl asuser. No fixes were developed on node2.
- **Evidence (after):** commit 98c608c, branch audit/2026-09-15, 23 tracked files, working tree clean. contracts: 0 violations across 9. census: 0 open findings, 0 allowed (zero placeholders). compile: 'Result: 0 errors, 0 warnings'. self-test: 'RESULT: 199 passed, 0 failed of 199 assertions' with SELFTEST PASSED. Scanners on the same host: ruff check, ruff format --check, mypy --strict, bandit, shellcheck, shfmt -d and a full-history gitleaks scan all PASS. Coverage: census.py 88%, contracts.py 74%, total 83%.
- **Notes:** Run from a fresh clone on the independent host rather than from the development tree, which is what the brief requires and what makes the result evidence of the committed state rather than of the working copy. The ledger at this point holds no non-BLOCKED open task: 56 tasks, 55 DONE and 1 BLOCKED (F-025, credential rotation, which only a human can perform).

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

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 5c21284
- **Location:** `FXNews.mq5:4268,4704,5418,5917`
- **Discovered by:** Phase B L3
- **Evidence (before):**

  > ':4268' sets movement_5m_pips = 0.0 when copied_m1 <= 5; there is no availability flag. It is consumed at ':4704' (currency-strength five-minute normaliser n5m), ':5418' (impulse exhaustion_penalty) and ':5917' (basket-agreement pair_move). A zero reads as 'no move', which suppresses exhaustion and biases both the flow and agreement terms.

- **Fix:** SymbolProfile carries has_movement_5m, set together with the value and copied on the sibling-context path. Currency strength drops the 5-minute term and its 0.30 weight from the normaliser when unmeasured; basket agreement skips an unmeasured peer instead of scoring it as a neutral half-agreement; ImpulseQuality carries exhaustion_available and overextended_cap is gated on it. The historical path sets exhaustion_available from continuation_available.
- **Evidence (after):** New self-test group 'exhaustion availability'. BEFORE (availability gate removed): 1 assertion FAILED - 'ComposeSignalScore ignores an overextension reading that was not measured'; RESULT 134 passed, 1 failed of 135; exit 1. AFTER: RESULT 135 passed, 0 failed of 135; exit 0. Historical regression: --validation still reports 50000 bars, 2589 boundaries, Signals=601, Avg score=74.7, PF=0.79 - identical to before the change, confirming the live path was the one affected. Build 0/0; census 0 findings; shellcheck clean.
- **Notes:** Same class as the tracker's closed tasks 21-29 (exclude-don't-impute); this instance was missed. Coverage limit recorded honestly: the two aggregation exclusions (currency strength, basket agreement) are verified by review and the historical regression run, not by a unit assertion, because exercising them needs a live profile set with resolved currency indices, spreads and snapshot history.

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

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 0a4b05f
- **Location:** `FXNews.mq5:2693,5310-5318,4984-4989`
- **Discovered by:** Phase B L2 + historical audit
- **Evidence (before):**

  > ':2693' always passes outside_seconds=60.0 when distance>0 (hold_score saturates to 1.0 against FullHoldScoreSeconds=12) and reentered_seconds=-1.0 (fakeout_penalty stays 0.0). Consequently weak_hold_cap (:4984) and range_snapback_cap (:4988) can never bind in a historical run, while they do bind live. Re-entry is genuinely untrackable in history (documented at :2685-2687), but the consequence for the reported score distribution is not documented.

- **Fix:** AddHistoricalCoverageLines emits three lines on every VALIDATION and AUTOTUNE report naming the two caps that cannot bind in a historical run, and Validation-and-Autotune.md states the consequence.
- **Evidence (after):** Real run: ./tools/selftest-macos.sh --validation exit 0 prints 'Model limits: hold below the scan timeframe is not resolvable and intra-bar / re-entry is not tracked, so hold_score saturates and fakeout_penalty is 0; / weak_hold_cap and range_snapback_cap cannot bind here, unlike a live scan.' Build 0 errors / 0 warnings. Report and documentation change only, so there is no fail-before test; the evidence is the emitted report text.
- **Notes:** Affects the fidelity of the report that Autotune ranks candidates on. Cross-check: the facts were already in the wiki ('Hold is one minute of resolution ... No re-entry is tracked'); the undisclosed part was the consequence for the cap ladder and the score distribution.

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

- **Status:** DONE  |  **Category:** test  |  **Host:** node3  |  **Commit:** e504ac5
- **Location:** `README.md:50; FXNews.mq5`
- **Discovered by:** Phase B L6; already disclosed in Known-Limitations.md:8 and CLAUDE.md:52-54
- **Evidence (before):**

  > Known-Limitations.md:8 and CLAUDE.md:52-54 state these areas are verified only by manual runtime observation. Several of the audit's behaviour findings (F-011, F-013, F-018) live exactly in that uncovered region, which is why they survived the 3.0 audit.

- **Fix:** New self-test group 'signal lifecycle' drives UpdateSignalState from synthetic scores: event creation, confirmation and timestamping, the age-limit ending into a cooldown, cooldown blocking, and reversal into the candidate path. Covers the deterministic core of the state machine for every confirmation mode without touching alert or dashboard surfaces.
- **Evidence (after):** Introduced the test and proved it detects the defect class by reintroducing the real 2.x regression (active TTL hard-coded to 300 s, tracker task 13). BEFORE: 2 assertions FAILED - 'the age limit ends the signal into a cooldown' and 'a running cooldown holds that direction out'; RESULT 138 passed, 2 failed of 140; exit 1. AFTER: RESULT 140 passed, 0 failed of 140; exit 0. Build 0/0; census 0 findings; shellcheck clean. A first injection targeted EventAgeLimitSeconds() and correctly did NOT fail the test, because that function feeds the composer's age cap rather than the active-state TTL; the injection site was corrected and the false negative is recorded in the commit so a green result is not mistaken for proof.
- **Notes:** SCOPE NOTE, per the rule that a task may not be closed by narrowing it. F-008 originally covered four areas: the live signal lifecycle, correlation grouping, alert dispatch and dashboard rendering. This task now covers the lifecycle only; the other three need the terminal's object and notification surfaces and are moved to the new task F-049. F-008 is therefore complete for its reduced subject with the remainder explicitly re-homed, not dropped.

### F-046 (S1, tooling) — The historical gate passed a VALIDATION report that had read no data at all

- **Status:** DONE  |  **Category:** test  |  **Host:** node3  |  **Commit:** f2f094c
- **Location:** `tools/selftest-macos.sh:145-156`
- **Discovered by:** Phase D - found at run time while gathering evidence for F-006, not by reading code
- **Evidence (before):**

  > A --validation run whose report read 'Window: 1970.01.01 -> 1970.01.01 (0.0 of 90 days) | Symbols 0/2 | Profiles with data=0 | M1 bars=0' still produced 'selftest: OK (validation report complete, Signals=0)' with exit 0. The mode exists to exercise the historical engine end to end and the wiki Testing page says so, yet the engine had read zero bars, so any regression in the historical path would have gone unnoticed. The harness used a fresh one-shot terminal that never opened an M1 chart, so this reproduced on every run.

- **Fix:** The gate parses loaded symbols, loaded M1 bars and evaluated boundaries from the report and refuses to pass a VALIDATION or AUTOTUNE run that read no history, printing the actionable cause. It requires data, not signals: a quiet market legitimately yields zero signals, so gating on signals would be a different bug.
- **Evidence (after):** BEFORE: 'selftest: OK (validation report complete, Signals=0)', exit 0. AFTER: 'selftest: FAILED (validation read no history: 0 symbol(s) loaded, 0 M1 bar(s), 0 boundar(ies) evaluated)', exit 1, with guidance to open an M1 chart. shellcheck clean.
- **Notes:** This defect also invalidated the project's own 3.0 release claim that the historical gates were green: they were green on an empty report.

### F-047 (S1, historical) — The historical modes treat the first empty M1 copy as final, so a history download in progress yields an empty report

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 81b79d4
- **Location:** `FXNews.mq5:2140 (LoadHistoricalM1Rates), 2060 (ProcessHistoricalProfile)`
- **Discovered by:** Phase D, diagnosing F-046
- **Evidence (before):**

  > Reproduced on every --validation run: the report reads 'Symbols 0/2 | M1 bars=0' and the Journal says 'EURUSD has no M1 history in the window (error 4401) and is skipped; open a chart of the symbol so the terminal downloads it, then re-run'. The terminal log shows the cause is a race, not a missing feed: the one-shot terminal authorizes on ICMarketsSC-MT5-4 (account 11013759, 8526 symbols synchronized) and shuts down about two seconds later, while CopyRates(PERIOD_M1, from, last_closed) triggers an on-demand download that has not completed. LoadHistoricalM1Rates returns 0 on the first attempt and the symbol is skipped for the whole run; CopyRates is never retried. History files do exist on disk (269 .hcc, including Bases/Default/history/EURUSD/2024.hcc and GBPUSD/2024.hcc).

- **Fix:** LoadHistoricalM1Rates polls CopyRates for the requested window inside a bounded, IsStopped-aware budget and reports a wait of two seconds or more; new input HistoricalHistoryWaitSeconds (default 60, validated 0..600 via MAX_HISTORICAL_HISTORY_WAIT_SECONDS), where 0 restores the single-attempt behaviour.
- **Evidence (after):** The gate is the unit under test. BEFORE (retry disabled): 'Symbols 0/2 | M1 bars=0', 'selftest: FAILED (validation read no history ...)', exit 1 - run twice. AFTER: 'Symbols 1/2 | Profiles with data=2 | M1 bars=50000', 'Boundaries: evaluated 2589 of ~10683', 'Signals=601', gate OK, exit 0 - run twice (2588/605 then 2589/601). Falsification attempted: the retry-disabled version was re-run after a successful populated run with the same terminal state and still read 0 bars, which rejects cache warming as the explanation.
- **Notes:** Correct fix is a bounded wait: poll CopyRates for the requested window for up to a configured number of seconds (respecting IsStopped), and report how long it waited, instead of treating the first empty copy as final. That is the documented MT5 pattern for on-demand history and it also fixes the real operator scenario 'I opened MT5 and ran VALIDATION immediately'. Rejected alternative: pre-opening M1 charts from the harness - it hides the defect and does not help a human operator. Rejected alternative: raising the harness timeout - it cannot help, because the run happens on the first timer tick after startup and the failure is deterministic within that tick. Sub-two-second retries are the normal successful path, which is why no wait line appears; the Journal line only fires at two seconds or more.

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

### F-011 (S2, dashboard) — g_signal_history_dirty is never cleared while active signal rows are rendered, forcing a full dashboard rebuild every scan

- **Status:** DONE  |  **Category:** perf  |  **Host:** node3  |  **Commit:** 1abef21
- **Location:** `FXNews.mq5:3788,6802-6804,7182`
- **Discovered by:** Phase B L5 + dashboard audit
- **Evidence (before):**

  > The flag is set at ':7240' and ':7265' and cleared only in RefreshVisibleSignalHistory (:7182), which is reachable only through RefreshVisibleSignalHistoryIfDue (:7135-7145) from the 'if(row == first_row)' branch of UpdateDashboard (:6802-6804). With ShowActiveSignalRows=true and at least one ranked row, that branch is skipped, the flag stays true, and ScanAll's condition at ':3788' forces UpdateDashboard every scan, defeating DisplayUpdateSeconds. Verified by grepping every write site of the flag.

- **Fix:** UpdateDashboard now calls RefreshVisibleSignalHistoryIfDue() before it branches on the display mode, so the cache behind g_signal_history_dirty is always current and the flag is always consumed; the branch now decides only what to render.
- **Evidence (after):** BEFORE (refresh moved back inside the display branch): tools/contracts.py FAILS with 'UpdateDashboard refreshes the history only after if(ShowActiveSignalRows); with active rows enabled the dirty flag is then never cleared and the dashboard rebuilds every scan (F-011)', exit 1. AFTER: 0 violations, exit 0. New self-test group 'history refresh' asserts the flag-consume contract directly; full gate 145 passed, 0 failed of 145. Build 0/0; census 0 findings; shellcheck clean.
- **Notes:** The call-site part of this fix has no runtime unit test by design: driving UpdateDashboard inside the self-test creates chart objects and could overwrite the harness's own verdict label. It is machine-checked structurally by tools/contracts.py instead, which is what makes the regression guard real rather than a comment.

### F-014 (S2, tooling) — The Wine path, WINEPREFIX and MT5 path constants are duplicated across the two gate scripts and can drift

- **Status:** DONE  |  **Category:** dead  |  **Host:** node3  |  **Commit:** 970f8e5
- **Location:** `tools/build-macos.sh:40-43; tools/selftest-macos.sh:38-40`
- **Discovered by:** Phase B L1
- **Evidence (before):**

  > Both scripts independently hard-code '/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64' and the same WINEPREFIX; the MT5 sub-path is repeated in build-macos.sh:42 and selftest-macos.sh:39-40. Extracting them into one sourced file is the standard fix.

- **Fix:** New tools/lib-mt5.sh holds the Wine path, the WINEPREFIX and the MetaTrader paths with mt5_configure and mt5_require_wine; both gate scripts source it. mt5_require_wine probes 'wine64 --version' and exits 2 naming the real cause (on arm64, the exact Rosetta 2 install command) instead of letting the failure surface later as a compiler result. FXNEWS_WINE and FXNEWS_WINEPREFIX allow a different install and make the checks themselves testable.
- **Evidence (after):** Scripts are the unit under test. BEFORE (probe removed): 'build: MetaEditor wrote no log (wine exit status 1)', exit 3 - the misleading compiler diagnosis, reproduced deliberately. AFTER: 'wine64 exists but cannot run ... needs Rosetta 2 ... sudo softwareupdate --install-rosetta --agree-to-license', exit 2; the same probe on selftest-macos.sh exits 2; a missing binary still reports 'wine64 not found' with exit 2 so the two failures stay distinguishable. No regression: build 0/0, full selftest 142 passed / 0 failed, explicit-source-path build works, census 0 findings, shellcheck clean on all three files. shellcheck's SC2034 on ME/TERMINAL was fixed by exporting the interface variables rather than with a disable directive.
- **Notes:** Shares the code being changed with F-024 and is committed with it as audit(F-014,F-024).

### F-015 (S2, tooling) — The indicator, the harness and the gate script are coupled by undocumented string literals with no contract test

- **Status:** DONE  |  **Category:** unsafe  |  **Host:** node3  |  **Commit:** 1abef21
- **Location:** `FXNews.mq5:1725; tools/mql5/FXNewsSelfTest.mq5:14,32-34; tools/selftest-macos.sh:72,139,159-163`
- **Discovered by:** Phase B L1
- **Evidence (before):**

  > Four implicit contracts: the verdict labels 'SELFTEST PASSED'/'VALIDATION ready'/'AUTOTUNE ready'/'ABORTED'; the result line 'RESULT: N passed, M failed'; the harness indicator path 'FXNews-selftest\FXNews'; and the install directory. Rewording a label in the indicator silently turns the gate into a timeout failure with no indication of the cause.

- **Fix:** New tools/contracts.py checks five cross-file contracts across FXNews.mq5, tools/mql5/FXNewsSelfTest.mq5 and tools/selftest-macos.sh - verdict labels, the result line, the report fields the gate parses, the harness install path - plus the F-011 structural invariant. selftest-macos.sh runs it before compiling; CLAUDE.md and README.md document it as a gate.
- **Evidence (after):** BEFORE (one verdict label reworded in the harness only): contracts.py FAILS with 'FXNewsSelfTest.mq5 no longer contains SELFTEST PASSED', exit 1. AFTER: 0 violations across 5 contracts, exit 0. contracts.py itself passes ruff check, ruff format, mypy --strict and bandit. Two mistakes in the checker were found by running it and fixed rather than loosened: it first demanded 'SELFTEST FAILED' in the shell gate, which only needs to recognise the passing verdict, and ruff flagged a nested if.
- **Notes:** Not BLOCKED and not partial: the checker covers every contract identified in the inventory's dependency graph. An unenforced checker would have been worthless, which is why it was wired into the gate in the same commit.

### F-016 (S2, ops) — No CI workflow: the three release gates are never run automatically

- **Status:** DONE  |  **Category:** deps  |  **Host:** node3  |  **Commit:** 2dbd184
- **Location:** `.github/`
- **Discovered by:** Phase B L0/L7
- **Evidence (before):**

  > .github contains only traffic.json; there is no workflow. Known-Limitations.md:7 lists this. The MQL5 compile gate cannot run on a stock GitHub runner, but census.py, shellcheck, ruff, mypy, the secret scan and the new contract test all can, and they are exactly the gates that catch the classes of defect this audit found.

- **Fix:** New .github/workflows/ci.yml runs the Linux-runnable gates on every push and pull request: census, contracts, ruff check, ruff format --check, mypy --strict, bandit, shellcheck, shfmt -d and a gitleaks scan of the full history (fetch-depth 0). Tool versions are pinned in the workflow and match AUDIT/environment.md. The workflow states in its own header, and the README and wiki now state, that the two MetaTrader gates are NOT covered and a green workflow is not a release gate.
- **Evidence (after):** All nine CI steps were run locally and pass (census, contracts, ruff check, ruff format --check, mypy --strict, bandit, shellcheck, shfmt -d, gitleaks). The pinned release downloads were verified reachable (HTTP 200 for shfmt 3.14.1 and gitleaks 8.30.1) and the three PyPI pins exist. The workflow YAML parses: 1 job, 12 steps. This task was only possible after F-026, F-027 and F-028 cleared the findings that would have made the first run red. HONEST ADDENDUM: the first real CI run FAILED at shell lint, which the local run had passed. The workflow pinned every tool except shellcheck and used the runner image's older release, which reports a trap-invoked function body as unreachable (SC2317) while shellcheck 0.11.0 does not. Filed as F-050 and fixed; the run after the fix is the evidence that matters, and the local pass alone was not sufficient evidence.
- **Notes:** Deliberately does not attempt the MQL5 gates in CI. Doing so would require installing Wine, Rosetta 2 and MetaTrader with broker history on a hosted runner, and a workflow that pretended to cover them would be worse than none. The unpinned shellcheck was a reproducibility defect in this task's own deliverable, not in the product, and CI caught it - which is the point of adding CI in the first place.

### F-017 (S2, validation) — MaxQuoteAgeSeconds and FullHoldScoreSeconds have no upper bound, so extreme values silently disable the freshness gate or make the HYBRID hold clause unreachable

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 79964e2
- **Location:** `FXNews.mq5:942,988-995`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > ValidateInputs checks only MaxQuoteAgeSeconds >= 1 (:942) and FullHoldScoreSeconds >= MinHoldSecondsForHighScore (:988-995). A very large MaxQuoteAgeSeconds disables quote-freshness enforcement (:4116, :5201); a very large FullHoldScoreSeconds drives hold_score below the 0.35 HYBRID clause (:6196) while weak_hold_cap (:4984) penalises every profile.

- **Fix:** MaxQuoteAgeSeconds and FullHoldScoreSeconds gained an upper bound of 3600 s (MAX_QUOTE_AGE_SECONDS, MAX_FULL_HOLD_SCORE_SECONDS), matching the other time-shaped inputs, so neither can be set large enough to make its gate vacuous. The two messages were extended to state the ceiling.
- **Evidence (after):** Two new self-test cases. BEFORE (new ceiling neutralised, syntax kept valid): 168 passed, 1 failed of 169, exit 1, and the failing case is the quote-age ceiling. AFTER: 169 passed, 0 failed of 169. Build 0/0; census 0; contracts 0.
- **Notes:** The first mutation attempt simply deleted the comparison and left 'if(... || )', which does not compile - recorded because a mutation that fails to build is not evidence of anything, so it was redone as a syntactically valid neutralisation.

### F-018 (S2, scoring) — single_feature_cap is applied without checking that the feature it measures was evaluated

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 3224f81
- **Location:** `FXNews.mq5:5026-5031`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':5026-5031' caps at 79 when execution.score < 0.78 or max(breakout.score, impulse.score) < 0.60, with no gate on the engine being enabled or the component being measured, while the very next cap block (:5033-5035) is explicitly gated and comments on that reasoning. With UseTechnicalBreakoutEngine=false and impulse unmeasured, an unmeasured 0 caps a strong score.

- **Fix:** Composer rules now require the engine to be enabled and measured. The synergy bonus takes breakout_confirms && impulse_confirms from (enabled && measured && score >= 0.45) for each engine; single_feature_cap compares the strongest reading among enabled-and-measured engines.
- **Evidence (after):** New self-test group 'composer engine gating'. BEFORE (both rules reverted to their ungated form): 2 assertions FAILED; RESULT 140 passed, 2 failed of 142; exit 1. AFTER: RESULT 142 passed, 0 failed of 142; exit 0. Historical regression after the shared-composer change: --validation exit 0 with 2589 boundaries, Signals=605, Avg score=74.7, PF=0.80 - no material change from the pre-change run (2589/601/74.7/0.79). Build 0/0; census 0 findings.
- **Notes:** Shares one root cause with F-019 and is committed with it as audit(F-018,F-019). Test-design note recorded: the first draft could not reach the cap's own '> 80' gate once the unmeasured engine's weight left the normaliser, so the assertion failed against the fixed code; the values were corrected so the test actually reaches the branch it targets.

### F-019 (S2, scoring) — The +0.05 synergy bonus is awarded on component scores without checking that either engine passed or was measured

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 3224f81
- **Location:** `FXNews.mq5:4958-4959`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':4958-4959' adds 0.05 to raw01 when breakout.score >= 0.45 and impulse.score >= 0.45. Nothing guarantees those scores came from measured components; the zeroing in ResetCompositeSignalScore makes values from a previous evaluation sticky only for measured paths, so the interaction with F-001/F-018 is a real risk.

- **Fix:** Composer rules now require the engine to be enabled and measured. The synergy bonus takes breakout_confirms && impulse_confirms from (enabled && measured && score >= 0.45) for each engine; single_feature_cap compares the strongest reading among enabled-and-measured engines.
- **Evidence (after):** New self-test group 'composer engine gating'. BEFORE (both rules reverted to their ungated form): 2 assertions FAILED; RESULT 140 passed, 2 failed of 142; exit 1. AFTER: RESULT 142 passed, 0 failed of 142; exit 0. Historical regression after the shared-composer change: --validation exit 0 with 2589 boundaries, Signals=605, Avg score=74.7, PF=0.80 - no material change from the pre-change run (2589/601/74.7/0.79). Build 0/0; census 0 findings.
- **Notes:** Shares one root cause with F-018 and is committed with it. Deliberate behaviour change: single-engine configurations lose the synergy bonus they previously received only because the absent second engine scored zero, which was imputed agreement. Documented in the commit message.

### F-021 (S2, dashboard) — WrapLabelText wraps report lines at 63 characters but SetDashboardRow re-clips them to the measured pixel limit, truncating the wrapped tail

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** f8ac04e
- **Location:** `FXNews.mq5:7482,7419`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > WrapLabelText's width is the character cap (:7482) while SetDashboardRow applies FitDashboardText and the pixel-derived limit (:7419, :7469). On a narrow chart the second line of an already-wrapped report loses its tail to an ellipsis rather than wrapping again.

- **Fix:** WrapLabelText takes the wrap width as a parameter and the report path passes DashboardTextLimit(), the same value SetDashboardRow clips to, so wrapping and clipping can no longer disagree. A non-positive width now returns no pieces instead of looping.
- **Evidence (after):** New assertion: the same text wrapped at width 20 yields more pieces than at 63, every piece fits 20 characters, and both the first and last word survive joining - so no text is dropped. BEFORE (wrapper ignoring the width, old constant, signature unchanged): 172 passed, 1 failed of 173, exit 1. AFTER: 173 passed, 0 failed of 173. Build 0/0; census 0; contracts 0.
- **Notes:** The tooltip already received the unwrapped line, so this was visible only on the label - which is why manual observation on a wide chart would not have shown it. Fixed by making the width explicit rather than by raising the character cap, which would only have moved the mismatch.

### F-023 (S2, tests) — No test could reach any ValidateInputs rejection path

- **Status:** DONE  |  **Category:** test  |  **Host:** node3  |  **Commit:** 853106a
- **Location:** `FXNews.mq5:930-1109`
- **Discovered by:** Phase B L6
- **Evidence (before):**

  > ValidateInputs contains roughly 20 distinct rejection blocks and is invoked only from OnInit (:809). The self-test does not call it at all, and SELFTEST mode still runs it, so an input-validation regression can only be observed by attaching the indicator interactively.

- **Fix:** The numeric validation was extracted into a pure ValidateInputsCore(const ValidationInputs&, string&) over a 55-field struct filled by CurrentValidationInputs(). ValidateInputs keeps the string-length and engine-enablement checks and maps a core failure to its message. All 20 guard blocks and their exact messages are preserved, verified by asserting the 18/2 split and the return counts during the splice.
- **Evidence (after):** New self-test group 'input validation': one baseline acceptance plus 18 single-field rejections with non-empty messages, covering every extracted guard. Removing any one guard fails its own case: the ATR-period guard and the F-017 quote-age ceiling were each removed in turn and each produced '168 passed, 1 failed of 169'. Assertions 149 -> 169. Build 0/0; census 0; contracts 0.
- **Notes:** The two checks that remain in ValidateInputs are the string-length check and the engine-enablement check; both are covered by the same reasoning but not by this group, which is stated rather than implied. The cross-field numeric rules (hold ordering, outcome ordering, baseline ordering, calendar ordering, rollover equality) ARE covered, because they moved with the numeric half.

### F-024 (S2, tooling) — build-macos.sh cannot distinguish 'Wine cannot execute' from 'the compiler produced no result line', and reports the wrong exit code

- **Status:** DONE  |  **Category:** bug  |  **Host:** node3  |  **Commit:** 970f8e5
- **Location:** `tools/build-macos.sh:47,116-120`
- **Discovered by:** Finding E-1
- **Evidence (before):**

  > The script checks only '[ -x "$WINE" ]' (:47), which is true for an x86_64 binary on an arm64 host without Rosetta. When Wine then fails to exec, the log is empty and the script exits 3 ('compiler produced no result line'), which the header documents as a compiler problem, not the environment problem (exit 2) it actually is. Observed on all four Macs.

- **Fix:** New tools/lib-mt5.sh holds the Wine path, the WINEPREFIX and the MetaTrader paths with mt5_configure and mt5_require_wine; both gate scripts source it. mt5_require_wine probes 'wine64 --version' and exits 2 naming the real cause (on arm64, the exact Rosetta 2 install command) instead of letting the failure surface later as a compiler result. FXNEWS_WINE and FXNEWS_WINEPREFIX allow a different install and make the checks themselves testable.
- **Evidence (after):** Scripts are the unit under test. BEFORE (probe removed): 'build: MetaEditor wrote no log (wine exit status 1)', exit 3 - the misleading compiler diagnosis, reproduced deliberately. AFTER: 'wine64 exists but cannot run ... needs Rosetta 2 ... sudo softwareupdate --install-rosetta --agree-to-license', exit 2; the same probe on selftest-macos.sh exits 2; a missing binary still reports 'wine64 not found' with exit 2 so the two failures stay distinguishable. No regression: build 0/0, full selftest 142 passed / 0 failed, explicit-source-path build works, census 0 findings, shellcheck clean on all three files. shellcheck's SC2034 on ME/TERMINAL was fixed by exporting the interface variables rather than with a disable directive.
- **Notes:** Shares the code being changed with F-014 and is committed with it. This is the repo-side defect behind environment blocker E-1, which was the audit's only S0.

### F-025 (S2, ops) — A live-looking GitHub PAT was supplied in plaintext and is present in the agent session transcript

- **Status:** BLOCKED  |  **Category:** unsafe  |  **Host:** node3  |  **Commit:** -
- **Location:** `session credential handling`
- **Discovered by:** Phase B L4
- **Evidence (before):**

  > The token authenticates as the repository owner with admin/push rights. It is not in the repository, not in git history (gitleaks and trufflehog both clean over all 78 commits), and was not committed. It is, however, recorded in the session transcript and was used once for authentication.

- **Notes:** Not a repository defect. Recommendation: rotate the token and use a scoped, short-lived credential stored in a secrets manager; this audit held no secret on disk except in a 0600 file outside the repository that is deleted at the end. Marked BLOCKED rather than DONE: the audit can prove the token never entered the repository or its history, but it cannot rotate it, and claiming the risk is closed without rotation would be false. This is the only open task in the ledger.
- **BLOCKED:** The GitHub PAT that authenticates as the repository owner was supplied in plaintext and is present in the agent session transcript. Rotating it is a GitHub account action; no repository change can perform it and the audit may not touch credentials on a live system. Tried: (1) confirmed the token is NOT in the repository, NOT in any of the 78 commits (gitleaks and trufflehog both clean over the full history) and was never committed - so there is nothing to purge from history; (2) confirmed it was used only for authenticated API reads and one push to the audit branch, never echoed into a log or a commit; (3) kept it outside the repository in ~/.fxnews/ mode 0600 for the duration. Options for a human, cheapest first: (1) revoke the token at github.com/settings/tokens and issue a replacement only if further audit work needs one - the audit branch is already pushed and needs nothing further; (2) if the token must stay live, scope it down to this repository and set an expiry; (3) run a secret scanner on the session transcript if it is retained anywhere, since that transcript is the only place the value exists. Also outstanding and related: ~/.fxnews/.fleet.secret and ~/.fxnews/.gh.token should be deleted once no further audit work needs them.

### F-048 (S2, historical) — The historical reports print the same generic interpretation whether or not higher score buckets actually produced better outcomes

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** da55cbc
- **Location:** `FXNews.mq5 (BuildAutotuneReport / BuildValidationReport interpretation lines)`
- **Discovered by:** Phase D - the first successful AUTOTUNE run in this audit
- **Evidence (before):**

  > The report prints 'Interpretation: score is a ranking metric. A useful score should show better R/PF in higher buckets.' unconditionally. On the 2026-09-15 AUTOTUNE run (GBPUSD, 2584 boundaries, 603 signals, 48.8 days) the observed bucket AvgR30 was <65 -0.068, 65-69 -0.105, 70-74 -0.075, 75-79 -0.237, 80-84 -0.110 - i.e. no monotone improvement, and the 75-79 bucket was the worst. All buckets were negative and no candidate beat CURRENT (improvement +0.000 on every metric). The report nevertheless ended with 'Recommended settings: ...' and the same generic interpretation, so an operator reading only the tail of the Journal would not learn that the ranking failed to hold on the very sample the recommendation came from.

- **Fix:** New pure EvaluateHistoricalRanking + AddHistoricalRankingVerdict report whether the sample supports the score's ranking claim, with the bucket numbers; both report builders call it and the generic Interpretation line no longer asserts the claim. Disclosure rather than suppression: Autotune stays advisory.
- **Evidence (after):** New self-test group 'ranking check' (4 assertions) including the exact falling profile the AUTOTUNE run produced. BEFORE (comparison inverted): 147 passed, 2 failed of 149, exit 1. AFTER: 149 passed, 0 failed of 149. New contract 'ranking-disclosure' pins both call sites; with the call removed from BuildAutotuneReport only, contracts fails with a precise message. End-to-end --validation exit 0 prints 'Ranking check: NOT SUPPORTED on this sample - the highest populated bucket (80+) averaged -0.095 R against -0.094 R in the lowest (60+), and only 3 of 4 adjacent pairs improved.' Build 0/0; census 0; contracts 0 across 6.
- **Notes:** The observation behind this finding stands and is material to a go-live decision: on this single-symbol 48.8-day sample the score showed no ranking edge and no candidate beat CURRENT. This task fixes the reporting, not the scoring; whether the score should rank better is a strategy question for a human, and the audit does not claim the score is wrong.

### F-049 (S2, tests) — Alert dispatch, correlation grouping and dashboard rendering still have no automated coverage

- **Status:** DONE  |  **Category:** test  |  **Host:** node3  |  **Commit:** b208a92
- **Location:** `FXNews.mq5 (UpdateAlertGroups, DispatchPendingAlerts, UpdateDashboard, BuildDiagnosticsLines)`
- **Discovered by:** Phase C - scope split out of F-008, which is complete for the lifecycle only
- **Evidence (before):**

  > F-008's original scope named four areas and CLAUDE.md records that all four were verified only by manual runtime observation. The lifecycle is now covered by the self-test group 'signal lifecycle'. Still uncovered: UpdateAlertGroups (group binding and leader election with hysteresis), DispatchPendingAlerts (the 10/minute, 2/scan and 30 s/profile rate limits, bounded retries, and the downgrade of a faded strong upgrade), and the dashboard (row composition to the 63-character budget, stale-row deletion, the ShowActiveSignalRows path, and the signal-history eviction dwell). Two of this audit's findings - F-011 (g_signal_history_dirty never cleared) and F-013 (every timeframe of a symbol shares a group) - live in that uncovered region.

- **Fix:** AlertRateLimitsAllow and GroupLeaderIndex extracted as pure functions and covered by seven assertions on their boundaries; UpdateAlertGroups now marks non-members with a sentinel so the election cannot pick one. The dashboard-rendering half is re-homed to F-051, not dropped.
- **Evidence (after):** BEFORE A (tie broken with >=): 189 passed, 2 failed of 191, exit 1. BEFORE B (60 s window dropped): 190 passed, 1 failed of 191, exit 1. AFTER: 191 passed, 0 failed of 191. Assertions 182 -> 191. Build 0/0; census 0; contracts 0/9.
- **Notes:** SCOPE CHANGE, recorded explicitly as the brief requires: F-049 originally named alert dispatch, correlation grouping AND dashboard rendering. The first two are covered here. Dashboard rendering (stale-row deletion, the ShowActiveSignalRows path, eviction dwell) needs a live chart and is re-homed to F-051 rather than considered closed. F-011's ordering invariant and F-021's wrap width are already covered - the first structurally by contracts.py, the second by the self-test. One assertion of mine failed first against correct code because the 'tie' case was not a tie; the test was fixed, not the code.

### F-050 (S2, tooling) — The CI workflow pinned every analysis tool except shellcheck, and the unpinned one failed the build

- **Status:** DONE  |  **Category:** deps  |  **Host:** node3 + GitHub runner  |  **Commit:** e4def3a
- **Location:** `.github/workflows/ci.yml; tools/selftest-macos.sh:89-96`
- **Discovered by:** the first real CI run of F-016 - found by CI, not by review
- **Evidence (before):**

  > Run 34980126739 (branch audit/2026-09-15) failed at the 'Shell lint' step with exit 1 while the identical command passed locally. The log names the cause: SC2317 (info) 'Command appears to be unreachable' on the three commands inside cleanup(), at tools/selftest-macos.sh lines 92-94. That function is reached only through 'trap cleanup EXIT', which the runner's older shellcheck (Ubuntu 24.04 provides 0.9.0) cannot see, so it reports the body as unreachable. Locally shellcheck is 0.11.0, which does not enable SC2317 by default and so passed. The workflow pinned ruff, mypy, bandit, shfmt and gitleaks but took shellcheck from the runner image, making the pipeline's result depend on the image version.

- **Fix:** Two changes, because there were two problems. (1) Reproducibility: shellcheck is now pinned via SHELLCHECK_VERSION 0.11.0 and installed from its release tarball, so a local pass means a CI pass. (2) The false positive itself is removed rather than suppressed: the cleanup function is inlined into the trap command, so no indirect invocation exists for a static analyser to mis-read, and the pre-existing '# shellcheck disable=SC2329' directive is deleted. No disable directive was added - the brief forbids weakening a check to make it pass, and shellcheck's own message says the finding is for indirect invocation.
- **Evidence (after):** shfmt -d clean and shellcheck 0.11.0 clean on all three scripts, with zero 'shellcheck disable' directives remaining in them except the two pre-existing SC1003 lexical notes. The pinned URL returns HTTP 200. The EXIT trap was verified to still clean up: after a full gate run the harness install directory, the harness script and the preset are all removed, and the gate reports 145 passed, 0 failed of 145. The workflow YAML still parses with six pinned versions.
- **Notes:** This is the failure mode F-016 exists to prevent, occurring in F-016's own deliverable within minutes of it being pushed, and caught by CI rather than by review. Recorded rather than quietly fixed, because it is also the strongest available evidence that the workflow does something.

### F-052 (S2, reporting) — The ranking evaluation could not say WHY the ranking failed - caps or the score

- **Status:** DONE  |  **Category:** tests  |  **Host:** node3  |  **Commit:** 6e59498
- **Location:** `FXNews.mq5 (historical bucket aggregation and ranking verdict)`
- **Discovered by:** F-048's open strategy question
- **Evidence (before):**

  > F-048 made the reports disclose that the ranking failed, but the report could only report the fact. It could not distinguish a score that does not rank outcomes from bucket membership that the cap ladder had contaminated, which was the actionable question and the one a hypothesis of mine had already guessed at.

- **Fix:** The samples are now bucketed twice from one recording: on the displayed score and on raw_score, the score before any cap applied. ScoreBucket{count, sum_R, capped_count} replaces the twelve loose bucket fields, so both bucketings share every consumer. The report prints both tables with cap incidence per bucket and a verdict on each, then states what their agreement or disagreement means, including which failure direction it implies. The ranking-disclosure contract pins the whole chain.
- **Evidence (after):** --validation (2589 boundaries, 605 signals): displayed NOT SUPPORTED (80+ -0.082 R vs 60+ -0.068 R), pre-cap NOT SUPPORTED (85+ -0.141 R vs 60+ -0.068 R); the report concludes both bucketings agree so it is a property of the score, not of the caps. --autotune (2584 boundaries): displayed NOT SUPPORTED (80+ -0.229 R vs 60+ -0.004 R), pre-cap NOT SUPPORTED (85+ -0.256 R vs 60+ -0.004 R), same conclusion. Fail-before: removing the pre-cap comparison fails the ranking-disclosure contract with a message naming F-048. Assertions 199 -> 204. Build 0/0; census 0; contracts 0/9.
- **Notes:** The cap incidence is new information in its own right: of 605 signals the pre-cap bucketing puts 198 in the 85+ band and EVERY one of them was capped down, and 150 of the 164 samples in the 80-84 displayed bucket are capped samples. The displayed score is dominated by penalised events in exactly the bands a reader would read as strongest.

### F-053 (S2, scoring) — MEASURED: the score does not rank 30m outcomes on the audit sample, and the caps are not the cause

- **Status:** DONE  |  **Category:** tests  |  **Host:** node3  |  **Commit:** 6e59498
- **Location:** `FXNews.mq5 (rank evaluation, measured not changed)`
- **Discovered by:** F-052's diagnostic, run on real broker history
- **Evidence (before):**

  > F-048 left the question open: on the 2026-09-15 runs the bucket average 30m R was negative in every bucket and no candidate beat CURRENT, but the audit could not say whether the score or the cap ladder was responsible.

- **Fix:** No code change: this is the measured answer, recorded because it is material to a go-live decision and because it disproves a hypothesis this audit had advanced.
- **Evidence (after):** Both bucketings fail in the same direction on both runs. VALIDATION: displayed 80+ -0.082 R vs 60+ -0.068 R; pre-cap 85+ -0.141 R vs 60+ -0.068 R. AUTOTUNE: displayed 80+ -0.229 R vs 60+ -0.004 R; pre-cap 85+ -0.256 R vs 60+ -0.004 R. The report states that both bucketings agree, so the failure is a property of the score rather than of the caps.
- **Notes:** DISPROVES A HYPOTHESIS OF MINE. I had suggested the 75-79 bucket looked inverted because events capped down by weak_hold_cap (74) and overextended_cap (75) concentrate there. That does not explain the result: bucketing on the score before ANY cap applied fails in the same direction and by a larger margin. The lead was wrong and is recorded as wrong. WHAT THIS DOES NOT ESTABLISH: that the score is broken. The product documents the score as an event-quality ranking, not a probability or a trade instruction, and nothing here tests event quality - only whether it ranks forward return. The measured statement is narrower: on one symbol over 48.8 days the score did not rank 30m outcomes, and the caps are not why. Whether the score SHOULD rank returns, and whether a longer or multi-symbol sample would show an edge this one cannot, remain human decisions. No weights were changed, because tuning them against the sample that exposed the failure is curve-fitting.

### F-010 (S3, historical) — The 85+ bucket in the historical report is unreachable (now empirically confirmed; the wiki already documents the empty bucket, so only the unannotated report row remains)

- **Status:** DONE  |  **Category:** dead  |  **Host:** node3  |  **Commit:** ba05024
- **Location:** `FXNews.mq5:2926-2930,3039`
- **Discovered by:** Phase B L1 + historical audit
- **Evidence (before):**

  > Flow is never populated in a historical run, so ComposeSignalScore always applies flow_absent_cap at 84.0 (:4969-4972); ScoreBucketFloor can therefore never return 85 for a historical score, AddHistoricalBucketStats never increments bucket85_count (:2926-2930), and the report row (:3039) always prints zero. Empirically confirmed on 2026-09-15: the AUTOTUNE report prints '85+ : 0 | +0.000 R' across 2584 evaluated boundaries and 603 signals.

- **Fix:** AddHistoricalBucketLines prints an explanation under the bucket table whenever the 85+ bucket is empty, stating that the historical model caps at 84 without a basket reading so the row is structurally unreachable. Both report builders use that function, so validation and autotune both carry it.
- **Evidence (after):** --validation exit 0 prints the zero row followed by the explanation line. Build 0/0; census 0; contracts 0/9; selftest 182/0.
- **Notes:** The wiki already documented the unreachable bucket; this closes the gap between the documentation and the report an operator actually reads. Disproof was not appropriate here - the zeros are real, the risk was their interpretation.

### F-012 (S3, scoring) — DISPROVED: the wick penalty's missing denominator entry is the correct arrangement

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** a7d2604
- **Location:** `FXNews.mq5:5330-5331`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':5330' subtracts wick_rejection_penalty*0.15 from 'weighted' but ':5331' adds only 0.17+0.17 to total_weight; the 0.15 never enters the denominator, so the penalty acts at an effective 0.15/0.95 weight outside the normaliser.

- **Fix:** No scoring change. The blend was extracted into the pure BlendBreakoutScore() and documented: the penalty is deducted after normalisation on purpose, so a flawless measured candle reaches 1.00 like every other component. Adding the 0.15 to total_weight, which the finding implied, would cap this component at 0.86 for every candle.
- **Evidence (after):** New self-test group 'breakout blend' (3 assertions) pins the ceiling. Applying the proposed fix (total_weight += 0.15) gives '170 passed, 2 failed of 172' with the ceiling assertions failing - the disproof. Current code: 172 passed, 0 failed of 172. Build 0/0; census 0; contracts 0.
- **Notes:** DISPROVED, like F-020, F-010 and F-001's original framing. The arithmetic was checked before the code was touched: 0.95/0.95 = 1.00 at zero penalty, and 0.95/1.10 = 0.86 if the 0.15 were folded in. Severity corrected S2 -> S3: the only real defect was legibility, and the disproof is now recorded in the code so it is not re-filed.

### F-013 (S3, dashboard) — DOMINANT FLOW's fallback group id is shared by every timeframe of a symbol - deliberate, not a defect

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 6485ce5
- **Location:** `FXNews.mq5:6325,6246`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > The comment at ':6318-6320' says a signal with no basket reading 'groups only with itself', but own_group is symbol + '_' + direction (:6325), which is identical across the timeframes of that symbol. CanDispatchAlert (:6246) admits only the group leader, so the remaining same-symbol timeframes stay pending for the life of the signal (:6642-6646).

- **Fix:** No behavioural change. own_group moved into a named OwnAlertGroup(symbol, direction) and the comment now states that same-symbol timeframes deliberately share a group, that the leader is elected by the highest DirectionSortScore, and that suppressed members show as '(N)' on the dashboard. The comment saying a signal 'groups only with itself' was the actual defect.
- **Evidence (after):** Four self-test assertions pin the identity, including that opposite directions on one symbol do NOT share a group. BEFORE (direction dropped from the id): 176 passed, 1 failed of 177, exit 1. AFTER: 177 passed, 0 failed of 177. Build 0/0; census 0; contracts 0. Verified that group_member_count is rendered as '(N)' at FXNews.mq5:8259, so suppressed members are visible.
- **Notes:** Severity S2 -> S3: the finding's premise ('stay pending for the life of the signal', implying a silent swallow) is false, because the group size is displayed. What remained was a wrong comment and no test, which is an S3 legibility defect. The one part worth keeping under test is that opposite directions never share a group, since that would let a long suppress a short.

### F-020 (S3, scoring) — RobustZ returning 0 on degenerate dispersion is the correct z, not an imputation (filed as a false-measured spread_z; disproved)

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 8cfbcf4
- **Location:** `FXNews.mq5:8266-8270,4661,5114-5116`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > RobustZ returns 0.0 when the denominator is below 1e-7 (:8269-8270). spread_z_available is set from median/session readiness alone (:5114) and spread_z is then a genuine-looking 0.0 (:5115-5116, :4661) which BlendExecutionScore weights at 0.14 (:5196).

- **Fix:** No code change. The finding was disproved by tracing the guarantees of the computation: AddSpreadSample inserts the current spread into the ring before UpdateSpreadStatistics runs, and RobustZ returns 0 only when mad == 0, which means every ring value including the current one equals the median. The numerator (value - median) is then exactly 0, so 0 is the exact z rather than a neutral stand-in, and awarding the term full credit is correct.
- **Evidence (after):** Proof by the computation's own invariants: FXNews.mq5 AddSpreadSample precedes UpdateSpreadStatistics in UpdateMarketData; RobustZ (FXNews.mq5:~8680) returns 0 only when MathMax(mad * MAD_TO_SIGMA, sigma_floor) <= 1e-7, and with sigma_floor = 0 (the spread call) that requires mad == 0, i.e. every ring sample equals the median. The same argument holds for BaselineZ on a zero-variance session baseline, where an EWMA mean equal to the value gives sd = 0 and (value - mean) = 0. The genuinely degenerate case that would matter - a value differing from a zero-dispersion centre - cannot occur, because the value is itself one of the samples that established the zero dispersion.
- **Notes:** SCOPE NOTE on the original finding, per the rule against closing a task by narrowing it. The filed claim was: 'RobustZ returns 0 for degenerate dispersion while spread_z_available stays true, so a genuine-looking 0.0 is weighted at 0.14 as if measured'. The availability half is accurate; the 'imputed neutral' half is false, because a 0 in that branch is the exact z. Severity drops from S2 to S3 and the residual is a documentation point: the RobustZ comment already explains the sigma_floor contract, but nothing states that a degenerate spread ring implies value == median. No defect means no fail-before test; the evidence is the invariant proof above. This is the third finding this audit has disproved rather than fixed, alongside F-001's original framing and F-010's. Disproved, so it has no code commit of its own; the recorded hash is the ledger commit that carries the disproof. Disproved, so it has no code commit of its own. No commit message names F-020 either, which the mechanical hash check exposed; the recorded hash is the earliest commit that changed the F-020 entry in AUDIT/ledger.json, found with 'git log -S' rather than guessed.

### F-022 (S3, dashboard) — BuildDiagnosticsLines recounts the dashboard objects on every scan, including the light path

- **Status:** DONE  |  **Category:** perf  |  **Host:** node3  |  **Commit:** c36e2e8
- **Location:** `FXNews.mq5:6817-6825,6747`
- **Discovered by:** Phase B L5 + dashboard audit
- **Evidence (before):**

  > 'UpdateActivityStatusLine' calls BuildDiagnosticsLines (:6821), which reaches CountDashboardObjects (:6747) and its 40 ObjectFind calls, identically to the full path. Tracker task 69 removed exactly this cost from the full path (:6769) but the lighter path still pays it on every scan.

- **Fix:** The dashboard object count is now refreshed once inside UpdateDashboard, immediately after it writes its rows, and read from g_dashboard_object_count elsewhere. UpdateDashboard is the only writer of those rows, so the reported value is unchanged and cannot drift.
- **Evidence (after):** New contract 'diagnostics-object-count' requires BuildDiagnosticsLines not to call CountDashboardObjects() directly. BEFORE (cache read reverted): contracts fails with that exact message, exit 1. AFTER: 0 violations across 7 contracts. Build 0/0; census 0; selftest 149/0.
- **Notes:** SEVERITY CORRECTED S2 -> S3 with the reasoning recorded: 40 ObjectFind calls at the default 2 s scan interval is about 20 calls per second and microseconds of work, so the original S2 performance rating overstated it. The change is kept on maintainability grounds - the work was unnecessary, not expensive - and it is measured here rather than assumed.

### F-026 (S3, tooling) — ruff F541: two f-strings without placeholders

- **Status:** DONE  |  **Category:** style  |  **Host:** node3  |  **Commit:** f5245d0
- **Location:** `tools/census.py:273,274`
- **Discovered by:** Phase B baseline (ruff check)
- **Evidence (before):**

  > ruff check tools/census.py -> 'Found 2 errors' (F541 at :273 and :274); both are auto-fixable by removing the extraneous f prefix.

- **Fix:** Removed the extraneous f prefix from the two adjacent regex fragments in census.py's declaration-detection pattern. The compiled pattern is identical; neither fragment interpolates anything.
- **Evidence (after):** ruff check tools/census.py clean. The change cannot alter detection because the prefix was inert, and that was verified rather than assumed: a synthetic probe file with three planted findings (write-only local, placeholder literal, uncalled function) is detected identically before and after - 3 findings, exit 1 - while the real source still reports 0 findings, exit 0. mypy --strict and bandit clean.
- **Notes:** Cleared as a prerequisite for F-016, which enforces ruff check in CI.

### F-027 (S3, tooling) — ruff format drift: the only Python file is not formatted to the formatter's standard

- **Status:** DONE  |  **Category:** style  |  **Host:** node3  |  **Commit:** 06638b2
- **Location:** `tools/census.py`
- **Discovered by:** Phase B baseline (ruff format --check)
- **Evidence (before):**

  > ruff format --check reports '1 file would be reformatted'.

- **Fix:** Applied `ruff format tools/census.py`. Formatting only, which is why the diff touches most of the file.
- **Evidence (after):** ruff format --check clean; ruff check clean; mypy --strict clean; bandit clean. Census behaviour unchanged: 3 findings on the synthetic probe, 0 on the real source.
- **Notes:** Cleared as a prerequisite for F-016, which enforces ruff format --check in CI.

### F-028 (S3, tooling) — shfmt drift in both shell scripts

- **Status:** DONE  |  **Category:** style  |  **Host:** node3  |  **Commit:** d80da2f
- **Location:** `tools/build-macos.sh; tools/selftest-macos.sh`
- **Discovered by:** Phase B baseline (shfmt -d)
- **Evidence (before):**

  > shfmt -d -i 2 -ci reports differences in both files: one-line brace guards expanded, case arms split, redirect spacing normalised.

- **Fix:** Applied `shfmt -i 2 -ci -w` to build-macos.sh and selftest-macos.sh; lib-mt5.sh was already conformant. Formatting only: no statement changed.
- **Evidence (after):** Reformatting executable gates is behaviour-risky, so every gate was run afterwards instead of trusting a whitespace-only diff. shfmt -d reports no drift; shellcheck clean on all three files; tools/contracts.py reports 0 violations, which also proves the patterns it parses out of selftest-macos.sh survived; build 0 errors / 0 warnings; full selftest 145 passed, 0 failed of 145.
- **Notes:** Cleared as a prerequisite for F-016, which enforces shfmt -d in CI.

### F-029 (S3, tooling) — tools/census-allow.txt is documented and defaulted to but does not exist

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 7a0d677
- **Location:** `tools/census.py:17,338`
- **Discovered by:** Phase B L0 + docs audit
- **Evidence (before):**

  > census.py's docstring and its argparse default reference tools/census-allow.txt, and the wiki Testing page tells users to put exceptions there. The file is absent. read_allow() tolerates absence, so this is a documentation gap, not a failure.

- **Fix:** tools/census-allow.txt now exists, empty, documenting the one-identifier-per-line format and the expectation that an entry is a written admission rather than a silencer. The path that census.py's usage text and the wiki's Testing page both reference now resolves.
- **Evidence (after):** The mechanism is proven, not assumed: against a scratch copy of the source with a deliberately dead identifier appended, census.py reports '[FINDING] unused-global: g_probe_dead_identifier' and exits 1 without an allow file, and '[allowed] ... 0 open finding(s), 1 allowed' with one naming it. Against the real source the committed file leaves the census at 0 findings, 0 allowed.
- **Notes:** The finding was a documentation/behaviour mismatch, so the fix had to be verified in both directions: that the file resolves, and that an entry in it actually changes the verdict.

### F-030 (S3, tooling) — .coverage is not ignored, so the coverage artifact required by the audit brief can be committed by accident

- **Status:** DONE  |  **Category:** style  |  **Host:** node3  |  **Commit:** e89c57c
- **Location:** `.gitignore`
- **Discovered by:** Phase B L0
- **Evidence (before):**

  > Running the mandated coverage measurement creates an untracked .coverage in the repository root; .gitignore lists *.ex5, *.log, *.out, *.tmp, *.bak and the MT5 runtime directories but not coverage data.

- **Fix:** .gitignore now lists .coverage, .coverage.* and htmlcov/ with the Python tool caches, so the artifact the brief's mandatory coverage run produces cannot be committed by accident.
- **Evidence (after):** BEFORE: 'git status --porcelain' listed '?? .coverage' (53 KB) and 'git check-ignore' exited 1. AFTER: 'git check-ignore -v .coverage' reports '.gitignore:12:.coverage  .coverage' and the working tree is clean with the artifact present on disk.

### F-031 (S3, repo) — One contributor appears under three different author identities

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 1ebce75
- **Location:** `git history`
- **Discovered by:** Phase B L0
- **Evidence (before):**

  > git log shows 26 commits as 'Andre Borchert <andreborchert@MacBook-AB.local>', 27 as '<andreborchert@macbook-ab.tail1c3b90.ts.net>', 25 as 'Pummelchen <0xa0b1@gmail.com>' and 1 as 'Pummelchen <andreborchert@MacBook-AB.local>'. Attribution and contributor statistics are split.

- **Fix:** A .mailmap maps the five author identities onto André Borchert <0xa0b1@gmail.com>. Display-only: no commit object changes, so no hash referenced by the ledger or the wiki is invalidated and the history is not rewritten.
- **Evidence (after):** BEFORE: 'git log --format=%an <%ae> | sort -u' reports 5 identities (node3; André Borchert at two addresses; Pummelchen at two). AFTER: 'git log --format=%aN <%aE> | sort -u' reports 1, with all 130 commits attributed to it.
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

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** f4a9387
- **Location:** `_fxnews-wiki/Testing-and-Validation.md:11,30`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > Line 11 states '117 assertions in eight groups'; line 30 states 'The result line prints the assertion total, so this page never has to.' Tracker task 110 asked for exactly the opposite.

- **Fix:** The wiki Testing and Architecture pages no longer hard-code the assertion total, honouring the same page's own promise that the result line prints it. The count changed twice during this audit (117 -> 123 -> 130) while regression tests were added, which is exactly the rot the hard-coded copies suffered. Committed in the wiki repository, not this one.
- **Evidence (after):** Wiki commit 'docs: stop hard-coding the self-test assertion total'; Testing-and-Validation.md:11 and Architecture.md:49 reworded.

### F-034 (S3, docs) — Known-Limitations calls all three gates macOS-only, but census.py is cross-platform

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 0e7c7f1
- **Location:** `_fxnews-wiki/Known-Limitations.md:7`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > ':7' states 'The three gates ... are macOS-only'. tools/census.py requires only Python 3.14 (verified running on macOS but with no platform-specific code), and Development-Guide.md:9-10 correctly pairs it with the macOS-only self-test.

- **Fix:** Corrected the wiki pages that stated things no longer true, and two that were already wrong: the four gates, which of them CI can run, the tool list, the self-test's coverage (the live signal lifecycle is now covered by the self-test) and the release process, which IS documented in Release-Checklist.md. Known-Limitations.md and Testing-and-Validation.md now distinguish the cross-platform gates from the macOS-only MetaTrader gates and say exactly what the CI workflow does and does not cover.
- **Evidence (after):** grep for 'three gates' / 'All three' / 'macOS-only' across the wiki returns no stale claim; Testing-and-Validation.md gained a 'What CI Covers, and What It Cannot' section and its gate table lists contracts.py; Home.md's project-structure paragraph no longer says there is no CI workflow.
- **Notes:** The original finding was that Known-Limitations called all three gates macOS-only although census.py is cross-platform. The correction grew to cover the CI workflow added by F-016 and the lifecycle coverage added by F-008, because all three make the same page wrong in the same way. Nothing was dropped: every stale statement in those pages was corrected, not just the one filed.

### F-035 (S3, docs) — Development-Guide both denies and documents the release process, and lists 'test' among commands that do not exist

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 0e7c7f1
- **Location:** `_fxnews-wiki/Development-Guide.md:23`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > ':23' says 'there is no repository-local install, lint, typecheck, format, test, migration, Docker, or deployment command' and 'The release and distribution process is not currently documented', while Release-Checklist.md exists and the same page describes the census and self-test gates as commands.

- **Fix:** Corrected the wiki pages that stated things no longer true, and two that were already wrong: the four gates, which of them CI can run, the tool list, the self-test's coverage (the live signal lifecycle is now covered by the self-test) and the release process, which IS documented in Release-Checklist.md. Development-Guide.md no longer claims there is no lint/typecheck/format/test command while describing the gates two lines above, and no longer says the release process is undocumented while linking to the Release Checklist.
- **Evidence (after):** Development-Guide.md:23 rewritten; the page now names the four gates, says which are cross-platform, and points at Release-Checklist.md for the release sequence.
- **Notes:** Shares the wiki commit with F-034; both are pure documentation corrections in the same repository.

### F-036 (S3, docs) — The tracker describes itself as open tasks and known bugs while showing 120/120 done, and its line-number baseline still says version 2.3

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 7de7c62
- **Location:** `_fxnews-wiki/Project-Tracker.md:3,7,9`
- **Discovered by:** Phase B docs audit
- **Evidence (before):**

  > ':3' calls the page 'Open tasks and known bugs'; ':7' records 'Progress: 120 of 120 done'; ':9' states line numbers refer to commit 9069ca3 (version 2.3) although the page was rewritten for 3.0.

- **Fix:** The Project-Tracker header no longer describes the page as 'open tasks and known bugs' beneath a stale '120 of 120 done' line and a 2.3 line-number baseline. It now separates the finished 2026-09-13 audit from the current one, points at AUDIT/ledger.json as the authoritative count, adds Blocked to the status list and contracts.py to the done criteria, and states which commit the line numbers refer to.
- **Evidence (after):** The wiki page header reads as above; the generated audit section beneath it is unchanged and still produced from AUDIT/ledger.json.
- **Notes:** The stale lines were hand-written outside the generated section, which is why regenerating the tracker never touched them.

### F-037 (S3, docs) — The documented version-bump procedure requires a deployment clone at MQL5/Indicators/FXNews/ that does not exist on this machine

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 7de7c62
- **Location:** `CLAUDE.md:24-30`
- **Discovered by:** Phase B L0
- **Evidence (before):**

  > CLAUDE.md step 2 tells the developer to fetch and reset a separate clone at MQL5/Indicators/FXNews/. That directory does not exist in the WINEPREFIX and no FXNews artifact exists anywhere in the MT5 tree; 'build-macos.sh --install' would create it.

- **Fix:** CLAUDE.md's version-bump step no longer tells the developer to fetch and reset a clone that may not exist. It states that the directory is the terminal's separate clone, that it is not guaranteed to exist, how to bootstrap it with git clone, and explicitly that --install creates the directory and verifies the copy but does NOT clone.
- **Evidence (after):** Verified against the machine rather than assumed, after F-045's --install created the directory: ls -a shows only FXNews.ex5 and no .git, and 'git -C .../FXNews fetch' reports 'fatal: not a git repository' - so the documented fetch/reset step would indeed have failed there.
- **Notes:** The finding was filed when the directory did not exist at all; F-045 then created it as an empty directory, which turns the missing-clone problem into a subtler one - a binary with no source beside it.

### F-038 (S3, scoring) — Unreachable guard: total_weight can never be zero

- **Status:** DONE  |  **Category:** dead  |  **Host:** node3  |  **Commit:** 0fa4053
- **Location:** `FXNews.mq5:4948-4949`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > execution_weight (0.18) and regime_weight (0.14) are unconditional (:4941, :4943), so total_weight is at least 0.32 and the 'if(total_weight <= 0.0) total_weight = 1.0' branch at ':4948-4949' cannot be taken.

- **Fix:** Documented why the guard is retained instead of deleted: execution_weight (0.18) and regime_weight (0.14) are unconditional, so the sum cannot be zero, and deleting the guard would turn a silent rescale into a silent divide-by-zero if a later edit made both conditional.
- **Evidence (after):** No observable test exists for this branch and none is claimed: the branch cannot be taken, so nothing can fail before or pass after. The invariant it protects is covered by the composer's existing 'all optional components unmeasured' assertions, which exercise the smallest total_weight.
- **Notes:** Recorded as documentation-only with the reason deletion was rejected, because deleting dead defensive code is the obvious move and is the riskier one here.

### F-039 (S3, docs) — The age_free_score field comment understates what the value excludes

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** 9774ca7
- **Location:** `FXNews.mq5:396,5012-5041`
- **Discovered by:** Phase B L3 + scoring agent
- **Evidence (before):**

  > ':396' documents age_free_score as 'displayed score before the event-age caps', but it is captured at ':5012' before the calendar-uncertainty, single-feature and elite caps are also applied (:5023-5042).

- **Fix:** The age_free_score field comment now names every ceiling it precedes - age, calendar uncertainty, single-feature, elite and absolute - instead of only the event-age caps.
- **Evidence (after):** New contract 'score-ceiling-reasons' checks the documented claim mechanically: it fails if the capture moves after the event-age caps. Verified by moving it after late_event_cap, which produces the F-039 violation, exit 1. Restored: 0 violations across 8 contracts.
- **Notes:** A comment cannot be tested for truth, but the claim it makes can: that age_free_score is captured before the age caps is structural, and the contract asserts exactly that.

### F-040 (S3, logic) — The hard 95 ceiling is the only cap that records no reason string

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** cf97ba3
- **Location:** `FXNews.mq5:5044-5045`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > Every other cap goes through ApplyScoreCap and appends to cap_reasons (:4963-5042); the final 'if(capped > 95.0) capped = 95.0' at ':5044-5045' bypasses the helper, so a 95 score's cap_reasons does not mention the ceiling.

- **Fix:** The absolute 95 ceiling now runs through ApplyScoreCap with the reason 'absolute_score_ceiling', so it records a reason like every other ceiling. Behaviour below the cap is unchanged because ApplyScoreCap only appends when it binds.
- **Evidence (after):** BEFORE (silent clamp restored): contracts reports two violations naming F-040, exit 1. AFTER: 0 violations across 8 contracts. Build 0/0; census 0; selftest 177 passed, 0 failed of 177.
- **Notes:** The contract's first pattern was wrong ('double ComposeSignalScore' for a void function) and reported the function missing against correct code; the pattern was corrected rather than the check loosened.

### F-041 (S3, logic) — The BAR_CLOSE confirmation rule was unreachable by any test, and its threshold clause is redundant

- **Status:** DONE  |  **Category:** dead  |  **Host:** node3  |  **Commit:** 38fe455
- **Location:** `FXNews.mq5:6187,6410`
- **Discovered by:** Phase B L2 + dashboard audit
- **Evidence (before):**

  > ':6187' re-tests MeetsThreshold(score, MinDisplayConfidence) although every call site already gated on it (:6410 and the candidate path), so the branch is unreachable in the failing direction.

- **Fix:** The rule moved into a pure BarCloseConfirms(candidate_bar_time, trigger_bar_time, score, min_confidence), which was the only way to exercise it because SignalConfirmationMode is an input variable. The threshold clause is kept: it is redundant at both call sites (PickBestDirection already required MinDisplayConfidence, and the reversal path requires the stronger StrongAlertConfidence) but it is what makes the branch mean 'still valid at the bar close' on its own terms, and it fails safe.
- **Evidence (after):** Four assertions, the load-bearing one being that a surviving candidate below the floor does NOT confirm. BEFORE (threshold clause dropped): 180 passed, 1 failed of 181, exit 1. AFTER: 181 passed, 0 failed of 181. Build 0/0; census 0; contracts 0/9.
- **Notes:** The commit hash was first recorded as e0f7cbf, which does not exist on the branch; it is 38fe455, taken from git log rather than from memory.

### F-042 (S3, dashboard) — PushSignalHistory's shift loop copies empty slots when the list is not yet full

- **Status:** DONE  |  **Category:** perf  |  **Host:** node3  |  **Commit:** 09e1c5e
- **Location:** `FXNews.mq5:7261-7262`
- **Discovered by:** Phase B L5 + dashboard audit
- **Evidence (before):**

  > ':7261-7262' shifts from evict down to index 1 even when evict is far beyond the used count, copying unused entries. Correct but wasted work; the loop should start at min(evict, count).

- **Fix:** PushSignalHistory now finds the first unused slot from the front, so the eviction index is the list's own end when there is a free one, and the tail dwell scan runs only when the list is full and something must be dropped. Used entries shift by one either way, so the resulting list is unchanged.
- **Evidence (after):** New contract 'signal-history-shift' pins the property that is checkable. BEFORE (free-slot search removed): contracts fails with the F-042 message, exit 1. AFTER: 0 violations across 9 contracts. Stated limit: the resulting list is identical before and after, so no behavioural test can distinguish them - which is why the finding survived review.
- **Notes:** The shift copied empty slots into empty slots; the waste was real but invisible in state. Closed with a structural contract because a behavioural one is impossible, and that impossibility is recorded rather than papered over.

### F-043 (S3, logic) — DISPROVED: SmoothStep's edge re-orientation is a tested fix for a pre-1.4 defect

- **Status:** DONE  |  **Category:** logic  |  **Host:** node3  |  **Commit:** 2868784
- **Location:** `FXNews.mq5:8198-8208`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > ':8198-8208' swaps the edges when edge0 > edge1. Every caller derives edges from validated inputs today, but a future reversed bound would silently invert a scoring ramp rather than failing — the exact defect class the self-test was created for.

- **Fix:** No behavioural change. The comment now records that reversed edges are oriented on purpose, that every reversed call in the file is a self-test assertion pinning it, and that this was filed, examined and found correct.
- **Evidence (after):** Grepping every call site found exactly three reversed literal pairs, all of them self-test assertions (SmoothStep(0.50,0.35,0.20) < ...(0.60), and ...(1.0,0.0,0.5) == 0.5). No production caller passes reversed edges, and the adjacent comment already recorded that before the fix the ramp ran backwards and scored 1.00 for moves against the signal. Build 0/0; census 0; contracts 0/9; selftest 177/0.
- **Notes:** DISPROVED, like F-012, F-013, F-020, F-010 and F-001's original framing. The proposed change would have re-introduced a severe scoring inversion, which is the opposite of a fix.

### F-044 (S3, docs) — The ATR definition (simple mean of true range, not Wilder smoothing) is undocumented

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** aee3e23
- **Location:** `FXNews.mq5:4401-4425`
- **Discovered by:** Phase B L3 + scoring audit
- **Evidence (before):**

  > CalculateATRFromRates returns the arithmetic mean of true range over ATRPeriod. No wiki page states whether ATR is Wilder-smoothed; Configuration.md and Signal-Logic.md both discuss ATR thresholds without defining it.

- **Fix:** Both ATR sites now document the definition: a simple arithmetic mean of the last period true ranges, not Wilder smoothing, so it deliberately differs from MT5's ATR indicator; and the live and historical paths must share it so a historical score describes live behaviour on the same bars.
- **Evidence (after):** New self-test group 'atr definition' on a three-bar series with true ranges 14, 5, 4: simple mean 7.667 against Wilder 8.667. BEFORE (genuine Wilder recursion substituted): 181 passed, 1 failed of 182, exit 1. AFTER: 182 passed, 0 failed. Build 0/0; census 0; contracts 0/9.
- **Notes:** The first mutation seeded the recursion with the mean, making it a fixed point, so it changed nothing and proved nothing; it was replaced with a genuine Wilder seeding rather than reported as evidence.

### F-045 (S3, tooling) — --install creates the destination directory silently and never verifies the terminal can load the binary

- **Status:** DONE  |  **Category:** docs  |  **Host:** node3  |  **Commit:** e28ad4b
- **Location:** `tools/build-macos.sh:150-156`
- **Discovered by:** Phase B L7
- **Evidence (before):**

  > ':152' runs 'mkdir -p "$DEST"' and ':153' copies the .ex5, printing success. CLAUDE.md warns that a stale .ex5 beside a current .mq5 is a trap because MT5 loads the binary, but nothing in the workflow reports which one the terminal will see.

- **Fix:** --install now reports whether the target directory existed or was created, compares the installed file's length with the source's and exits 2 on a mismatch, and warns when a stale .mq5 sits beside the fresh .ex5. The size mismatch message names both lengths.
- **Evidence (after):** Against the real prefix: first run 'install target absent, creating: ...' then 'installed FXNews.ex5 ... (246424 bytes, verified)' with the installed file measuring 246424 bytes against a 246424-byte source; second run reports 'install target exists' and verifies again. The size guard was reproduced in isolation with a 3-byte file against a 10-byte source and reports REJECTED, exiting 2. shfmt -d and shellcheck tools/*.sh are clean.
- **Notes:** shellcheck on a SINGLE file reports SC1091 because it cannot follow the lib-mt5.sh source; that is an artefact of the invocation, not a regression - it appears twice on the previous version under the same call - and the gate's own invocation over tools/*.sh is clean.

### F-051 (S3, testing) — Dashboard row rendering and the signal-history eviction dwell still have no automated coverage

- **Status:** DONE  |  **Category:** tests  |  **Host:** None  |  **Commit:** 0a39984
- **Location:** `FXNews.mq5 (UpdateDashboard, SetDashboardRow, DeleteDashboardRowsFrom)`
- **Discovered by:** scope re-homed from F-049, as the audit brief requires
- **Evidence (before):**

  > Re-homed from F-049, which named alert dispatch, correlation grouping and dashboard rendering together. The first two are now covered by the 'alert dispatch' self-test group. Still uncovered: stale-row deletion when the dashboard shrinks, the ShowActiveSignalRows path, and the signal-history eviction dwell introduced with F-042. Rendering needs a live chart, which is why the whole area was manual-only. F-011's refresh-ordering invariant is already pinned structurally by tools/contracts.py (dashboard-refresh) and F-021's wrap width by the self-test, so this task is the remainder, not the whole area.

- **Fix:** Dashboard row creation, the label budget and stale-row deletion are covered by running against the harness's real chart; the history eviction rule moved into a pure SignalHistoryEvictionSlot with four boundary assertions. The F-042 contract was repointed at the new function.
- **Evidence (after):** BEFORE A (deletion off-by-one): 197 passed, 2 failed of 199, exit 1. BEFORE B (dwell ignored): 198 passed, 1 failed of 199, exit 1. AFTER: 199 passed, 0 failed of 199. Assertions 191 -> 199. Build 0/0; census 0; contracts 0/9. SECOND PASS: new self-test group 'active signal rows', 14 assertions, three mutations each failing exactly one assertion (217/1 of 218). Assertions 204 -> 218.
- **Notes:** The ShowActiveSignalRows path is not covered by a new test and the ledger says so: it needs a running scan. Its defect-prone property - refresh before the branch on display mode - is already pinned structurally by the dashboard-refresh contract added with F-011. Two fixtures of mine failed first against correct code (a non-tie 'tie' in F-049, and a non-monotonic eviction fixture here); both were test errors and are recorded in the tests. RESOLVED PROPERLY in a second pass: the two decisions the branch makes are now pure functions with fourteen assertions and three separate fail-before mutations, so the gap this entry recorded is closed for selection and ordering. Still uncovered and stated as such: the row text and tooltip builders, which read profile globals and are exercised only by rendering.
