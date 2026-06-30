# Destination map — where the product actually lives, and how to verify it there

The rule: *if you deleted your local copy right now, where would the product still
exist for the user?* That place is the destination. Verify there.

## Published repository
- **Lives at:** the remote default branch + CI status + releases.
- **Verify:**
  - `gh run watch "$(gh run list -L1 --json databaseId --jq '.[0].databaseId')" --exit-status` → CI green.
  - `gh api repos/<owner>/<repo>/contents/<path> --jq .sha` → the file is on the remote.
  - `gh release view <tag> --json tagName` → the release exists.
  - Optional gold standard: `git clone` fresh into /tmp, run the tests there.
- **Common miss:** `git push` returned 0 but CI is red, or you pushed a branch that never merged.

## Deployed web app
- **Lives at:** the production URL (and its CDN/edge cache), not `localhost`.
- **Verify:** `curl -sS -o /dev/null -w '%{http_code}' https://<prod>` → 200; fetch the page and grep for the change you shipped; check the deployment id is the new one.
- **Common miss:** verifying the dev server; or the deploy succeeded but the change is behind a cache / old build.

## CLI / installed tool
- **Lives at:** the install path on `$PATH`.
- **Verify:** `which <tool>` resolves; run `<tool> --version` from a clean shell (new dir); execute a real command.
- **Common miss:** it works via `./bin/tool` in the repo but isn't actually on `$PATH`.

## Claude Code skill / hook
- **Lives at:** `~/.claude/skills/<name>/` and (for hooks) `~/.claude/settings.json`.
- **Verify:** `ls ~/.claude/skills/<name>/SKILL.md`; run its `scripts/doctor.sh`; confirm the hook command appears in settings.json; fire the hook on a sample input.
- **Common miss:** the skill is built in a repo checkout but never copied to the install path; the hook file exists but was never wired.

## Database write
- **Lives at:** the row in the table.
- **Verify:** re-`SELECT` the row by id and compare fields; confirm the transaction committed.
- **Common miss:** the ORM call returned an object from memory but the commit rolled back / hit a constraint.

## Sent message / email
- **Lives at:** the recipient's inbox; your **Sent** folder is the proxy you can see.
- **Verify:** check Sent (not Drafts); confirm a thread/message id; if possible, a delivery receipt.
- **Common miss:** it sat in Drafts; or "send" created the draft but the send action never fired.

## Config change
- **Lives at:** the running process that reads the config — not the file on disk.
- **Verify:** reload/restart the consumer and observe the new behaviour; re-read the effective value the process reports.
- **Common miss:** edited the file but the daemon still runs the old config; wrong file / wrong scope (user vs project).

## Generated document
- **Lives at:** the rendered output and/or the shared link.
- **Verify:** open the rendered PDF/Word/slide (see `doc-eye`); click the shared link in a logged-out context to confirm permissions resolve.
- **Common miss:** the markdown source is right but the render is broken; the "shared" link is private.

## Package release
- **Lives at:** the registry (npm / PyPI / crates.io).
- **Verify:** in a clean environment, install the exact published version from the registry and import/run it.
- **Common miss:** `npm publish` printed success but the version is unlisted/deprecated, or the published tarball omitted files (check `.npmignore`/`files`).

## Migration / refactor
- **Lives at:** the whole tree + a clean build.
- **Verify:** full build + test from a clean checkout; `grep -r` proves **zero** old call-sites/imports remain.
- **Common miss:** edited the obvious files but left old call-sites that still compile, so "it builds" hides a half-migration.
