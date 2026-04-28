---
description: >-
  List open PRs on a target repo, use a worktree for each PR, review, and
  record Approved vs issues
alwaysApply: false
---

## Step 1: Fetch open PRs into the review queue

Run the following command to retrieve open PRs that match the review filter:

```bash
gh pr list \
  --repo 247sports/247-App \
  --search "is:open -author:busycaesar" \
  --limit 20 \
  --json number,headRefName,reviews \
  --jq '[.[] | select([.reviews[]? | select(.state == "APPROVED" and .author.login == "busycaesar")] | length == 0) | {number, headRefName}]'
```

The `-reviewed-by:@me` qualifier excludes PRs the current authenticated user has already reviewed (including approvals), so previously-approved PRs are skipped on subsequent runs.

Take the command's stdout (a JSON array of objects with `number` and `headRefName`) and write it to `prs-to-review.json` in the same directory as this rule file (`.cursor/rules/prs-to-review.json`), replacing the file if it exists. Save valid JSON for each entry — only the PR `number` and branch name (`headRefName`) — pretty-printed with 2-space indent. If the array is empty, still write `[]` so the queue file reflects the current run.

## Step 2: Review each PR by invoking `code-review`

Once `.cursor/rules/prs-to-review.json` is written, iterate over its entries **in order, top to bottom** and run the procedure defined in `.cursor/rules/code-review.mdc` against each one, passing that entry's `number` as the `$PR_NUMBER` argument and `headRefName` as the `$BRANCH` argument.

For every entry `{ number, headRefName }` in the queue:

1. Treat `number` as `$PR_NUMBER` and `headRefName` as `$BRANCH`, then follow `code-review.mdc` end-to-end for that branch:
   - Prepare the worktree at `./worktrees/$BRANCH`.
   - Diff against `origin/main` and produce the structured security-focused review.
   - Persist the result for `$BRANCH` to `.cursor/rules/pr-review.md` per its update procedure, including `$PR_NUMBER` in the row's `PR` column and in any `### #<PR_NUMBER> <BRANCH>` subsection (the existing row + subsection, if any, are replaced — never duplicated).
   - Clean up the worktree.

2. Continue to the next entry **even if a single branch's review fails** (e.g. fetch error, dirty worktree, missing branch). Record what happened in `.cursor/rules/pr-review.md` as an `Issues` row (with the same `$PR_NUMBER` in the `PR` column) whose `Notes` cell summarizes the failure (e.g. `"Review skipped — could not fetch branch"`), and move on. Do not abort the whole run.

3. Every branch in the queue is reviewed **every run**, even if it already appears in `pr-review.md`; `code-review.mdc`'s update procedure overwrites stale rows and subsections in place.

After Step 2, `.cursor/rules/pr-review.md` must contain one row per entry that was in `.cursor/rules/prs-to-review.json` for this run, each row reflecting the latest review outcome for that branch.
