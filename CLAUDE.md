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

Alongside the build, run:

- `OperatingMode = FXNEWS_MODE_SELFTEST` — 74 assertions over the pure helpers; needs no
  market data, no symbols and no history.
- the dead-code census in the wiki's *Testing and Validation* page — the field and local
  audits the compiler cannot do.

Neither covers stateful behaviour: the signal lifecycle, correlation grouping, alert
dispatch and the dashboard are verified only by manual runtime observation.

## Version bumps touch three locations plus the wiki

1. **This repo** — `FXNews.mq5` line 1 and `#property version`, plus `README.md`.
2. **`MQL5/Indicators/FXNews/`** — a separate clone of this repository. Update it with git
   (`fetch` + `reset --hard origin/main`), then copy a freshly compiled `FXNews.ex5` in.
   A stale `.ex5` next to a current `.mq5` is a trap: MT5 loads the binary.
3. **`origin/main`**.

Then the wiki (a separate git repository): `Home.md` version line and a `Changelog.md`
entry. The README links to that Changelog, so a version bump without it is visibly
inconsistent.

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
`available` flag, never on a sentinel value, and no tag or reason text may assert a
component that was not evaluated.
