# landed

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code skill](https://img.shields.io/badge/Claude%20Code-skill-8A63D2.svg)](https://code.claude.com/docs/en/skills)

**A Claude Code skill that verifies the finished work actually arrived at its real destination — and works there — before saying "done".**

You built the thing, tests passed, you said "done". But "done" was measured at the **workbench**: the local working tree, `localhost`, the build directory, the draft. The product doesn't live there. It lives at a **destination** — a remote branch behind a CI gate, a production URL, an install path on `$PATH`, a database row, someone's inbox. Until you've checked it *there*, you verified a rehearsal, not the product.

`landed` is the last-mile discipline: **local-green ≠ landed.**

> This skill exists because of a real miss: "16/16 local tests pass → published → done" while the remote CI was red the whole time. The fix isn't more local tests — it's checking the product where it actually lives.

---

## The rule

**Find where the product actually lives. Verify it there. Only then say "done".**

A deploy isn't done when the push succeeds — it's done when CI is green and the live URL serves the change. A publish isn't done when `git push` returns 0 — it's done when the remote branch shows the files and the release exists. The gap between "I pushed it" and "it landed" is where the embarrassing bugs live.

---

## The destination map

| You produced… | It actually LIVES at | Verify by |
|---|---|---|
| A published repo | remote branch + CI + releases | `gh run watch --exit-status`, `gh api .../contents`, fresh clone |
| A deployed web app | the production URL | `curl`/fetch live URL → status + content |
| A CLI / installed tool | the install path on `$PATH` | run it by name from a clean shell |
| A Claude Code skill/hook | `~/.claude/skills/…` + settings.json | `ls` install path, run `doctor.sh`, confirm hook wired |
| A database write | the actual row | re-read the row by id |
| A sent email | recipient inbox / **Sent** | check Sent, not Drafts |
| A config change | the running process | reload + observe the effect |
| A package release | the registry | install fresh in a clean env |
| A migration | whole tree + clean build | full build + `grep` proves zero old call-sites |

When your artefact isn't in the table, ask: *"if I deleted my local copy now, where would the product still exist for the user?"* That's the destination.

---

## The landing checklist

Before any "done / shipped / live / published / deployed / sent":

1. **Present** — it exists at the destination (you read it back *from there*).
2. **Correct** — it's the version you intended (right commit/tag, not a stale cache).
3. **Working** — it runs / resolves / serves *at* the destination (CI green, URL 200s, binary runs).
4. **Clean** — no half-landed state (no red CI, no old call-sites, no draft-as-sent).

Skip any → say "pushed, CI running", never "done", until all four hold.

---

## Install

```bash
git clone https://github.com/pedroreisper/landed
less landed/install.sh          # read it
bash landed/install.sh          # installs to ~/.claude/skills/landed
```

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/pedroreisper/landed/main/install.sh | bash
```

Flags: `--project`, `--hook` (wire the proactive Stop hook), `--uninstall`. Then `/reload` and:

```bash
bash ~/.claude/skills/landed/scripts/doctor.sh
```

---

## Two modes

**Manual** — invoke `/landed` after a deploy/publish/install to run the checklist.

**Proactive** — a `Stop` hook (`hooks/landed_check.py`) scans your final message for a ship-claim about a remote destination. If the turn shows **no evidence** of a destination check (a `gh run`/`gh release`/`gh api` call, a `curl`/fetch to an http URL, a registry install, a read of the install path), it **blocks** and makes you verify at the destination first.

```bash
bash ~/.claude/skills/landed/hooks/install_hook.sh
```

Calibrated for precision: it blocks **only** on a strong ship-claim with **zero** evidence, reads evidence from actual tool calls (not the model's claim), and blocks once per stop chain. A vague "that's done" about a local edit doesn't trip it.

---

## Composes with

- **[`did-it-actually`](https://github.com/pedroreisper/did-it-actually)** asks *does the output match the request?* (fidelity). `landed` asks *did it reach where it lives and work there?* (location). Run `landed` last.
- **[`resourceful`](https://github.com/pedroreisper/resourceful)** governs input depth; `landed` governs output reach.
- **[`upshift`](https://github.com/pedroreisper/upshift)** picks the execution gear; `landed` confirms the product reached its destination.

## What's in the box

```
landed/
├── SKILL.md                    # destination map + last-mile discipline
├── hooks/
│   ├── landed_check.py         # Stop hook — blocks a ship-claim with no destination evidence
│   └── install_hook.sh
├── references/
│   ├── destination-map.md      # full artefact → destination → verification table
│   └── examples.md             # worked landings + a deliberate "not yet landed"
├── scripts/doctor.sh
├── tests/                      # block/allow hook tests (run in CI)
└── install.sh
```

## License

MIT © 2026 Pedro Reis Pereira
