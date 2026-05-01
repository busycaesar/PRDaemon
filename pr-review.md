---
description: >-
  List open PRs on a target repo, walk the JSON queue with scripts/review-pr-queue.sh,
  then follow code-review.md per exported PR_NUMBER / BRANCH.
alwaysApply: false
---

## Step 1: Fetch open PRs into the review queue

From the project root, run `scripts/fetch-prs-to-review.sh` so the queue file is created or refreshed:

```bash
./scripts/fetch-prs-to-review.sh
```

If the script is not executable, use `bash scripts/fetch-prs-to-review.sh` instead.

On success it writes the queue to **`cache/pr-review/prs-to-review.json`**.

## Step 2: Walk the queue with `scripts/review-pr-queue.sh`

After `cache/pr-review/prs-to-review.json` exists, run the script from the project root:

```bash
./scripts/review-pr-queue.sh
```

If it is not executable, use `bash scripts/review-pr-queue.sh` instead.
