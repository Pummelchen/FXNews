# FXNews audit — environment record

Mandated by the audit brief §1. Every tool used by this audit is listed with its exact
name, version, install method and host, so the environment is re-installable from this
file alone. Secrets are never recorded here.

## 1. Hosts

| Host | Role | OS | Arch | CPU | RAM | Cores | Access |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `node3` (Node3.local) | **Development + baseline + fix host** | macOS 27.0 (26A428) | arm64 (Apple M2) | Apple M2 | 8 GB | 8 | local |
| `node1` (Node1.local) | **Phase E independent verification host** | macOS 27.0 | arm64 (Apple M2) | Apple M2 | 8 GB | 8 | `ssh node1@node1` (key) |
| `node2` (Node2.local) | spare (not used this session) | macOS 27.0 | arm64 | Apple M2 | 8 GB | 8 | `ssh node2@node2` (key) |
| `node4` (Node4.local) | spare (not used this session) | macOS 27.0 | arm64 | Apple M2 | 8 GB | 8 | `ssh node4@node4` (key) |
| `deltasona` | Intel VPS, offered for Linux/x86 work (§1b) | Debian GNU/Linux 13 (trixie) | x86_64 | 8 cores | 15 GB (7 GB free) | 8 | `ssh root@91.99.176.243` (key) |

Fleet note (§1b): all four Macs are 8 GB and Apple M2. Per the brief, at most one heavy
build/test job runs per Mac at a time, and Docker must not run concurrently with an Xcode
build on the same Mac. FXNews has no Xcode or Docker component, so this audit runs one
build at a time on `node3`, then one on `node1` for Phase E. No job was run on the VPS.

### Remote state left behind

Anything installed on a remote host is recorded here so the fleet can be returned to a
known state.

| Host | Installed by this audit | Purpose | Removal |
| --- | --- | --- | --- |
| `node1` | Rosetta 2; `bandit 1.9.4` (pip, `--break-system-packages`); a staged copy of node3's `MetaTrader 5.app` at `~/mt5-app` (**removed**); `~/fxnews-phasee` and `~/fxnews-main` clones | Phase E attempt, abandoned — see E-5 | Rosetta 2 has no uninstaller; the staged app and the `fxnews-main` clone were deleted; `~/fxnews-phasee` (1.5 MB) retained |
| `node2` | Rosetta 2; `bandit 1.9.4` and `coverage 7.16.1` (pip, `--break-system-packages`, console scripts not on the non-interactive PATH - invoke them as `python3 -m bandit` / `python3 -m coverage`); `~/fxnews-phasee` clone (1.5 MB) | **Phase E host** | `rm -rf ~/fxnews-phasee`; `pip uninstall bandit coverage`; Rosetta 2 has no uninstaller |
| `node3` | Rosetta 2; `bandit`, `pip-audit`, `coverage`, `PyYAML` (pip) | development, baseline and fix host | `pip uninstall` those four; the interpreter itself is unchanged |
| `node4` | nothing | not used | — |
| `deltasona` (VPS) | nothing | reachable, not used | — |

**Fleet finding (E-4/E-5).** All four Macs are Apple Silicon and none had Rosetta 2 when
the audit began, so no gate could run anywhere. Rosetta is now installed on node1, node2 and
node3.

**Phase E procedure.** The MetaTrader gates must run inside the console user's **Aqua**
launchd session. Over SSH the session is `Background`, macOS forbids it from connecting to
WindowServer, and MetaTrader 5 — a windowed application — initialises graphics and exits
cleanly with code 0 before loading any script, producing `no Experts journal`. The symptom
looks like a broken terminal or a missing broker account; it is neither.

There are two ways in, and the second needs no privilege at all — use it (F-055):

```bash
# 1. As root. Works, but needed a credential, and the audit should not need one.
ssh <host> 'sudo launchctl asuser "$(id -u)" sudo -u <user> /bin/bash -lc \
  "cd ~/fxnews-phasee && ./tools/selftest-macos.sh"'

# 2. As the console user, no sudo. Write a LaunchAgent with
#    LimitLoadToSessionType=Aqua and bootstrap it into your OWN gui domain:
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.fxnews.phasee.plist
launchctl bootout   "gui/$(id -u)/com.fxnews.phasee"
```

Method 2 works because a non-root user may read and bootstrap into their own `gui/<uid>`
domain, and `LimitLoadToSessionType=Aqua` puts the job in the GUI session where WindowServer
is reachable. Note that `launchctl managername` reports `Background` **from inside such a
job**, which makes it a misleading probe — the test that matters is whether the terminal
actually starts. Method 2 was used for the 3.2 Phase E run and produced a complete green
gate set with no credential involved.

`node2` was the Phase E host (app 5.0.4501, Wine 9.14, same as the working development
host). `node1` was abandoned after its bundled Wine 9.8 (app 5.0.4330) refused to start even
with node3's newer Wine staged in; the staged copy was deleted.

## 2. Local toolchain (`node3`)

### Pre-existing

| Tool | Version | Path / method |
| --- | --- | --- |
| Homebrew | 7.0.1 | `/opt/homebrew/bin/brew` |
| git | 2.55.0 | `/opt/homebrew/bin/git` (Homebrew) |
| gh | 2.100.0 | `/opt/homebrew/bin/gh` (Homebrew) — **not authenticated**; API/git used instead |
| Python | 3.14.7 | `/Library/Frameworks/Python.framework/Versions/3.14/bin/python3` |
| pip | 26.2.1 | as above |
| ruff | 0.16.7 | `/opt/homebrew/bin/ruff` (Homebrew) |
| mypy | 2.3.1 | `/opt/homebrew/bin/mypy` (Homebrew) |
| shellcheck | (Homebrew) | `/opt/homebrew/bin/shellcheck` |
| shfmt | 3.14.1 | `/opt/homebrew/bin/shfmt` (Homebrew) |
| gitleaks | 8.30.1 | `/opt/homebrew/bin/gitleaks` (Homebrew) |
| trufflehog | 3.97.4 | `/opt/homebrew/bin/trufflehog` (Homebrew) |
| jq | 1.8.2 | `/opt/homebrew/bin/jq` (Homebrew) |
| Docker | 29.8.0 (server 29.5.2) | `/opt/homebrew/bin/docker` (Homebrew) |
| QEMU | 11.1.1 | `/opt/homebrew/bin/qemu-system-x86_64` (Homebrew) |
| Apple clang | 21.0.0 (clang-2100.3.34.2) | `/usr/bin/clang` (Xcode CLT) |

### Installed by this audit

| Tool | Version | Install method | Purpose |
| --- | --- | --- | --- |
| bandit | 1.9.4 | `python3 -m pip install --upgrade bandit` | Python SAST |
| pip-audit | 2.10.1 | `python3 -m pip install --upgrade pip-audit` | Python dependency/CVE scan |
| coverage | 7.16.1 (C extension) | `python3 -m pip install --upgrade coverage` | Python coverage |
| Rosetta 2 | macOS 27.0 runtime | `sudo softwareupdate --install-rosetta --agree-to-license` | **required** to execute the x86_64 Wine/MetaEditor build gate on arm64 |

Re-install command for the audit tooling:

```bash
python3 -m pip install --upgrade bandit pip-audit coverage
```

### MetaTrader 5 / Wine

| Component | Version | Path |
| --- | --- | --- |
| MetaTrader 5.app | 5.0.4501 | `/Applications/MetaTrader 5.app` (621 MB) |
| bundled `wine64` | MetaQuotes build, Mach-O **x86_64** | `/Applications/MetaTrader 5.app/Contents/SharedSupport/wine/bin/wine64` |
| WINEPREFIX | — | `$HOME/Library/Application Support/net.metaquotes.wine.metatrader5` (13 GB) |
| `terminal64.exe` | recorded in baseline | `<prefix>/drive_c/Program Files/MetaTrader 5/terminal64.exe` (112 MB) |
| `MetaEditor64.exe` | recorded in baseline | `<prefix>/drive_c/Program Files/MetaTrader 5/MetaEditor64.exe` (109 MB) |

**Platform coupling (finding E-1).** The bundled `wine64` is an **x86_64** Mach-O. On
Apple Silicon every gate therefore requires Rosetta 2. Rosetta was **absent on all four
Macs** when this audit began, so `tools/build-macos.sh` and `tools/selftest-macos.sh`
exited non-zero (exit 3, "MetaEditor wrote no log") on the entire fleet. This is recorded
as ledger task **E-1** and was remediated by installing Rosetta 2 on `node3`.

## 3. Credentials handling

- No secret is printed, logged, committed or echoed by this audit. Findings that touch a
  secret are reported as `file:line contains a live-looking credential`.
- The fleet/owner password supplied out of band is held only at `~/.fxnews/.fleet.secret`
  (mode `0600`, outside the repository) for the duration of the audit and is **deleted at
  the end**. It is never written into `AUDIT/` or committed.
- The GitHub PAT supplied out of band is not stored on disk by this audit; `gh` was left
  unauthenticated. It is present in the session transcript only, which is why the final
  report recommends rotating it.
