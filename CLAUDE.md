# FXNews — working agreement

## Tone

Use a neutral, collaborative engineering tone. Be direct but not argumentative.

When you disagree, state the technical reason once and proceed with the user's chosen
approach unless it is unsafe or impossible.

In practice:

- Raise a concern once. Do not repeat it in later messages unless something new makes it
  newly relevant, or the user asks.
- Do not re-litigate a decision the user has made.
- State findings plainly. No preamble, no hedging, no disclaimer attached to every mention
  of an already-established fact.
- Report what was verified and what was not, once, and move on.

## Build

```bash
./tools/build-macos.sh
```

Exits non-zero on any error **or** warning, so it can gate a commit. macOS only; it drives
MetaEditor through the Wine bundle inside the MetaQuotes build of MetaTrader 5.

MetaEditor's `/compile:` CLI silently does nothing when the source path contains a space —
no log, no error, exit status 0. That rules out compiling in place under
`MQL5/Indicators/`, which sits below `Program Files/MetaTrader 5`. Compile at the repo path
and copy `FXNews.ex5` across, or use the MetaEditor GUI, which is unaffected.

## A clean compile proves less than it looks

The MQL5 compiler warns only about a variable that is never touched at all. Anything
written — including by an initialiser — counts as used. Verified by probe: an
initialised-but-unread local, a struct copied into a local and never read, a struct field
assigned but never read, a tautological comparison and an unreachable statement after
`return` all compile with zero warnings.

Alongside the build, run the other two gates:

```bash
tools/census.py            # dead-code and placeholder census, exits non-zero on any finding
tools/contracts.py         # cross-file string contracts between the indicator, the harness and the gates
./tools/selftest-macos.sh  # self-test in the terminal; --validation / --autotune run
                           # a short historical pass and require a complete report
```

The self-test covers the pure helpers, the shared composer, the historical engine on
synthetic bars, the recent-signal list and the live signal lifecycle. It does not cover
correlation grouping, alert dispatch or dashboard rendering; those are verified by manual
runtime observation. `tools/contracts.py` covers the string contracts between the
indicator, the harness and these scripts, which no compiler sees.

## Version bumps touch three locations plus the wiki

1. **This repo** — `FXNews.mq5` line 1 and `#property version`, plus `README.md`.
2. **`MQL5/Indicators/FXNews/`** — the terminal's copy, which is a *separate clone* of this
   repository, not a directory this repo maintains. It is not guaranteed to exist: on the
   audit machine it was absent until `--install` created it, and it held only `FXNews.ex5`
   afterwards (F-037). Bootstrap it once with
   `git clone https://github.com/Pummelchen/FXNews.git`, then update it with
   `fetch` + `reset --hard origin/main`, then `./tools/build-macos.sh --install` (or copy a
   freshly compiled `FXNews.ex5` in). `--install` creates the directory and verifies the
   copy but does **not** clone: installing into a directory with no `.git` leaves a binary
   with no source beside it, so the `fetch`/`reset` step above will fail there. A stale
   `.ex5` next to a current `.mq5` is a trap: MT5 loads the binary.
3. **`origin/main`**.

Then the wiki (a separate git repository): `Home.md` version line, a `Changelog.md`
entry, and the `Project-Tracker.md` page (close what the revision completes, log what
was found but deferred). The README links to the Changelog, so a version bump without it
is visibly inconsistent.

## Product boundaries

No order placement, no file persistence, no `WebRequest`, no sockets, no DLL imports.
Scores are an event-quality ranking, not a probability or a trade instruction. Autotune is
advisory and never writes settings. Changing any of these requires explicit human review —
see the wiki's *Safety and Security* page.

## Scoring conventions

A component that could not be measured is **excluded** from a blend — its weight drops to
zero and it leaves the normaliser — rather than imputed with a neutral constant. Imputing
drags every score toward that constant, penalising strong candidates and flattering weak
ones exactly when the least information is available. Consumers gate on an explicit
`available` / `measured` flag, never on a sentinel value, and no tag or reason text may
assert a component that was not evaluated. This applies inside every component too.

The blend and the cap ladder exist once, in `ComposeSignalScore()`, and the breakout
structure, impulse blend, regime blend and execution blend are pure functions shared by
the live scanner and the historical modes. Change them there; never fork a copy.

The terminal keeps only the first 63 characters of a chart label. Compose rows to that
budget and put detail in the tooltip.
