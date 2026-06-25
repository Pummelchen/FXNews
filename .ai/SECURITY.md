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

# Security and Safety Notes

## Current security posture from repository files

FXNews is documented and implemented as a chart-only MetaTrader 5 custom indicator. The README states that it never opens, closes, modifies, or manages trades and that it uses no WebRequest, DLLs, external feeds, CSV logging, or disk output. The source description also says no trade execution and no disk I/O.

Evidence:
- `README.md`
- `FXNews.mq5`
- `.gitignore`

## Auth/authz model

No application authentication or authorization system was detected. This is not a web/server application. Runtime access is controlled by the local MT5 terminal/account environment.

## Secrets handling

No secret files or environment variable contract were detected. Do not add tokens, credentials, account IDs, broker passwords, API keys, or access tokens to source, generated docs, comments, reports, or manifests.

## Security-sensitive capabilities

| Capability | Current status | AI-agent rule |
|---|---|---|
| Trade execution/order management | Not part of current documented scope. | Do not add without explicit human approval. |
| Disk output/logging | README says no disk output; source diagnostics use chart/Journals. | Do not add file writes without approval and docs update. |
| Web requests/external feeds | README says no WebRequest/external feeds. | Do not add external network calls without approval. |
| DLL imports | README says no DLLs. | Do not add DLL imports without approval. |
| Push notifications | Optional through `EnablePushNotification` and `SendNotification`. | Keep opt-in; avoid sensitive text. |
| Sound alerts | Optional through `EnableSoundAlert` and `PlaySound`. | Keep opt-in; validate locally. |
| MT5 economic calendar | Optional calendar context through MT5 APIs. | Document behavior and broker/terminal availability limits. |
| Financial signal language | Scores are rankings, not win probabilities or instructions. | Avoid advisory/promissory wording. |

## Sensitive paths and artifacts

| Path/pattern | Reason |
|---|---|
| `FXNews.mq5` | Product behavior, alerting, signal scoring, and safety boundaries live here. |
| `.ai/MANIFEST.json` | Machine-readable docs metadata; must not contain secrets. |
| `*.ex5` | Compiled binary artifact; ignored and should not be committed. |
| `MQL5/Logs/`, `MQL5/Profiles/`, `MQL5/Tester/` | Local terminal/tester data; ignored and should not be committed. |

## Review triggers

Require human review before merging changes that:

- add or call trading/order/account functions;
- introduce file writes, CSV/report files, or persistent settings output;
- introduce WebRequest, DLL imports, or external data feeds;
- change push-notification defaults or alert frequency;
- reframe scanner scores as recommendations or probabilities;
- materially alter historical validation/autotune parameter application;
- move scanning from timer-based flow to a different runtime callback.

## Safe validation for security-sensitive edits

- Compile first.
- Use a demo/non-production account.
- Keep alerts disabled unless alert behavior is the change under test.
- Inspect MT5 Journal for unexpected output.
- Confirm no ignored artifacts are staged.
- Confirm no secret-like values were written to docs/source.

## Known unknowns

- Exact MT5/MetaEditor build version is not declared.
- No automated security scanning workflow is present.
- Wiki content referenced by README was not available as versioned repository content during this bootstrap scan.
