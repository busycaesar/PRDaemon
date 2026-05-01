---
description: >-
  List open PRs on a target repo, use a worktree for each PR, review, and
  record Approved vs issues
alwaysApply: false
---

## Step 1: Fetch open PRs into the review queue

Ensure `config.json` at the project root defines:

- `repo` — the target GitHub repository in `owner/name` form (passed to `gh` as `--repo`).
- `authorUsername` — the GitHub username whose PRs should be excluded from the queue and whose existing approvals should cause a PR to be skipped.

From the project root, run `fetch-prs-to-review.sh` so the queue file is created or refreshed:

```bash
./fetch-prs-to-review.sh
```

If the script is not executable, use `bash fetch-prs-to-review.sh` instead.

On success it writes the queue to **`cache/pr-review/prs-to-review.json`** (see `fetch-prs-to-review.sh` for query filters and JSON shape).

You need `gh` and `jq` on your `PATH`, with `gh` authenticated for the configured repository.

## Step 2: Review each PR by invoking `code-review`

Once `cache/pr-review/prs-to-review.json` is written, iterate over its entries **in order, top to bottom** and run the procedure defined in `code-review.md` at the project root against each one, passing that entry's `number` as the `$PR_NUMBER` argument and `headRefName` as the `$BRANCH` argument.

For every entry `{ number, headRefName }` in the queue:

1. Treat `number` as `$PR_NUMBER` and `headRefName` as `$BRANCH`, then follow `code-review.md` end-to-end for that branch.

2. Continue to the next entry **even if a single branch's review fails** (e.g. fetch error, dirty worktree, missing branch). Record what happened in `pr-review.md` as an `Issues` row (with the same `$PR_NUMBER` in the `PR` column) whose `Notes` cell summarizes the failure (e.g. `"Review skipped — could not fetch branch"`), and move on. Do not abort the whole run.

After Step 2, `pr-review.md` must contain one row per entry that was in `cache/pr-review/prs-to-review.json` for this run, each row reflecting the latest review outcome for that branch.
