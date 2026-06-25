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

# Generic AI Agent Instructions for FXNews

## Start every new session this way

1. Read `AI_INDEX.md` first.
2. Read `.ai/START_HERE.md`, `.ai/PROJECT_MAP.md`, and `.ai/ARCHITECTURE.md` before editing.
3. Read `.ai/COMMANDS.md`, `.ai/TESTING.md`, and `.ai/SECURITY.md` before proposing validation.
4. Inspect the current source files you will edit. These generated docs are guidance, not a substitute for current code.

## Repository-specific ground rules

- This repository currently centers on `FXNews.mq5`, a MetaTrader 5 MQL5 custom indicator.
- Do not modify product/source code unless the user explicitly asks for an implementation change. Onboarding refreshes should touch only README/AI documentation/metadata.
- Treat `README.md`, `FXNews.mq5`, and `.gitignore` as the source-grounded baseline for this onboarding set.
- When repo facts conflict, trust current source code first, then build/runtime configuration, then README/docs, then inference.
- Clearly separate verified facts, assumptions, inferences, unknowns, and risks.
- Do not create vendor/model-specific instruction files.

## Planning changes

Before editing `FXNews.mq5`, produce a short plan that names:

- the exact behavior being changed;
- source functions or constants likely affected;
- validation steps available in MetaEditor/MT5;
- any financial, alerting, performance, or chart-output risks.

Keep the single-file structure in mind. `FXNews.mq5` contains initialization, scanning, scoring, state, dashboard, alerts, calendar context, and historical validation/autotune logic. Avoid broad rewrites when a targeted function-level change is enough.

## Avoid hallucinating

Use the following labels in notes and PR summaries when appropriate:

- `verified`: directly supported by `FXNews.mq5`, `README.md`, `.gitignore`, or generated manifest.
- `inferred`: likely from project type or code shape but not explicitly declared.
- `unknown`: not verifiable from the repository.
- `conflicting`: current files disagree.
- `needs_human_review`: a maintainer should decide.

Never claim automated tests, CI, package manager scripts, Docker support, database migrations, or deployment automation unless current files prove they exist.

## Coding conventions to preserve

- MQL5 source currently uses global input declarations, enums, structs, helper functions, and chart label objects in one file.
- Preserve `#property strict`, indicator chart-window behavior, and no-plots behavior unless intentionally changing the product.
- Keep scanner score language distinct from guaranteed trade outcomes.
- Preserve current chart-only/no-trade-management posture unless a human explicitly requests otherwise.
- Preserve bounded timer-path work and avoid unbounded loops in `OnTimer()` and `ScanAll()`.
- Do not commit MT5 generated artifacts such as `*.ex5`, logs, tester output, or profiles.

## Validation expectations

There is no repository-local automated test command detected. Minimum validation for code changes should be:

1. Compile `FXNews.mq5` in MetaEditor and record compiler result.
2. Attach the indicator to an MT5 chart in a demo/non-production environment.
3. Check dashboard status line and recent signal/history formatting.
4. If changing historical mode, run `FXNEWS_MODE_VALIDATION` or `FXNEWS_MODE_AUTOTUNE` and inspect MT5 Journal output.
5. If changing alerts, validate `EnableSoundAlert` and/or `EnablePushNotification` behavior safely.

For docs-only changes, validate JSON manifest syntax, README links, and no accidental model-specific file creation.

## Safety rules

- Do not add trade execution, order management, account operations, WebRequest, DLL imports, credential handling, or disk output without explicit human approval.
- Do not introduce secrets into docs, comments, manifests, or source.
- Do not print, store, or commit access tokens.
- Be conservative with financial wording: signal scores are scanner rankings, not trade recommendations or probabilities.
- Mark any behavior involving alerts, calendar context, or future file/network output as security-sensitive.

## Commit and PR expectations

- Keep docs-only AI-onboarding changes separate from product code changes.
- In PR descriptions, list changed files and validation actually performed.
- Do not claim MetaEditor compile/runtime validation unless it was actually performed.
- Refresh these onboarding files after meaningful changes to `FXNews.mq5`, README/docs, validation workflow, packaging, security boundaries, or repository structure.

## Refresh policy

Update the onboarding set when:

- `FXNews.mq5` changes in initialization, scoring, state, dashboard, alerts, calendar, or historical validation/autotune paths;
- README/wiki-facing setup guidance changes;
- any build/test/CI tooling is added;
- any security-sensitive capability is added;
- generated docs are older than the manifest policy or no longer match source.
