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

# Start Here for a Fresh AI Session

## Pasteable first-session prompt

```text
You are working in the FXNews repository. Start by reading AI_INDEX.md, AGENTS.md, .ai/PROJECT_MAP.md, .ai/ARCHITECTURE.md, .ai/COMMANDS.md, .ai/TESTING.md, and .ai/SECURITY.md. Then inspect the current source files relevant to the task, especially FXNews.mq5 before making any code edits.

Summarize your understanding using these labels: verified facts, assumptions, inferences, unknowns, and risks. Do not rely on prior chat history or external repo-learning websites. Treat the onboarding files as guidance only; current source code and repository config are the source of truth.

Before editing, produce a concise implementation plan naming the functions/files likely affected and the validation you can actually perform. Preserve the chart-only MT5 indicator boundary unless explicitly asked otherwise. Do not add trade execution, disk output, WebRequest, DLL imports, credentials, or model-specific instruction files. After editing, report changed files and validation actually run.
```

## Reading order

1. `AI_INDEX.md` — repository overview and task map.
2. `AGENTS.md` — generic operating rules.
3. `.ai/PROJECT_MAP.md` — file/module map.
4. `.ai/ARCHITECTURE.md` — runtime and data flows.
5. `.ai/COMPONENTS.md` — component cards for the single-file implementation.
6. `.ai/COMMANDS.md` — available manual workflows.
7. `.ai/TESTING.md` — validation expectations.
8. `.ai/SECURITY.md` — safety boundaries.
9. `.ai/KNOWN_UNKNOWNS.md` — unresolved facts and review notes.
10. Current source files for the specific task.

## How to summarize before editing

Use this compact shape:

```text
Verified facts:
- ...
Assumptions:
- ...
Inferences:
- ...
Unknowns / risks:
- ...
Plan:
- ...
Validation:
- ...
```

## Context management

- Do not load every generated document into active context if the task is narrow.
- For source edits, load the relevant `FXNews.mq5` functions around the change and any adjacent helpers.
- For docs-only updates, load README, `AI_INDEX.md`, `AGENTS.md`, `.ai/MANIFEST.json`, and the specific `.ai/*` files being changed.
- Prefer source references by path and function name over long pasted snippets.

## Rules for uncertainty

- If a command, workflow, or runtime version is not in the repo, mark it unknown instead of guessing.
- If README/docs and code disagree, trust current code first and record the disagreement in `.ai/KNOWN_UNKNOWNS.md`.
- If a change may alter chart-only/no-trade/no-disk/no-external-request behavior, ask for explicit human approval before implementing it.

## Reporting after changes

Always report:

- changed files;
- whether product/source code changed;
- validation actually run;
- validation skipped and why;
- any remaining risks or follow-up items.
