# PRDaemon

<img width="4640" height="928" alt="Gemini_Generated_Image_z13ognz13ognz13o" src="https://github.com/user-attachments/assets/d5e3cfda-ebd5-468c-89b4-9c1d0d3528be" />

## Description

PRDaemon is a background automation tool that silently monitors open pull requests in a GitHub repository on a schedule, reviewing each one by fetching its diff against the base branch and recording an outcome of approved or issues. For every run, it produces a human-readable Markdown report alongside machine-readable JSON progress files, giving you copy-paste-ready GitHub comments without any manual queue management.

## Features

- **Automated PR discovery** — queries GitHub for open PRs that haven't been approved yet, filtering out the bot author and already-reviewed entries, and writes the queue to `prs-to-review.json`.
- **Isolated worktree reviews** — each PR branch is checked out into its own `./worktrees/<branch>` directory so reviews never disturb the main checkout.
- **Security-focused diff analysis** — diffs each branch against `origin/main` and checks for injection, broken auth, hard-coded secrets, weak crypto, unsafe input handling, supply-chain risks, insecure error handling, race conditions, and frontend/backend-specific vulnerabilities.
- **Structured report output** — findings are recorded in `pr-review.md` with a summary table (PR, branch, status, notes) and a detailed issues section with file paths, line ranges, severity, and recommended fixes.
- **Resilient batch processing** — reviews continue even if a single branch fails (fetch error, dirty worktree, etc.); failures are recorded as `Issues` rows with a short explanation.
- **Automatic worktree cleanup** — each worktree is removed and pruned after its review completes, keeping the repo tidy across runs.

## How to run the project?

### Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated (`gh auth login`).
- Access to the target repository (`247sports/247-App` by default).
- Git 2.5+ (for worktree support).

### Running a review

Open the project in Claude Code and invoke the PR review skill:

```
/pr-review
```

Claude will:

1. Fetch all open, un-approved PRs from the configured repository and write them to `prs-to-review.json`.
2. For each PR, create an isolated worktree, diff the branch against `origin/main`, and perform a security-focused code review.
3. Persist the outcome (Approved / Issues) to `pr-review.md`, updating any existing rows for the same branch in place.
4. Clean up each worktree after its review finishes.

### Output files

| File                 | Purpose                                                                   |
| -------------------- | ------------------------------------------------------------------------- |
| `prs-to-review.json` | Queue of PRs fetched in the latest run (PR number + branch name).         |
| `pr-review.md`       | Cumulative review log: summary table at the top, detailed findings below. |

## Author

[Dev J. Shah](https://github.com/busycaesar)
