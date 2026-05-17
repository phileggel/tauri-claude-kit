# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository, which is an opinionated Claude-assisted factory for Tauri 2 + Axum/React 19 projects, built around Spec Driven Development. It ships the full stack: SDD workflow agents, quality reviewers, convention docs, scripts, hooks, and justfile recipes.

## Simple Technical Workflow

_Use for: Bug fixes, dependency updates, minor maintenance (no new business rules or features)._

1.  **Analysis**: Read relevant documentation and analyze the codebase.
2.  **Direct Plan**: Propose a concise TODO plan with exact file paths in the chat. Ask user to validate.
3.  **Tracking**: Use internal `TaskCreate` / `TaskUpdate` tools to track workflow steps (mark `in_progress` when starting, `completed` when done) for user visibility.
4.  **Implementation**: Execute the code changes.
5.  **Review & Quality**: Run static checks (`python3 scripts/check.py`), write tests, and run `/preflight` before any release.
6.  **Closure**: Ask user if another task is needed before commit, otherwise use **`/smart-commit`** skill.

## Critical Patterns

- **Always work on a feature branch**: Never commit directly to `main`. Create a branch for every change and merge via PR.
  - ✅ Correct: `git checkout -b feat/your-feature` → implement → `/smart-commit` → merge to main
  - ❌ Wrong: committing directly to `main` (the pre-commit hook will hard-block it)
  - _Why it's critical:_ Review agents use branch scope (`branch-files.sh`) to discover all modified files. On `main`, the branch base equals HEAD and agents see nothing.

- **Always use `just`**: Never suggest or execute native commands if a corresponding recipe exists in `justfile`.

- **Never commit without explicit user authorization.** Always use `/smart-commit` and wait for a clear "go" before any `git commit` or `git push` — including hotfixes, release commits, and one-liners. No exceptions.

- **Project Name Neutrality:** Agent files MUST NOT reference a specific project name (e.g., "MyApp").
  - ✅ Correct: "You are a senior code reviewer for a full-stack project."
  - ❌ Wrong: "You are a senior code reviewer for MyApp."
  - _Why it's critical:_ Agents are reusable; embedding project names creates stale references when copied or renamed.

- **Tool Minimality:** Agent `tools:` fields should only list necessary tools. Review-only agents should not have `Edit` or `Write`.
  - ✅ Correct: `tools: Read, Grep, Glob, Bash` for a review agent.
  - ❌ Wrong: `tools: Read, Grep, Glob, Bash, Edit, Write` for a review agent.
  - _Why it's critical:_ Over-privileged agents are slower and pose a security risk.

- **Kit-local tooling only:** When working on this repository, only use tools from `.claude/` (skills, agents) and `scripts/` (check.py, release-kit.py). Never invoke agents or skills from `kit/agents/` directly — those are downstream artifacts, not kit tooling.
  - ✅ Correct: `/preflight`, `/smart-commit`, `python3 scripts/check.py`
  - ❌ Wrong: running `reviewer`, `spec-checker`, or any `kit/agents/**/*.md` agent on kit files
  - _Why it's critical:_ Kit agents are written for downstream project structure which does not exist in this repository.

```bash
# Sync latest tag
./scripts/sync-config.sh

# Sync a specific tag
./scripts/sync-config.sh v4.0.0
```

The script self-updates before syncing: if `sync-config.sh` itself changed in the kit, it re-executes the new version automatically. After syncing, review `git diff` before committing.

## Versioning

Use semantic versioning via git tags:

| Bump    | When                                          |
| ------- | --------------------------------------------- |
| `patch` | Bug fix in a script or agent wording          |
| `minor` | New agent/skill, significant improvement      |
| `major` | Breaking change (renamed file, removed agent) |

Run releases via `just release` (interactive). Pass `-y` to auto-confirm the suggested version without a prompt — useful when running non-interactively:

```bash
just release -y
```

## Git hooks

Hooks in `kit/githooks/` are synced to `.githooks/` in downstream projects (via `just sync-kit`) and to this repo's `.githooks/` for kit development (via `just mirror-local`). Both sync paths now **auto-activate** the hooks (set `core.hooksPath = .githooks`) if no other hooks path is configured. Opt out with `SYNC_NO_HOOKS=1`.

- **pre-commit**: runs `python3 scripts/check.py --fast` (lint/format only)
- **commit-msg**: enforces conventional commit format (`type: description`, max 72 chars, no co-author lines, no test results in message)

Valid commit types: `feat`, `fix`, `docs`, `test`, `chore`, `refactor`, `ci`

## Repository layout

```
kit/                        ← everything synced downstream
  sync-config.sh            → scripts/sync-config.sh (bootstrap, copied once)
  agents/                   → .claude/agents/
  skills/                   → .claude/skills/
  docs/                     → docs/ (copy-once — never overwrites)
  githooks/                 → .githooks/
  common.just               → common.just
  scripts/
    sync.sh                 ephemeral sync logic (runs from $TMP, never copied)
    branch-files.sh         → scripts/
    changed-files.sh        → scripts/
    report-path.sh          → scripts/
    validate-sync.sh        → scripts/
    whats-next.py           → scripts/
    check.py                → scripts/check.py
    release.py              → scripts/release.py
scripts/                    ← kit-only tooling (not synced)
  check.py                kit quality checker
  release-kit.py            kit release manager
```

## Downstream tools (**CRITICAL** for reference only)

All agents, skills, scripts, git hooks, and justfile recipes provided to downstream projects are inventoried in [`kit/kit-tools.md`](kit/kit-tools.md). Refer to that file for the full list — do not duplicate it here.

## Local tools (kit development only)

These are available in `.claude/` for working on the kit itself. They are **not synced** to downstream projects.

| Type  | Name           | When to use                                                                                            |
| ----- | -------------- | ------------------------------------------------------------------------------------------------------ |
| skill | `preflight`    | Before any release — validates IA readiness, script quality, cross-component coherence (`/preflight`)  |
| skill | `smart-commit` | To create a validated conventional commit (`/smart-commit`)                                            |
| skill | `whats-next`   | At session start to triage what to work on next across TODOs, plans, and in-flight git (`/whats-next`) |
| skill | `create-pr`    | Push the current feature branch and open a GitHub PR (`/create-pr`)                                    |

> `smart-commit`, `whats-next`, and `create-pr` are mirrored from `kit/skills/`, and all hooks from `kit/githooks/` — run `just mirror-local` to sync both after changing sources. Hooks auto-activate on first mirror; opt out with `SYNC_NO_HOOKS=1`.
