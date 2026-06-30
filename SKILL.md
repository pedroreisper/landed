---
name: landed
description: Verifies the finished work actually arrived at its REAL destination and works there — not at the place it was built. After a deploy / publish / release / install / migration / send, it asks "where does this product actually live?" (remote branch + green CI, production URL, install path, DB row, Sent folder, the running process) and checks it there. Use whenever about to say "done / shipped / live / published / deployed / merged / sent / pronto / entregue / no ar" about something that lives somewhere other than where you built it. Also fires proactively (Stop hook) and blocks a ship-claim with no evidence of a destination check. NOT a request-fidelity verifier (that's did-it-actually) and NOT a code reviewer — it checks LOCATION and last-mile reachability of the final artefact.
license: MIT
metadata:
  version: "1.0.0"
  priority: "9"
  audience: "claude-code"
---

# landed — did it land where it actually lives?

You built the thing. Tests passed. You said "done". But "done" was measured at the
**workbench** — the local working tree, `localhost`, the build directory, the draft.
The product doesn't live there. It lives at a **destination**: a remote branch behind
a CI gate, a production URL, an install path on `$PATH`, a database row, someone's
inbox. Until you've checked it *there*, you haven't verified the product — you've
verified a rehearsal of it.

This skill is the last-mile discipline. Local-green ≠ landed. Before "done" on
anything that ships somewhere, you locate the real destination and confirm the
artefact is **present, correct, and working** at that destination.

## The core rule

**Find where the product actually lives. Verify it there. Only then say "done".**

A deploy isn't done when the push succeeds — it's done when CI is green and the live
URL serves the change. A publish isn't done when `git push` returns 0 — it's done
when the remote default branch shows the files and the release exists. An install
isn't done when the build compiles — it's done when running the binary from its
installed path works. The gap between "I pushed it" and "it landed" is where the
embarrassing bugs live.

## The destination map

For each artefact, the product lives at the **right-hand** column. Verify there.

| You produced… | Built / staged at | It actually LIVES at | Verify by (at the destination) |
|---|---|---|---|
| A published repo | local working tree | remote default branch + CI + releases | `gh run watch --exit-status`; `gh api repos/o/r/contents/<path>`; fresh `git clone` then run |
| A deployed web app | `localhost` / build dir | the production URL | `curl`/WebFetch the live URL → assert status + expected content; not the dev server |
| A CLI / installed tool | repo checkout | the install path on `$PATH` | run it by name from a clean shell; `which`; `--version` |
| A Claude Code skill/hook | repo checkout | `~/.claude/skills/<n>` + settings.json | `ls` the install path; run its `doctor.sh`; confirm the hook is wired |
| A database write | app memory / the ORM call | the actual table/row | re-read the row back from the DB by id |
| A sent message / email | a draft | recipient inbox / your **Sent** folder | check Sent (not Drafts); confirm thread id / delivery |
| A config change | the edited file | the **running process** that reads it | reload + observe the effect, not just the file contents |
| A generated document | the markdown / source | the rendered / shared artefact | open the rendered output; confirm a shared link actually resolves |
| A package release | local build dir | the registry (npm/pypi/crates) | install fresh from the registry in a clean env; import/run it |
| A migration / refactor | the files you edited | the whole tree + the build | full build + test from clean; grep that **zero** old call-sites remain |

When your artefact isn't in the table, derive the destination from one question:
*"If I deleted my local copy right now, where would the product still exist for the
user?"* That place is the destination. Check it there.

## The landing checklist

Run this before emitting any ship-claim ("done / shipped / live / published /
deployed / merged / sent / pronto / entregue / no ar"):

1. **Present** — the artefact exists at the destination (remote file, live URL, row, install path). You *read it back from there*, not from your build.
2. **Correct** — the version at the destination is the one you intended (right commit/tag, right content, not a stale cache, not a half-push).
3. **Working** — it actually runs / resolves / serves *at* the destination (CI green, URL 200s with the change, binary executes, row queryable, link opens).
4. **Clean** — no half-landed state: no failed CI, no broken old call-sites left behind, no draft mistaken for sent, no `localhost`-only success.

A "done" that skips any of these is provisional — say "pushed, CI running" or
"deployed, verifying live", never "done", until all four hold.

## Reproduce the gate locally first

The cheapest way to land cleanly is to **run the destination's gate before you push
to it**. If the remote has a CI lint step, install the real linter and run it locally
(`brew install shellcheck` then `shellcheck …`) — "my tests pass" does not cover a
lint or build step you never ran. Mirror the CI sequence on your machine; only then
push and watch it confirm.

## When to use

- **Proactively** — the `hooks/landed_check.py` Stop hook scans your final message for
  a ship-claim about a remote destination (published/deployed/released/live/merged/
  sent). If it finds one with **no evidence** in the turn of a destination check
  (a `gh run`/`gh release`/`gh api` call, a `curl`/fetch to an http URL, a registry
  install, a read of the install path), it **blocks** and makes you verify at the
  destination first. Install with `bash hooks/install_hook.sh`.
- **Manually** — invoke `/landed` after a deploy/publish/install to run the checklist.
- **As a gate** — anytime you're about to type "done" about something that lives
  somewhere other than where you built it.

## When NOT to use

- Purely local work with no destination (a scratch script, a local analysis). The
  workbench *is* the destination — Gear-1 of life.
- When you've already verified at the destination and are reporting that verification.
- Read-only answers and conversation, where nothing ships.

## Anti-noise (calibrated, not crying wolf)

- The hook **blocks only on a strong ship-claim with zero destination evidence** — high
  precision. A vague "that's done" about a local edit does not trip it.
- Evidence is read from the **transcript** (actual tool calls), not from the model's
  claim that it checked. "CI is green" without a `gh run` call in the turn counts as
  unverified.
- One block per stop chain (a `stop_hook_active` guard prevents loops). The point is a
  single forced destination check, not nagging.

## Relationship to other skills

- **`did-it-actually`** asks *"does the output match what was asked?"* — request
  fidelity. `landed` asks *"did that output reach where it lives and work there?"* —
  location fidelity. They're orthogonal and compose: a `did-it-actually` PASS on a
  deploy you never confirmed is live is still not done. Run `landed` last.
- **`resourceful`** governs input depth (how hard you looked before answering).
  `landed` governs output reach (whether the answer arrived). Input vs delivery.
- **`upshift`** picks the execution gear that produces the work; `landed` confirms the
  work's product reached its destination once produced.

## Reference index

- `references/destination-map.md` — the full artefact → destination → verification table, expanded with concrete commands.
- `references/examples.md` — worked landings: a publish, a deploy, an install, a "sent" email, and a deliberate "not yet landed → don't say done".
- `scripts/doctor.sh` — verify install + hook wiring.
- `hooks/landed_check.py` — Stop hook that blocks a ship-claim lacking destination evidence.
- `hooks/install_hook.sh` — wires the hook into `~/.claude/settings.json`.
