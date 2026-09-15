#!/usr/bin/env python3.14
"""Render the audit's human-readable views from the machine ledger.

`AUDIT/ledger.json` is the single source of truth for task records. This script
derives, and therefore can never diverge from it:

  * AUDIT/findings.md          - the full Phase B enumeration, for the repository
  * AUDIT/wiki-tracker.md      - the section to paste into the GitHub wiki
                                 Project-Tracker page (brief section 9)

Usage:
    python3 AUDIT/render.py

Exit status is 0 on success, 2 when the ledger is missing or unreadable.
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

STATUSES_OPEN = frozenset({"START", "PROGRESS", "TEST", "AUDIT"})
SEVERITY_ORDER = ("S0", "S1", "S2", "S3")


def load_ledger(path: Path) -> dict[str, Any]:
    """Return the parsed ledger, or exit 2 with a message."""
    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
    except OSError as exc:
        sys.exit(f"render: cannot read {path}: {exc}")
    except json.JSONDecodeError as exc:
        sys.exit(f"render: {path} is not valid JSON: {exc}")
    if not isinstance(data, dict) or "tasks" not in data:
        sys.exit(f"render: {path} has an unexpected shape")
    return data


def severity_rank(task: dict[str, Any]) -> tuple[int, str]:
    """Sort key: severity first, then id."""
    severity = str(task.get("severity", "S3"))
    index = (
        SEVERITY_ORDER.index(severity)
        if severity in SEVERITY_ORDER
        else len(SEVERITY_ORDER)
    )
    return (index, str(task.get("id", "")))


def cell(text: Any) -> str:
    """Escape a value for a Markdown table cell."""
    return str(text if text is not None else "-").replace("|", "\\|").replace("\n", " ")


def summary_line(tasks: list[dict[str, Any]]) -> str:
    """One-line counts block for the top of both views."""
    by_status = Counter(str(t.get("status", "?")) for t in tasks)
    by_sev = Counter(str(t.get("severity", "?")) for t in tasks)
    done = by_status.get("DONE", 0)
    blocked = by_status.get("BLOCKED", 0)
    open_count = sum(by_status.get(s, 0) for s in STATUSES_OPEN)
    sev = " ".join(f"{s}:{by_sev.get(s, 0)}" for s in SEVERITY_ORDER)
    return (
        f"total {len(tasks)} | done {done} | open {open_count} | "
        f"blocked {blocked} | {sev}"
    )


def render_findings(ledger: dict[str, Any]) -> str:
    """The Phase B enumeration document."""
    tasks: list[dict[str, Any]] = sorted(ledger["tasks"], key=severity_rank)
    lines: list[str] = [
        "# FXNews audit — finding enumeration (Phase B)",
        "",
        "Generated from `AUDIT/ledger.json` by `AUDIT/render.py` — do not edit by hand.",
        f"Branch `{ledger['branch']}`, base commit `{ledger['baseCommit']}`.",
        "",
        f"**{summary_line(tasks)}**",
        "",
        "Severity follows the audit brief §7. Work order: all S0, then S1, S2, S3.",
        "",
        "| id | sev | area | status | file:line | title |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for task in tasks:
        lines.append(
            f"| {cell(task['id'])} | {cell(task['severity'])} | {cell(task['module'])} "
            f"| {cell(task['status'])} | `{cell(task['file'])}` | {cell(task['title'])} |"
        )

    lines += ["", "## Detail", ""]
    for task in tasks:
        lines += [
            f"### {task['id']} ({task['severity']}, {task['module']}) — {task['title']}",
            "",
            (
                f"- **Status:** {task['status']}  |  **Category:** {task.get('category', '-')}  "
                f"|  **Host:** {task.get('hostUsed', '-')}  |  **Commit:** {task.get('commit') or '-'}"
            ),
            f"- **Location:** `{task['file']}`",
            f"- **Discovered by:** {task.get('discoveredBy', '-')}",
        ]
        if task.get("evidenceBefore"):
            lines += [
                "- **Evidence (before):**",
                "",
                "  > " + str(task["evidenceBefore"]).replace("\n", " "),
                "",
            ]
        if task.get("fixSummary"):
            lines += [f"- **Fix:** {task['fixSummary']}"]
        if task.get("evidenceAfter"):
            lines += [f"- **Evidence (after):** {task['evidenceAfter']}"]
        if task.get("notes"):
            lines += [f"- **Notes:** {task['notes']}"]
        if task.get("blockedReason"):
            lines += [f"- **BLOCKED:** {task['blockedReason']}"]
        lines.append("")
    return "\n".join(lines)


def render_wiki(ledger: dict[str, Any]) -> str:
    """The Project-Tracker section, per brief §9."""
    tasks: list[dict[str, Any]] = sorted(ledger["tasks"], key=severity_rank)
    open_tasks = [t for t in tasks if str(t.get("status")) in STATUSES_OPEN]
    blocked = [t for t in tasks if t.get("status") == "BLOCKED"]
    done = [t for t in tasks if t.get("status") == "DONE"]

    lines: list[str] = [
        "## Pre-production audit (2026-09-15)",
        "",
        (
            "Independent pre-production audit of the whole repository, run on branch "
            "`audit/2026-09-15` from base commit `71ce980`, and merged by pull request only "
            "after the final phase passed. The authoritative ledger lives in the repository at "
            "`AUDIT/ledger.md` / `AUDIT/ledger.json`; this page mirrors it and the ledger wins "
            "on any conflict."
        ),
        "",
        f"**{summary_line(tasks)}**",
        "",
        "### Open items",
        "",
    ]
    if open_tasks:
        lines += [
            "| # | Sev | Status | Area | What |",
            "| --- | --- | --- | --- | --- |",
        ]
        for task in open_tasks:
            lines.append(
                f"| {cell(task['id'])} | {cell(task['severity'])} | {cell(task['status'])} "
                f"| {cell(task['module'])} | {cell(task['title'])} |"
            )
    else:
        lines.append("_None._")

    lines += ["", "### Blocked items", ""]
    if blocked:
        lines += [
            "| # | Sev | Blocked by | What | Options for a human |",
            "| --- | --- | --- | --- | --- |",
        ]
        for task in blocked:
            lines.append(
                f"| {cell(task['id'])} | {cell(task['severity'])} | {cell(task.get('blockedReason'))} "
                f"| {cell(task['title'])} | - |"
            )
    else:
        lines.append("_None._")

    lines += [
        "",
        "### Completed audit tasks",
        "",
    ]
    if done:
        lines += [
            "| # | Sev | Area | What | Evidence |",
            "| --- | --- | --- | --- | --- |",
        ]
        for task in done:
            lines.append(
                f"| {cell(task['id'])} | {cell(task['severity'])} | {cell(task['module'])} "
                f"| {cell(task['title'])} | {cell(task.get('evidenceAfter') or task.get('fixSummary'))} |"
            )
    else:
        lines.append("_None yet._")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    """Write both views next to the ledger."""
    here = Path(__file__).resolve().parent
    ledger = load_ledger(here / "ledger.json")
    (here / "findings.md").write_text(render_findings(ledger), encoding="utf-8")
    (here / "wiki-tracker.md").write_text(render_wiki(ledger), encoding="utf-8")
    tasks: list[dict[str, Any]] = ledger["tasks"]
    print(f"render: wrote findings.md and wiki-tracker.md — {summary_line(tasks)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
