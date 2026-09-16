# FXNews

<!-- agent-harnesses:begin -->
> **One instruction file.** This is it. Codex, DeepSeek Harness, OpenCode,
> Qwen Code, Qoder and Zed read `AGENTS.md` directly, and Claude Code reads it
> through the committed `CLAUDE.md`, which contains nothing but `@AGENTS.md`.
> **Edit only this file** — do not add a second set of instructions anywhere.
>
> Do **not** add `.rules`, `.cursorrules`, `.windsurfrules`, `.clinerules`,
> `.github/copilot-instructions.md` or `AGENT.md`. Zed takes the *first match*
> from that list, **ahead of `AGENTS.md`**, so any one of them silently
> replaces this file for every Zed user.
<!-- agent-harnesses:end -->

A chart-only MetaTrader 5 indicator that scores fresh breakout and impulse events
across a symbol/timeframe basket from a single chart. `FXNews.mq5` is one
**self-contained** file — 10,183 lines, no includes, no DLL, no `WebRequest`, no
file persistence and no order placement. Everything around it (`tools/`, `AUDIT/`)
is macOS-side build, gate and audit tooling driving MetaEditor under Wine. It is
feature-complete at source version 3.3 and distributed as source plus a locally
compiled `.ex5`. Released as
[`v3.300`](https://github.com/Pummelchen/FXNews/releases/tag/v3.300) with both attached; the process
is in [`RELEASE.md`](RELEASE.md).

## Product boundaries

No order placement, no file persistence, no `WebRequest`, no sockets, no DLL
imports. Scores are an **event-quality ranking, not a probability or a trade
instruction**. Autotune is advisory and never writes settings. Changing any of these
requires explicit human review — see the wiki's *Safety and Security* page.

## Working agreement

State findings plainly: no preamble, no hedging, and no disclaimer attached to every
mention of an already-established fact. Report what was verified and what was not,
**once**, and move on.

When you disagree, state the technical reason once and then proceed with the user's
chosen approach unless it is unsafe or impossible. Raise a concern once — do not
repeat it in later messages unless something new makes it newly relevant, or the user
asks — and do not re-litigate a decision the user has made.

**Work in this repository only.** Never commit, push, open a pull request against, or
otherwise modify any other repository — explicitly including the `TinyTitan` master
from which `RELEASE.md` is generated. `RELEASE.md` is a deployed copy: when it is wrong,
report the exact correction and why, and leave it. A fix that belongs upstream is the
owner's to apply. Touching another repository requires an instruction that names it, and
"the fix lives there" is not one.

## Layout

- `FXNews.mq5` — the whole product, at the repository root.
- `tools/build-macos.sh` and `tools/lib-mt5.sh` — the MetaEditor-under-Wine compile
  gate and the shared MT5/Wine path table.
- `tools/selftest-macos.sh` — a headless terminal self-test, plus
  `tools/mql5/FXNewsSelfTest.mq5` and `FXNewsPrimeHistory.mq5`, the harness scripts
  it installs and runs.
- `tools/census.py`, `tools/contracts.py`, `tools/census-allow.txt` — the static
  gates. `AUDIT/` — the audit record (`environment.md` pins every tool version).
- `.github/workflows/ci.yml` — the Python and shell gates.

## Build and test

```bash
./tools/build-macos.sh                    # compiles FXNews.mq5, or a path given as $1
./tools/build-macos.sh --install          # copies the .ex5 into MQL5/Indicators/FXNews/

python3 tools/census.py                   # dead-code and placeholder census
python3 tools/contracts.py                # cross-file string contracts
./tools/selftest-macos.sh                 # --validation | --autotune for a short historical pass
```

Both Python gates carry a `#!/usr/bin/env python3.14` shebang and `census.py`
hard-fails below `MIN_PYTHON = (3, 14)` — an older `python3` refuses rather than
degrading.

The self-test covers the pure helpers, the shared composer, the historical engine on
synthetic bars, the recent-signal list and the live signal lifecycle. It does
**not** cover correlation grouping, alert dispatch or dashboard rendering — those
are verified by manual runtime observation. `tools/contracts.py` covers the string
contracts between the indicator, the harness and these scripts, which no compiler
can see.

There is no standalone executable: the indicator is attached to a chart in MT5.

## Identity

`FXNews.mq5` line 3 — `#property version "3.300"` — is the source of truth, with
`// FXNews version 3.3` on line 1 and `README.md` restating it. **Nothing enforces
the string**: `tools/contracts.py` checks cross-file string contracts and one
structural dashboard invariant, but not the version triple.

**A version bump touches three locations plus the wiki:**

1. **This repository** — `FXNews.mq5` line 1 and the `#property version`, plus
   `README.md`.
2. **`MQL5/Indicators/FXNews/`** — the terminal's copy, which is a *separate clone*
   of this repository, not a directory this repository maintains. It is not
   guaranteed to exist. Bootstrap it once with
   `git clone https://github.com/Pummelchen/FXNews.git`, update it with `fetch` +
   `reset --hard origin/main`, then `./tools/build-macos.sh --install`.
3. **`origin/main`**.

Then the wiki (a separate git repository): the `Home.md` version line, a
`Changelog.md` entry, and the `Project-Tracker.md` page. The README links to the
Changelog, so a version bump without it is visibly inconsistent.

## Scoring conventions

A component that could not be measured is **excluded** from a blend — its weight
drops to zero and it leaves the normaliser — rather than imputed with a neutral
constant. Imputing drags every score toward that constant, penalising strong
candidates and flattering weak ones exactly when the least information is
available. Consumers gate on an explicit `available` / `measured` flag, never on a
sentinel value, and no tag or reason text may assert a component that was not
evaluated. This applies inside every component too.

The blend and the cap ladder exist **once**, in `ComposeSignalScore()`, and the
breakout structure, impulse blend, regime blend and execution blend are pure
functions shared by the live scanner and the historical modes. Change them there;
never fork a copy.

The terminal keeps only the first **63 characters** of a chart label. Compose rows
to that budget and put detail in the tooltip.

## Gates

- `.github/workflows/ci.yml` (`gates`, ubuntu-latest, Python 3.14) runs in order:
  `python tools/census.py`, `python tools/contracts.py`, `ruff check` /
  `ruff format --check`, `mypy --strict` on the three Python files, `bandit -q -r`,
  `shellcheck tools/*.sh`, `shfmt -d -i 2 -ci tools/*.sh`, and `gitleaks detect` over
  full history. Tool versions are pinned in the workflow env block.
- **The two MetaTrader gates are deliberately not in CI** — they need Wine and a
  terminal with broker history. **A green workflow is not by itself a release gate**;
  `build-macos.sh` and `selftest-macos.sh` must be run locally.

## Traps

- **`build-macos.sh` exit codes:** `0` clean (0 errors, **0 warnings**); `1` the
  compiler reported errors **or warnings**; `2` environment problem (missing source,
  Wine, MetaEditor, or a path containing a space); `3` MetaEditor produced no result
  line; `4` no finish within `BUILD_TIMEOUT` (default 300 s). Warnings fail the gate,
  so a "successful" compile is a low bar.
- **MetaEditor's `/compile:` and `/log:` switches silently do nothing when the path
  contains a space** — no log, no error, exit status 0. That rules out compiling in
  place under `MQL5/Indicators/`, which sits below `Program Files/MetaTrader 5`.
  Compile at the repository path and copy the `.ex5` across, or use the MetaEditor
  GUI, which is unaffected. The script detects the space and exits 2.
- **The bundled Wine is an x86_64 Mach-O.** On Apple Silicon it needs Rosetta 2;
  without it the compile writes no log and the build exits 3 with a message that
  blames the compiler. `tools/lib-mt5.sh` pre-empts this with `mt5_require_wine`
  (exit 2, naming the real cause). Install it with
  `sudo softwareupdate --install-rosetta --agree-to-license`.
- **A clean compile proves much less than it looks.** The MQL5 compiler warns only
  about a variable that is never touched at all — anything written, including by an
  initialiser, counts as used. Verified by probe: an initialised-but-unread local, a
  struct copied into a local and never read, a struct field assigned but never read,
  a tautological comparison, and an unreachable statement after `return` **all
  compile with zero warnings**. That is why `census.py`, `contracts.py` and the
  self-test exist.
- `--validation` and `--autotune` fail unless history actually loaded — the gate
  requires `Symbols loaded > 0` and `M1 bars > 0`, because a report over zero bars
  used to print OK.
- `selftest-macos.sh` requires that MetaTrader 5 is **not** already running
  (MetaTrader refuses a second instance, and the harness then waits on the wrong
  process). Exit `0` pass, `1` FAILED/ABORTED/timeout, `2` environment problem.
- **`--install` creates the destination directory and verifies the copy, but does
  not clone.** Installing into a directory with no `.git` leaves a binary with no
  source beside it, and the `fetch`/`reset` step then fails there. **A stale `.ex5`
  next to a current `.mq5` is a trap: MT5 loads the binary.**
- **No `.ex5` is committed and none should be** — `.gitignore` lists `*.ex5`; the
  compiled artifact is a release output, not source. The `.ex5` is MetaTrader
  bytecode, not a macOS binary, so macOS architecture and `lipo` rules do not apply.

<!-- release-rules:begin -->
## Releasing

**Read [`RELEASE.md`](RELEASE.md) before cutting a release.** It carries the
generic rules every Pummelchen repository follows, plus this repository's own
section. Do not improvise a release.

The non-negotiables:

- **Apple Silicon only** — build native `arm64` (M1–M6). Never `--arch x86_64`,
  never `ARCHS=arm64 x86_64`, and never `lipo -create`, which is how a universal
  binary gets made.
- **Assert it** — `lipo -archs <binary>` must report exactly `arm64`. A build that
  silently produced a fat binary is a release defect, not a build option.
- **Every release carries the artifacts.** A tag alone is not a release.
- **Identity is single-sourced and enforced** — never bump one declaration of the
  version or build number on its own; the build or CI must fail on a mismatch.
- **Dry run first**; publish only on an explicit flag.
- **Never fetch a model, dataset or dependency to make a gate pass.** A check that
  cannot run is reported *not checked*, and the release notes must name it.
<!-- release-rules:end -->
