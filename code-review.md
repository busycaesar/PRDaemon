---
alwaysApply: true
---

## Prepare a worktree for the branch

Given a PR number (`$PR_NUMBER`) and branch name (`$BRANCH`), prepare an isolated working copy in `./worktrees/$BRANCH` so the review can happen without disturbing the main checkout. `$PR_NUMBER` is carried through and recorded in the review log; `$BRANCH` drives the git operations.

1. Fetch the latest copy of the branch from `origin`:

   ```bash
   git fetch origin "$BRANCH"
   ```

2. Try to create a new worktree at `./worktrees/$BRANCH` tracking that branch:

   ```bash
   git worktree add "./worktrees/$BRANCH" "$BRANCH"
   ```

3. If the worktree already exists (the previous command fails because the path or branch is already checked out somewhere), reuse it instead — `cd` into the existing worktree directory and check out the branch:

   ```bash
   cd "./worktrees/$BRANCH"
   git checkout "$BRANCH"
   git pull --ff-only origin "$BRANCH"
   ```

After this step, the current working directory must be `./worktrees/$BRANCH` with `$BRANCH` checked out and up to date with `origin/$BRANCH`.

## Review the diff against `origin/main`

Once the worktree is ready and `$BRANCH` is checked out, diff the branch against `origin/main` and perform a security-focused PR code review on the result.

1. Make sure `origin/main` is up to date so the diff reflects the real merge target:

   ```bash
   git fetch origin main
   ```

2. Generate the diff of everything `$BRANCH` introduces on top of `origin/main` (use the three-dot form so the diff only shows commits unique to the branch, not unrelated changes that landed on main):

   ```bash
   git diff origin/main...HEAD
   ```

   Also list the changed files for orientation:

   ```bash
   git diff --name-status origin/main...HEAD
   ```

3. Read the diff and perform a code review focused on **vulnerable / unsafe code**. For every change, look for issues such as:
   - **Injection & untrusted input:** SQL/NoSQL injection, command injection, XSS, SSRF, path traversal, unsafe deserialization, prototype pollution, unvalidated redirects.
   - **AuthN / AuthZ:** missing permission checks, broken access control, privilege escalation, IDOR, tenant/user-scope leaks.
   - **Secrets & sensitive data:** hard-coded credentials, API keys, tokens, PII written to logs, secrets in URLs or client bundles.
   - **Cryptography:** weak/legacy algorithms, hard-coded keys/IVs, predictable randomness (`Math.random` for security), missing TLS verification.
   - **Input validation & data handling:** missing validation/sanitization, unsafe regex (ReDoS), unsafe file uploads, mass assignment.
   - **Dependencies & supply chain:** newly added packages, suspicious versions, lockfile changes, post-install scripts.
   - **Error handling & disclosure:** leaking stack traces, internal IDs, or DB errors to clients; swallowing security-relevant errors.
   - **Concurrency / state:** race conditions, TOCTOU, unsafe shared mutable state.
   - **Frontend-specific:** `dangerouslySetInnerHTML`, untrusted HTML/markdown rendering, unsafe `postMessage`/`window.open`, CORS/CSRF regressions.
   - **Backend-specific:** missing rate limiting, unsafe direct DB queries, ORM `raw`/string-built queries, unsafe shell calls (`exec`, `spawn` with shell strings).
   - **Tests & dead code:** removed/disabled security tests, TODOs around auth or validation, debug or backdoor code.

4. For each finding, record: file and line range, a short title, severity (`info` / `low` / `medium` / `high` / `critical`), the risk it creates, and a concrete recommended fix. If no issues are found in a section, say so explicitly rather than omitting it. Quote the relevant snippet from the diff so the reviewer can locate the change quickly.

The output of this step is a structured PR code review focused on security and correctness of the changes introduced by `$BRANCH` over `origin/main`.

## Persist the review to `pr-review.md`

After the review for `$BRANCH` is complete, record the result in `pr-review.md` (located alongside this rule at `.cursor/rules/pr-review.md`). The file accumulates results across runs — create it on first use, otherwise update it in place.

### File layout

The file always has two sections, in this order:

1. **A summary table** at the very top with one row per reviewed branch and exactly these columns:

   | PR | Branch | Status | Notes |
   | -- | ------ | ------ | ----- |
   - `PR` — the value of `$PR_NUMBER` rendered as `#<number>` (e.g. `#819`). Use `-` if no PR number is available.
   - `Branch` — the value of `$BRANCH`.
   - `Status` — either `Approved` (no findings worth blocking on) or `Issues` (one or more findings).
   - `Notes` — a short (≤ 1 sentence) summary; for `Approved` rows this can be a quick reason such as "no security-relevant changes", for `Issues` rows give a 1-line headline of the worst finding.

2. **An "Issues details" section** below the table with one subsection per branch whose status is `Issues`. Branches with status `Approved` must NOT appear in this section.

   Each issues subsection looks like:

   ```markdown
   ### #<PR_NUMBER> <BRANCH>

   - **<file path>** (`<line range>`) — <short title>: <one- or two-sentence brief describing the suspicious code chunk and why it may be vulnerable>.
   - ... (one bullet per finding)
   ```

   Quote or reference the exact code chunk only briefly — enough for the reviewer to locate it. Detailed reproduction belongs in the diff itself.

### Update procedure

1. If `.cursor/rules/pr-review.md` does not exist, create it with the table header (and an empty `## Issues details` heading) before adding the new row.
2. If a row for `$BRANCH` already exists in the table, **replace** that row and any existing `### #<PR_NUMBER> <BRANCH>` subsection (do not duplicate). Match existing subsections by `$BRANCH` regardless of their previous PR number, in case the PR number changed or was previously missing. Otherwise append a new row to the end of the table.
3. If the status is `Issues`, ensure a `### #<PR_NUMBER> <BRANCH>` subsection exists under `## Issues details` with one bullet per finding. If the status is `Approved`, ensure no subsection for `$BRANCH` exists under `## Issues details`.
4. Preserve all rows and subsections for other branches untouched.

### Template (for first creation)

```markdown
# PR review log

| PR | Branch | Status | Notes |
| -- | ------ | ------ | ----- |

## Issues details
```

## Clean up the worktree

After the report has been written to `pr-review.md`, remove the worktree that was created in the first step so it doesn't accumulate stale checkouts.

1. Move out of the worktree directory back to the main repo root before removing it (you cannot remove a worktree from inside itself):

   ```bash
   cd -  # or: cd /Users/dev/Desktop/projects/247
   ```

2. Remove the worktree at `./worktrees/$BRANCH`:

   ```bash
   git worktree remove "./worktrees/$BRANCH"
   ```

3. If the previous command refuses because the worktree has uncommitted/locked state (it should not, since the review is read-only), force the removal:

   ```bash
   git worktree remove --force "./worktrees/$BRANCH"
   ```

4. Prune any leftover administrative entries:

   ```bash
   git worktree prune
   ```

After this step, `./worktrees/$BRANCH` must no longer exist and `git worktree list` must not include it.
