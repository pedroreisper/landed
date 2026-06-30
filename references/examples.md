# Worked landings

## Publish a repo — landed
> Built a skill, `git push` succeeded.

**Not done yet.** The product lives on GitHub behind CI. Land it:
`gh run watch <id> --exit-status` → green; `gh api repos/o/r/contents/SKILL.md` → present;
`gh release view v1.0.0` → exists. *Now* say done. (This is the exact miss that
created this skill: "16/16 local tests pass → done" while the remote CI was red.)

## Deploy a web app — landed
> `vercel deploy` returned a URL.

Fetch the **production** URL, not the preview: `curl -sS -w '%{http_code}' https://app.com`
→ 200, and grep the response for the change. Confirm the deployment id is the new one.
Only then: "deployed and live, verified."

## Install a CLI — landed
> `make install` compiled cleanly.

Open a **new** shell, `which mytool` resolves to the install path, `mytool --version`
prints the new version, run one real command. The build compiling is the workbench;
running it from `$PATH` is the destination.

## "Sent" an email — landed
> Clicked send.

Check the **Sent** folder (or the API's sent label), not Drafts. Confirm a message/
thread id exists. A "sent" that's still in Drafts is the classic last-mile failure.

## Not yet landed — don't say done
> Migrated 38 of 40 files; build is green.

Build-green can hide a half-migration. `grep -r "oldRouter" .` → if any call-site
remains, it has **not** landed. Report "38/40 migrated, 2 call-sites remain" — precise,
not "done". Done is when the grep is empty and the clean build passes.

## Correct down-scope — landed needs no check
> Wrote a one-off analysis script and ran it locally for the user.

The workbench **is** the destination — there's no remote, no install, no recipient.
Reporting the result is landing it. Don't invent a destination check that doesn't exist.
