#!/usr/bin/env python3.14
"""Cross-file contract checks for FXNews.

The indicator, the harness script and the two shell gates are coupled by string
literals that no compiler and no existing gate checks:

  * the verdict labels the harness polls for and the shell gate greps for,
  * the "RESULT: N passed, M failed" line the shell gate parses,
  * the report fields the shell gate now parses to prove a historical run read data,
  * the harness indicator path and the directory the shell gate installs into.

Renaming any of them in one file used to turn a gate into a timeout or a silent
pass with no indication of the cause. This makes such a change fail loudly at the
gate instead.

It also pins one structural invariant that has no runtime expression: the dashboard
must refresh its signal-history cache unconditionally, because that cache backs the
dirty flag which schedules the whole dashboard update. The call used to sit inside
the "history list is the only display" branch, so with active rows enabled the flag
was never cleared and the dashboard rebuilt on every scan (F-011).

Usage:
    tools/contracts.py [repo-root]

Exit status is 0 when every contract holds, 1 on any violation, 2 on a usage or
read problem. Requires Python 3.14 or later.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

MIN_PYTHON = (3, 14)
if sys.version_info < MIN_PYTHON:
    sys.exit(
        f"contracts: Python {MIN_PYTHON[0]}.{MIN_PYTHON[1]}+ required, "
        f"found {sys.version.split()[0]}"
    )


@dataclass(frozen=True)
class Violation:
    """One broken contract."""

    contract: str
    detail: str

    def as_text(self) -> str:
        """Render for a terminal."""
        return f"contracts: FAIL [{self.contract}] {self.detail}"


def read(path: Path) -> str:
    """Read a source file, or exit 2."""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        sys.exit(f"contracts: cannot read {path}: {exc}")


def require_all(
    violations: list[Violation],
    contract: str,
    needles: list[str],
    haystack: str,
    where: str,
) -> None:
    """Record a violation for every needle missing from haystack."""
    for needle in needles:
        if needle not in haystack:
            violations.append(
                Violation(contract, f"{where} no longer contains {needle!r}")
            )


def check_verdict_labels(
    violations: list[Violation], indicator: str, harness: str, shell: str
) -> None:
    """The verdict strings the indicator publishes, the harness polls and the gate greps."""
    labels = [
        "SELFTEST PASSED",
        "SELFTEST FAILED",
        "VALIDATION ready",
        "AUTOTUNE ready",
        "ABORTED",
    ]
    require_all(violations, "verdict-labels", labels, harness, "FXNewsSelfTest.mq5")
    require_all(
        violations,
        "verdict-labels",
        ["SELFTEST PASSED"],
        shell,
        "selftest-macos.sh",
    )
    require_all(
        violations,
        "verdict-labels",
        ["SELFTEST", "VALIDATION", "AUTOTUNE", "ABORTED"],
        indicator,
        "FXNews.mq5",
    )


def check_result_line(violations: list[Violation], indicator: str, shell: str) -> None:
    """The self-test result line the shell gate parses for its pass/fail verdict."""
    require_all(
        violations,
        "result-line",
        ["RESULT: %d passed, %d failed"],
        indicator,
        "FXNews.mq5",
    )
    if not re.search(r"RESULT: \[0-9\]\* passed, \[0-9\]\* failed", shell) and (
        "RESULT: [0-9]* passed, [0-9]* failed" not in shell
    ):
        # The shell side writes the pattern as a POSIX ERE inside a grep -o argument.
        violations.append(
            Violation(
                "result-line",
                "selftest-macos.sh no longer parses 'RESULT: [0-9]* passed, [0-9]* failed'",
            )
        )


def check_report_fields(
    violations: list[Violation], indicator: str, shell: str
) -> None:
    """The report fields the shell gate parses to prove a historical run read data."""
    require_all(
        violations,
        "report-fields",
        ["M1 bars=%d", "Symbols %d/%d", "evaluated %d of"],
        indicator,
        "FXNews.mq5",
    )
    require_all(
        violations,
        "report-fields",
        ["M1 bars=", "Symbols "],
        shell,
        "selftest-macos.sh",
    )


def check_harness_path(violations: list[Violation], harness: str, shell: str) -> None:
    """The path the harness loads the indicator from and the directory the gate installs into."""
    match = re.search(r'#define\s+HARNESS_INDICATOR_PATH\s+"([^"]+)"', harness)
    if match is None:
        violations.append(
            Violation(
                "harness-path", "FXNewsSelfTest.mq5 declares no HARNESS_INDICATOR_PATH"
            )
        )
        return
    # "FXNews-selftest\\FXNews" -> install dir FXNews-selftest, binary FXNews.ex5
    parts = [p for p in match.group(1).split("\\") if p]
    if len(parts) != 2:
        violations.append(
            Violation(
                "harness-path", f"unexpected HARNESS_INDICATOR_PATH {match.group(1)!r}"
            )
        )
        return
    install_dir, binary = parts
    if f"Indicators/{install_dir}" not in shell:
        violations.append(
            Violation(
                "harness-path",
                f"selftest-macos.sh does not install into Indicators/{install_dir}",
            )
        )
    if f"{binary}.ex5" not in shell:
        violations.append(
            Violation(
                "harness-path", f"selftest-macos.sh does not install {binary}.ex5"
            )
        )


def check_dashboard_refresh(violations: list[Violation], indicator: str) -> None:
    """UpdateDashboard must refresh the history cache before it branches on display mode."""
    body = re.search(r"void UpdateDashboard\(\)\s*\{(.*?)\n\}", indicator, re.DOTALL)
    if body is None:
        violations.append(
            Violation("dashboard-refresh", "UpdateDashboard not found in FXNews.mq5")
        )
        return
    text = body.group(1)
    refresh = text.find("RefreshVisibleSignalHistoryIfDue();")
    branch = text.find("if(ShowActiveSignalRows)")
    if refresh == -1:
        violations.append(
            Violation(
                "dashboard-refresh",
                "UpdateDashboard no longer refreshes the visible signal history",
            )
        )
    elif branch != -1 and refresh > branch:
        violations.append(
            Violation(
                "dashboard-refresh",
                "UpdateDashboard refreshes the history only after 'if(ShowActiveSignalRows)'; with active rows "
                "enabled the dirty flag is then never cleared and the dashboard rebuilds every scan (F-011)",
            )
        )


def check_ranking_disclosure(violations: list[Violation], indicator: str) -> None:
    """Both historical reports must state whether the sample supports the ranking claim.

    The reports used to print the claim unconditionally, so an AUTOTUNE run whose
    buckets fell the wrong way still recommended settings without saying so. The
    comparison itself lives in EvaluateHistoricalRanking and is asserted by the
    self-test; this pins the two call sites, which no unit test can reach without
    running a full historical backtest.
    """
    for builder in ("BuildValidationReport", "BuildAutotuneReport"):
        body = re.search(rf"void {builder}\(.*?\n\}}", indicator, re.DOTALL)
        if body is None:
            violations.append(
                Violation("ranking-disclosure", f"{builder} not found in FXNews.mq5")
            )
            continue
        if "AddHistoricalRankingVerdict(" not in body.group(0):
            violations.append(
                Violation(
                    "ranking-disclosure",
                    f"{builder} no longer reports whether the sample supports the score's ranking claim",
                )
            )


def main(argv: list[str]) -> int:
    """Run every contract check against the repository at argv[0] or the parent of tools/."""
    root = (
        Path(argv[1]).resolve()
        if len(argv) > 1
        else Path(__file__).resolve().parent.parent
    )
    indicator = read(root / "FXNews.mq5")
    harness = read(root / "tools" / "mql5" / "FXNewsSelfTest.mq5")
    shell = read(root / "tools" / "selftest-macos.sh")

    violations: list[Violation] = []
    check_verdict_labels(violations, indicator, harness, shell)
    check_result_line(violations, indicator, shell)
    check_report_fields(violations, indicator, shell)
    check_harness_path(violations, harness, shell)
    check_dashboard_refresh(violations, indicator)
    check_ranking_disclosure(violations, indicator)

    for violation in violations:
        print(violation.as_text())
    print(
        f"contracts: {len(violations)} violation(s) across 6 contracts, root {root.name}"
    )
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
