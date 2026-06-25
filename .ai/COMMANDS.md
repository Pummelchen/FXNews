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

# Commands and Workflows

## Repository-local command status

No repository-local package manager scripts, automated build commands, automated test commands, Docker setup, database migration tooling, or CI workflow were detected during bootstrap inspection.

Evidence:
- `FXNews.mq5`
- `README.md`
- `.gitignore`
- checked common paths: `package.json`, `pyproject.toml`, `Dockerfile`, `.github/workflows/ci.yml`

## Install / setup

| Task | Workflow |
|---|---|
| Install runtime | Install MetaTrader 5 with MetaEditor. Exact version/build is not declared in the repository. |
| Place source | Copy or open `FXNews.mq5` in the MT5/MQL5 Indicators workspace. |
| Compile | Use MetaEditor compile action for `FXNews.mq5`. The ignored output artifact is expected to be `*.ex5`. |
| Run | Attach compiled indicator to an MT5 chart in a demo/non-production environment. |

## Build

No shell command was found. Manual workflow:

```text
MetaEditor -> open FXNews.mq5 -> Compile
```

Expected result:

- compile succeeds without errors;
- `FXNews.ex5` or equivalent compiled artifact is created locally;
- compiled artifact remains uncommitted because `.gitignore` excludes `*.ex5`.

## Local development

Suggested safe workflow:

1. Edit `FXNews.mq5` or docs.
2. For source edits, compile in MetaEditor.
3. Attach to an MT5 chart in a demo/non-production account.
4. Check dashboard status line, recent message rows, tooltips, and MT5 Journal output when debug or historical mode is enabled.
5. Do not commit local MT5 artifacts.

## Test

No automated test harness was detected. Use the manual validation matrix in `.ai/TESTING.md`.

Focused runtime checks:

| Change area | Focused validation |
|---|---|
| Inputs/startup | Compile, attach indicator, verify invalid inputs fail cleanly and valid defaults initialize. |
| Symbol parsing | Test symbol list variants and broker suffix/prefix behavior. |
| Timeframe parsing | Test supported tokens: `M1`, `M5`, `M15`, `M30`, `H1`, `H4`, `H8`, `H12`, `D1`. |
| Scoring | Enable `DebugScoreBreakdown` and `DebugPrintToJournal` only in a safe local/demo setting. |
| Dashboard | Resize chart and confirm text truncation/layout remains readable. |
| Alerts | Enable sound or push options deliberately and verify no duplicate alert storms. |
| Historical mode | Run `FXNEWS_MODE_VALIDATION`; inspect MT5 Journal report. |
| Autotune | Run `FXNEWS_MODE_AUTOTUNE`; inspect Journal and verify LIVE continuation behavior. |

## Lint / typecheck / format

No repository-local lint, typecheck, or formatter command was detected. Treat MetaEditor compile as the minimum syntax/type validation for MQL5 source changes.

## Database migrations

Not applicable from current repository contents. No database, schema, migration tool, or persistence layer was detected.

## Docker / local services

Not applicable from current repository contents. No Dockerfile or compose file was detected.

## Release / deploy

No release automation was detected. Any release workflow should be confirmed by a maintainer before documenting it as policy.

## Safe docs validation when a local clone is available

- Confirm only README/onboarding files changed.
- Validate `.ai/MANIFEST.json` as JSON.
- Check README links point to local files that exist.
- Check generated Markdown links are not obviously broken.
- Check no secret-like values or access tokens were written.
- Check no new vendor/model-specific AI instruction file was created.
- Do not run destructive or production-facing commands.
