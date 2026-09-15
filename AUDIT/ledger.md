# FXNews pre-production audit — task ledger

Source of truth for the audit (§8). Machine-readable mirror: `AUDIT/ledger.json`.
The GitHub wiki Project-Tracker mirrors the open/blocked subset (§9); **this ledger wins
on conflict**.

Branch: `audit/2026-09-15`. Base commit: `71ce980`.

Task fields: `id | severity | project/module | file:line | title | category | status |
host-used | discovered-by | evidence-before | fix-summary | evidence-after | commit |
notes | blocked-reason`.

Statuses: `START -> PROGRESS -> TEST -> AUDIT -> DONE`, plus `BLOCKED`.

Gates: **START** reproduced/proven + expected-correct behaviour written down;
**PROGRESS** the diff; **TEST** a test that FAILS before and PASSES after, pasted, full
suite green on the right host class, no new warnings vs baseline; **AUDIT** cold re-read,
linters/analyzers/scanners re-run, no baseline regression, no new placeholder;
**DONE** all of the above, committed atomically to the audit branch.

## Template adaptation notice

The audit brief targets a 20+ project polyglot monorepo (Swift 6.4/C#/.NET 10/C99/Python).
This repository has **one product source file** (`FXNews.mq5`, MQL5) plus three tool files.
Per the owner's decision the brief is applied to FXNews with every section that cannot
apply documented as N/A in `AUDIT/inventory.md` §6 rather than fabricated. Language
standards for Swift, C# and C are **N/A — no source in those languages exists here**.

## Environment tasks

| id | sev | module | file:line | title | category | status | host | commit |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| E-1 | S0 | tooling | `tools/build-macos.sh:40` | Build and self-test gates cannot execute: bundled `wine64` is x86_64, Rosetta 2 absent on all four Macs | deps | **DONE** | node3 | _pending_ |
| E-2 | S1 | tooling | `tools/selftest-macos.sh:34` | No MQL5 formatter/linter/SAST/coverage tooling exists; gates are limited to compiler + census + self-test | deps | **DONE** | node3 | _pending_ |

### E-1 — Rosetta 2 absent: both gates are unrunnable fleet-wide

- **Evidence before:** `arch -x86_64 /usr/bin/true` → `Bad CPU type in executable` on
  `node1`, `node2`, `node3`, `node4`. `file wine64` → `Mach-O 64-bit executable x86_64`.
  `tools/build-macos.sh` does not verify that Wine can actually execute; it checks only
  `[ -x "$WINE" ]` (`:47`), so the failure surfaces late as exit 3
  (`MetaEditor wrote no log`) instead of exit 2 (environment problem).
- **Expected-correct behaviour:** the documented build/test workflow in `README.md:32-50`,
  `CLAUDE.md:10-18` and the wiki Release-Checklist must run on a stock Apple-Silicon Mac;
  and `build-macos.sh` must report an environment problem (exit 2) when Wine cannot run,
  not a compiler-result problem (exit 3).
- **Exact remediation command (logged before execution, per §0):**
  `sudo softwareupdate --install-rosetta --agree-to-license`
- **Rollback:** Rosetta 2 has no supported uninstaller. Rollback is
  `sudo rm -rf /Library/Apple/usr/libexec/oah` (not recommended; breaks all x86_64
  binaries including MetaTrader). Recorded for completeness only.
- **Host:** `node3` (dev), `node1` (Phase E).
- **Discovered by:** Phase A environment probe.
- **Evidence after:** `sudo softwareupdate --install-rosetta --agree-to-license` → "Install
  of Rosetta 2 finished successfully"; `arch -x86_64 /usr/bin/true` → OK;
  `wine64 --version` → `wine-9.14`; `./tools/build-macos.sh` → `0 errors, 0 warnings`,
  exit 0. **Follow-on repo defect filed separately as `F-001`** (the script cannot
  distinguish "Wine cannot execute" from "compiler produced no result").

### E-2 — No MQL5 static-analysis or coverage tooling

- **Evidence before:** no MQL5 formatter, linter, static analyzer, SAST scanner or
  coverage tool exists in the fleet (verified against Homebrew, pip and the toolchain
  probe). MQL5 is a closed language with no public parser; MetaEditor's own compiler is
  the only analyzer.
- **Consequence:** L4 (security) and L5 (performance) analysis of `FXNews.mq5` is
  **manual and evidence-based**, not tool-assisted. `tools/census.py` (written for this
  repo) supplies dead-code/placeholder coverage and is treated as the repo's own analyzer.
- **Not BLOCKED:** a real substitute exists and is used. Recorded as a documented
  tooling gap rather than a blocker.

## Findings

_Phase B populates this section. Nothing is listed as a finding until it has an evidence
reference._
