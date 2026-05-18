# List of TODOs

## Candidates

- **SDD Workflow B walk — verify reviewer dual-use.** Reviewer agents (`reviewer-arch`, `reviewer-backend`, `reviewer-frontend`, `reviewer-e2e`, `reviewer-sql`, `reviewer-infra`, `reviewer-security`) are used by both Workflow A (Phase 4) and Workflow B (step 5). Workflow B has no `docs/plan/{feature}-plan.md`, no `docs/contracts/{domain}-contract.md`, no `docs/spec/{domain}.md`. Verify each reviewer handles the no-plan / no-contract context gracefully (no hard reads, no halts on absent files). Likely surface mostly verification with small graceful-skip patches.

- **Tools walk.** One-shot setup helpers and maintenance skills — different lens than workflow agents ("is this easy to invoke and complete?"). Targets:
  - `kit/skills/setup-e2e/SKILL.md` — 368 lines, 162-line longest section. Deferred from v4.5 Phase 3.
  - `kit/skills/prune/SKILL.md`, `kit/skills/dep-audit/SKILL.md`, `kit/skills/kit-discover/SKILL.md`, `kit/skills/whats-next/SKILL.md`, `kit/skills/techdebt/SKILL.md`, `kit/skills/visual-proof/SKILL.md`, `kit/skills/start/SKILL.md`, `kit/agents/retro-spec.md`

- **Partial-stack audit + `--strict` toggle generalization (no-DB Tauri, etc.).** Generalizes the work shipped in v4.5 for issue #15 (graceful skip on absent stack). v4.5 added marker-file detection (`package.json`, `src-tauri/Cargo.toml`, `src-tauri/.sqlx/`) and per-checker skip-with-summary; this candidate completes the partial-stack story across the rest of the kit and adds release-time strictness.

  Three axes to audit (output is a concrete fix list, not the fixes themselves):
  1. **Scripts beyond `check.py`** — sweep all `kit/scripts/*` and any DB-touching agent helper scripts to confirm they all skip-not-fail when `.sqlx/`, `migrations/`, or DB env vars are absent. Catch partial-stack edge cases (`migrations/` exists but `.sqlx/` doesn't, or the reverse).
  2. **Agents/skills with hard SQLx assumptions** — sweep `kit/agents/*.md` and `kit/skills/*/SKILL.md` for misleading advice (e.g. backend reviewer expecting SQLx idioms, test-writer-backend defaulting to SQLx integration tests, contract skill assuming a DB boundary, dep-audit assuming sqlx in Cargo.toml). For each, decide: gate behind detection, or add an "if your project uses a DB" caveat.
  3. **Dead surface for no-DB projects** — what ships as pure noise? `just prepare-sqlx` recipe in `kit/common.just`, SQLx-specific reviewer rules, SQLx-flavored test-writer templates. Decide per item: ship-and-skip-when-irrelevant, gate at sync time, or split into a separate opt-in module.

  **`--strict` toggle** — `check.py` currently treats absent stack as `SKIPPED` (correct for `--fast` / pre-commit). In strict mode (used by `release.py`), absent stack should arguably FAIL: releases shouldn't ship without exercising the full quality gate. But a deliberately no-DB Tauri project should still be releasable. Decide the policy:
  - Option A: `--strict` requires all markers — simple but excludes legitimate no-DB releases.
  - Option B: `--strict` distinguishes core stack (`package.json` + `Cargo.toml` required) from optional stack (`.sqlx/` optional). Allows no-DB releases while still gating "you forgot to scaffold React".
  - Option C: project-level config flag declares which markers are expected. Most flexible, more moving parts.

  Closes GH #15 + #27 as side-effects. Categorisation per fix item: graceful-skip / doc-gate / sync-time-exclude / accept-as-noise / strict-required.

- **Collapse `branch-files.sh` + `changed-files.sh` into `branch.sh files` subcommand.** v4.7.3 introduced `branch.sh {base|diff|log}` to absorb compound shell from reviewer prompts (issue #37). `branch-files.sh` and `changed-files.sh` differ by exactly one line (whether the committed branch diff is included) — natural candidates to fold in as `branch.sh files` and `branch.sh files --uncommitted-only`. Net −2 scripts. Breaking change for downstream callers (agents naming the scripts directly) — handle as a coordinated rename + sync cycle, not piecemeal.

- **v4.8 review-cycle deferred polish.** Surfaced by the global ai-reviewer + script-reviewer pass on `feat/v4.8-candidates`; triaged as should-fix or consider, not blocking release:
  - **spec-reviewer wording** — Category B leak-list: `response` too broad (split to `request body` / `response body`); C wire-shape: "command responses" leaks vocab (rephrase to "observable to the user"); G demoted 🟡 trailing sentence duplicates Critical Rule 6 (trim).
  - **spec-writer Rule 7** — 111-word lead sentence (convert to nested bullets); anti-list missing transport vocabulary (`endpoint`, `route`, `HTTP`, `API call`); Good/Bad table examples skew Rust-Tauri.
  - **reviewer-frontend** — verify cross-ref `## Before Major Project Releases` in `kit-readme.md` (confirmed exists at L175 during review; mention for future drift).
  - **reviewer-infra** — Step 7 has dead trigger phrasing predating the v4.8 Scope formalization ("cumulative branch diff against the previous tag, or explicit release sweep"); Scope is now the single source of truth.
  - **reviewer-backend** — frontmatter description leads with negative anti-patterns; positive trigger (flat-`{BC}Error` model) would route better. `### Error handling` first bullet bundles three rules at one severity; consider split.
  - **reviewer-e2e Rule 8** — neighbour example reads tautologically ("the changed test file plus its `_helpers/` references"); rephrase as X-for-Y-change pair like siblings.
  - **release.py** — exit code 2 for malformed `--version` (POSIX); `dataclass Commit` to replace loose `list[dict]`; stdout/stderr split so `release.py --preview` is machine-parseable; Cargo.toml `re.subn` to bail if version-match count != 1; commit error wrapper drops `e.stderr`.
  - **merge.py** — `git rebase --abort` failure swallowed (line 169); `.format()` mixed with f-strings (line 131); `LC_ALL=C` on git invocations to harden English-error-string parsing.
  - **sync.sh** — `echo -e` portability (use `printf '%b\n'` if shebang ever drifts to `/bin/sh`); add `command -v python3 >/dev/null` preflight; atomic-rename manifest file to avoid partial-write on early exit; chmod +x for `.py`/`.mjs` if they ever grow shebangs that get invoked directly.
  - **check.py** — `env_update: dict[str, str] | None` (typed parameterization); `_safe_print` `file: object | None`; TSC verbose-mode loses error output (line 419).

## Experimental
