# FXNews audit — baseline (regression yardstick)

Phase A output (§3). Captured **before any change** on branch `audit/2026-09-15` at base
commit `71ce980`, host `node3` (Node3.local, macOS 27.0, Apple M2, 8 GB), after installing
Rosetta 2 (ledger `E-1`).

No later state may be worse than this on any metric without an explicit, justified,
numbered task.

## 1. Build

| Metric | Value |
| --- | --- |
| Command | `./tools/build-macos.sh` |
| Result line | `Result: 0 errors, 0 warnings, 4024 ms elapsed, cpu='X64 Regular'` |
| Exit code | **0** |
| Errors | **0** |
| Warnings | **0** |
| Artifact | `FXNews.ex5`, 223 340 bytes |
| Harness compile | `./tools/build-macos.sh tools/mql5/FXNewsSelfTest.mq5` → `0 errors, 0 warnings`, 887 ms |

Note: the harness compile emits one `information:` line about an implicitly added
`tester_indicator` property; `build-macos.sh` filters `information:` lines by design, so it
is not counted as a warning.

## 2. Tests

| Metric | Value |
| --- | --- |
| Command | `./tools/selftest-macos.sh` |
| Result line | `RESULT: 117 passed, 0 failed of 117 assertions` |
| Exit code | **0** |
| Passed | **117** |
| Failed | **0** |
| Skipped | 0 (the self-test has no skip mechanism) |
| Groups | 8 — ramps and clamps, robust statistics, time and session, symbols and timeframes, scoring helpers, availability and composer, historical engine, signal history |
| Runtime | terminal start → verdict ≈ 1 s of test work, inside a 240 s harness timeout |
| Coverage (MQL5) | **not measurable** — no MQL5 coverage tool exists (ledger `E-2`) |

This independently confirms the assertion count of **117** claimed by `README.md:50`,
`CLAUDE.md:45`, `Testing-and-Validation.md:11` and `Architecture.md:49`, and proves that
`tools/selftest-macos.sh:13` ("72 pure-helper assertions") is stale.

The 117 figure is a *dynamic* count: 120 static `SelfTestCheck`/`SelfTestNear` call sites
(75 + 45), of which 3 (`FXNews.mq5:1517`, `:1582`, `:1652`) execute only when a synthetic
allocation fails, so they do not run on a passing run.

## 3. Python static analysis (`tools/census.py`, the only Python file)

| Gate | Command | Result |
| --- | --- | --- |
| Type check | `mypy --strict tools/census.py` | **clean** — `Success: no issues found in 1 source file`, exit 0 |
| Lint | `ruff check tools/census.py` | **2 findings**, exit 1 — `F541 f-string without any placeholders` at `:273` and `:274` |
| Format | `ruff format --check tools/census.py` | **1 file would be reformatted**, exit 0 (reported, not enforced) |
| SAST | `bandit -q -r tools/census.py` | **clean**, exit 0 |
| Dependencies / CVE | `pip-audit` | **no repo dependency manifest exists**; imports are `argparse, json, re, sys, collections.abc, dataclasses, pathlib` — **stdlib only**, so the repo's dependency CVE surface is empty |
| Coverage | `coverage run --source=tools tools/census.py FXNews.mq5; coverage report -m` | **86 %** (247 statements, 34 missed) |

Environment-only note (does **not** ship, not a repo defect): `pip-audit` against the local
interpreter environment reports `setuptools 82.0.1` → `PYSEC-2026-3447` (fix 83.0.0).

## 4. Shell static analysis

| Gate | Command | Result |
| --- | --- | --- |
| Lint / SAST | `shellcheck tools/build-macos.sh tools/selftest-macos.sh` | **clean**, exit 0 |
| Format | `shfmt -d -i 2 -ci tools/build-macos.sh tools/selftest-macos.sh` | **differs** (exit 1) — style only: one-line `{ ...; }` guards, `case` arm layout, redirect spacing |

## 5. Dead code / placeholder census (repo's own analyzer)

| Metric | Value |
| --- | --- |
| Command | `python3 tools/census.py` |
| Result | `census: 0 open finding(s), 0 allowed, source FXNews.mq5` |
| Exit code | **0** |
| Allow-list | `tools/census-allow.txt` does not exist; `read_allow()` tolerates absence, so 0 allowed entries |

## 6. Secret scanning (full history, not just HEAD)

| Scanner | Scope | Result |
| --- | --- | --- |
| `gitleaks detect --source . --redact` | **78 commits**, ~702 KB | **no leaks found**, exit 0 |
| `trufflehog git file://. --results=verified,unknown` | 1 106 chunks, ~742 KB | **0 verified, 0 unverified secrets**, exit 0 |

History hygiene: no `.env`, `.pem`, `.key`, `.p12`, `id_rsa` or credential-named path has
ever been committed; no binary blob was ever committed (largest blob ever is
`FXNews.mq5` at 312 404 bytes).

## 7. Repository hygiene (L0)

| Check | Result |
| --- | --- |
| `.gitignore` adequacy | covers `*.ex5`, `*.log`, `*.out`, `*.tmp`, `*.bak`, `.DS_Store`, `MQL5/{Logs,Profiles,Tester}/` |
| Ignored-but-present files | none |
| Committed build artifacts | none |
| Lockfiles / pinned deps | N/A — zero dependencies |
| CI configuration | **none** (`.github/` contains only `traffic.json`) |
| License | MIT, `LICENSE` present, copyright holder named |
| Branch protection | unknown — not verifiable with the available token scope |

## 8. Summary of the yardstick

| Metric | Baseline (do not regress) |
| --- | --- |
| Build errors / warnings | 0 / 0 |
| Self-test | 117 passed, 0 failed |
| Census open findings | 0 |
| mypy --strict | clean |
| ruff check findings | 2 |
| shellcheck findings | 0 |
| shfmt drift | present |
| python coverage | 86 % |
| secrets | 0 |
| placeholders | 0 (census clean) |
| dependency CVEs | 0 (no dependencies) |
