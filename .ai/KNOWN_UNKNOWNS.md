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

# Known Unknowns and Review Notes

## Unknowns from bootstrap

| Label | Item | Why it matters | Suggested action |
|---|---|---|---|
| unknown | Exact MetaTrader 5 / MetaEditor build version is not declared. | Compile/runtime behavior can vary by terminal build. | Maintainer can document supported build range. |
| unknown | No repository-local automated test harness was found. | Future agents cannot run automated tests from the repo. | Add documented compile/test workflow if available. |
| unknown | No CI workflow was found. | PR validation expectations are manual. | Add CI only if safe and practical for MQL5. |
| unknown | GitHub Wiki content is linked from README but not versioned in the inspected tree. | Setup/operations details may live outside this repository checkout. | Keep critical source-grounded setup facts in repo docs if they affect code changes. |
| unknown | Release/distribution process is not declared in repo files. | Future agents should not invent deployment/release steps. | Document release workflow if needed. |
| unknown | Supported brokers/symbol suffix conventions are not documented in repo files. | `FindBrokerSymbolMatch()` tries to resolve symbols, but real broker coverage is environment-specific. | Test with target broker symbols before changing symbol logic. |

## Conflicts detected

No source/doc conflicts were detected during bootstrap. If future refreshes find conflicts, prefer current source and build/runtime config over older docs.

## Things an AI should ask a human before changing

- Adding trade execution, order management, or account operations.
- Adding disk output, CSV/log files, or persistent parameter files.
- Adding WebRequest, DLL imports, external feeds, or credentials.
- Changing default alert behavior or enabling push notifications by default.
- Rewording scores as trade recommendations, probabilities, or guaranteed outcomes.
- Refactoring the single-file MQL5 implementation into multiple files.
- Changing release/distribution policy.

## Obsolete or model-specific AI files

No prior model-specific AI instruction files were found during bootstrap checks of known locations. No migration, deprecation, preservation, or removal was performed.

## Validation limitations of this generation

- Direct local clone from the execution container was unavailable because the container could not resolve `github.com`; repository inspection and writes used the GitHub connector.
- MetaEditor compile was not run because no MT5/MetaEditor runtime is available in the execution environment.
- MT5 runtime, historical validation, and alert behavior were not executed.
- Generated docs are source-grounded but should be refreshed after meaningful source or workflow changes.
