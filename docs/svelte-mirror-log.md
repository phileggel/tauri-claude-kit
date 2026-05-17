# Svelte Mirror Log

Audit trail for `/svelte-update` decisions on every cherry-pick from `main` into `svelte-main`. Each entry records: what was mirrored, what was skipped (with reason), and what was flagged for custom treatment.

This file lives on `svelte-main` only — never cherry-picked back to `main`.

---

## svelte-v0.1.1+4.5.2 → svelte-v0.2.0+4.7.2

Baseline: `+4.5.2`. New baseline: `+4.7.2`. Cherry-picked 9 substance commits (release commits skipped — svelte-main owns its own release lineage).

### Mirrored to `-svelte` variant

- `kit/agents/reviewer-frontend.md` @ c1b12e3 — reviewer-e2e lane split applied verbatim to `reviewer-frontend-svelte.md`. Scope tightened to `src/`, E-rules / `e2e/` references moved to `reviewer-e2e`'s lane. Framework-neutral; no Svelte-specific substitutions needed beyond what was already there.
- `kit/agents/reviewer-security.md` @ f016b07 — v4.7 template alignment (When-to-use / Process steps / Critical Rules / Notes / false-positive list / cross-layer findings) applied to `reviewer-security-svelte.md`. All structural changes mirrored; XSS examples kept Svelte-specific (`{@html}` instead of `dangerouslySetInnerHTML`); `.tsx` swapped for `.svelte` throughout; output-format examples updated to use `$state` instead of `React state`. Added `{@html sanitizedMarkdown}` to false-positive list as the Svelte equivalent of "documented-sanitizer-in-scope".
- `kit/agents/test-writer-e2e.md` @ c6ce3f1 — scenario-writer pivot (pick critical-path commands / write scenarios / halt for missing helpers / sibling-pattern sections) applied to `test-writer-e2e-svelte.md`. The `setReactInputValue()` helper and its references dropped throughout (Svelte 5 `bind:value` + `$state` synchronous DOM update means native `setValue()` works); template uses `await (await $("#id")).setValue(value)` directly. Added Notes section explaining why no React-style input workaround is needed.

### Skipped (React-specific, no Svelte mirror needed)

(None — all React-side changes on forked files this cycle had framework-neutral structure or were translatable.)

### Custom (flagged for manual treatment)

- `kit/scripts/check.py` — internal metric key `react_tests` is inconsistent with the user-facing label `"Frontend Tests"` (svelte-main's framework-neutral wording, in place since the v4.6.0 a517098 convergence). Rename `react_tests` → `frontend_tests` across all 5 sites (lines 84, 284, 297, 357, 363) on svelte-main only. Cosmetic — does not affect functionality. Defer to a svelte-only follow-up branch; not part of this migration PR.

### Shared (no `-svelte` variant — cherry-pick applied as-is)

23 files: kit-tools, kit-readme, scripts, hooks, common.just, skills (create-pr / start), CI workflow, plus the new `kit/agents/reviewer-e2e.md` (framework-agnostic WebDriver scenario reviewer — no fork needed).

---

## svelte-v0.2.0+4.7.2 → svelte-v0.2.1+4.7.3

Baseline: `+4.7.2`. New baseline: `+4.7.3`. Cherry-picked the single substance commit from main (`d337eb5`, PR #38) — closes GH #37.

### Mirrored to `-svelte` variant

- `kit/agents/reviewer-frontend.md` @ d337eb5 — Step 3 compound-shell wrapper applied verbatim to `reviewer-frontend-svelte.md`. Framework-neutral.
- `kit/agents/reviewer-security.md` @ d337eb5 — Step 3 compound-shell wrapper applied verbatim to `reviewer-security-svelte.md`. Framework-neutral.

### Skipped (React-specific, no Svelte mirror needed)

(None — the entire #37 fix is framework-neutral plumbing.)

### Custom (flagged for manual treatment)

(None this cycle.)

### Shared (no `-svelte` variant — cherry-pick applied as-is)

Everything else: `branch.sh` (new), `branch-files.sh` (sources `branch.sh base`), `scripts/check.py` lint rule, the 7 main-side reviewer patches, `test-writer-backend.md`, `create-pr/SKILL.md`, `kit-tools.md`, `kit-readme.md`, `docs/TODO.md`.

---

## svelte-v0.2.0+4.7.3 → svelte-v0.2.1+4.7.4

Baseline: `+4.7.3`. New baseline: `+4.7.4`. Cherry-picked one main commit (`0f3a0a2`, PR #40) — convention-doc compound-shell follow-up to #37.

### Mirrored to `-svelte` variant

- `kit/docs/test_convention.md` @ 0f3a0a2 — one-line example `cd src-tauri && cargo test` → `cargo test --manifest-path src-tauri/Cargo.toml`. Mirrored verbatim to `test_convention-svelte.md`. Framework-neutral.

### Skipped (React-specific, no Svelte mirror needed)

(None.)

### Custom (flagged for manual treatment)

(None.)

### Shared (no `-svelte` variant — cherry-pick applied as-is)

`kit/docs/test_convention.md` (React-side; coexists with the Svelte fork in this branch).

---

## svelte-v0.3.0+4.8.0 → svelte-v0.4.0+4.9.0

Baseline: `+4.8.0`. New baseline: `+4.9.0`. Cherry-picked the single squash commit `bd45f68` (PR #43) — v4.9 docs alignment.

### Conflicts resolved during cherry-pick

(None — clean cherry-pick.)

### Mirrored to `-svelte` variant

- `kit/docs/frontend-rules.md` @ bd45f68 — full F0 introduction + F28 restructure mirrored to `frontend-rules-svelte.md`: F0 tree adapted to Svelte (`.svelte` components, `.svelte.ts` reactive modules, `snackbarStore.svelte.ts`, `ui/modules/` instead of `ui/hooks/`, `Router.svelte`, `main.ts` Svelte 5 entry, `infra/i18n/`). F1 trimmed to one-sentence cite of F0. F24↔E4 reverse cross-link + F18→visual-proof reference added. Banner dropped.
- `kit/docs/e2e-rules.md` @ bd45f68 — banner dropped, `docs/` prefix removed from peer-file refs, E4↔F24 reverse cross-link added to `e2e-rules-svelte.md`. Verbatim mirror.
- `kit/docs/test_convention.md` @ bd45f68 — snackbar mock path moved from `@/infra/snackbar` to `@/ui/components/snackbar/snackbarStore.svelte` (matching the Svelte F0 widget colocation). Tier 4 row + body section added pointing at `e2e-rules-svelte.md` (B36 ephemeral DB).
- `kit/docs/frontend-visual-proof.md` @ bd45f68 — banner dropped (replaced with F18 reverse-link callout), config defaults + example imports updated to F0 paths (`src/styles/index.css`, `src/infra/i18n/index.ts`, `import { setupI18n } from "../infra/i18n"`).
- `kit/agents/reviewer-frontend.md` @ bd45f68 — single F28→F0 citation fix mirrored to `reviewer-frontend-svelte.md` ("F0 layout uses `src/ui/modules/`" — the Svelte path).
- `kit/agents/test-writer-frontend.md` @ bd45f68 — 4 F28→F0 citations mirrored to `test-writer-frontend-svelte.md` (read-list gloss, "anywhere in src/" placement, vitest target prose, colocation rule).

### Skipped (no fork — change flows through cherry-pick as-is)

- `kit/docs/backend-rules.md`, `kit/docs/ddd-reference.md`, `kit/docs/error-model.md`, `kit/docs/i18n-rules.md` — backend/neutral layering and convention. No fork.
- `kit/skills/visual-proof/SKILL.md` — i18n glob + config defaults updated to F0 paths. Skill body is framework-neutral (works for both React and Svelte projects via the per-project config).
- `scripts/branch.sh` (NEW), `scripts/mirror-local.sh` — kit-internal infra. Shared.
- `.claude/agents/doc-reviewer.md` — new Category F (40-char table cell). Kit-internal reviewer. Shared.

### Custom (flagged for manual treatment)

(None this cycle — all mirrors clean.)

---

## svelte-v0.2.1+4.7.4 → svelte-v0.3.0+4.8.0

Baseline: `+4.7.4`. New baseline: `+4.8.0`. Cherry-picked the single squash commit `c3a695d` (PR #42) — closes GH #15, #22, #23, #25, #27, #28, #29, #32, #35, #41.

### Conflicts resolved during cherry-pick

- `kit/kit-readme.md` — kept Svelte "frontend-rules" wording from svelte-main; added the new `error-model.md` row from main. Convention-doc count is now 8 (matches main).
- `kit/scripts/check.py` — kept svelte-main's `"Frontend Tests"` label (framework-neutral, per a517098 convergence); genericized the gh#27 comment from "scaffolded React stack" to "scaffolded frontend stack"; applied main's `SKIP_FRONTEND_ABSENT` constant and `--passWithNoTests` flag.

### Mirrored to `-svelte` variant

- `kit/agents/reviewer-frontend.md` @ c3a695d — added the v4.8-new `## Scope` section (diff-scoped default + opt-in `release-sweep` literal trigger) and Critical Rule 8 (Scope-drift guard with cap-overflow guidance) to `reviewer-frontend-svelte.md`. Framework-neutral — the neighbour examples ("presenter for a component change, the hook for a gateway change") apply equally to Svelte (`.svelte` presentational + `.svelte.ts` modules). Verbatim mirror.
- `kit/agents/reviewer-security.md` @ c3a695d — added the v4.8-new `## Scope` section, the `## When to use` "Skip for" clause (return-type / rename / helper-split refactors with no security delta), the `## Cross-layer findings` intro paragraph (default-mode-vs-release-sweep), and Critical Rule 10 (Scope-drift guard with cap-overflow guidance) to `reviewer-security-svelte.md`. All framework-neutral. Verbatim mirror.

### Skipped (no fork — change flows through cherry-pick as-is)

- `kit/docs/error-model.md` (NEW) — backend-only contract (Rust types + Tauri command boundary). FE handling section narrows on `code` discriminator via Specta-derived bindings; no framework-specific idiom. No `-svelte` fork needed; ships verbatim.
- `kit/docs/backend-rules.md`, `kit/docs/ddd-reference.md` — backend layering / error-model framing. Framework-neutral; no fork.
- `kit/agents/reviewer-backend.md`, `kit/agents/reviewer-arch.md`, `kit/agents/reviewer-infra.md`, `kit/agents/reviewer-sql.md`, `kit/agents/reviewer-e2e.md`, `kit/agents/spec-reviewer.md` — no `-svelte` fork; cherry-pick applies as-is.
- `kit/skills/spec-writer/SKILL.md` — gh#41 Rule 7 expansion. Spec writing is framework-neutral (UL + behavior); no fork.
- All other touched files (kit-tools, kit-readme handled in conflicts, common.just, scripts, hooks, top-level `docs/TODO.md`, `CLAUDE.md`, `scripts/branch-files.sh`, `scripts/mirror-local.sh`) — shared.

### Custom (flagged for manual treatment)

(None this cycle — both fork-bearing agents had clean verbatim mirrors.)

---

## Architectural note — when to fork vs share

A new agent or doc should get a `-svelte` fork **only** when its substance is framework-specific (idioms, syntax, helper code). `reviewer-e2e` reviews WebDriver scenarios at the test-code level (selectors, async correctness, no-mock discipline) — these are framework-agnostic, so no fork.

When a forked file's `main` side changes and the change is purely structural / framework-neutral, the mirror is verbatim. When it carries framework-specific code (React hooks, `{@html}`, `setReactInputValue`), the mirror needs targeted substitution. The skill makes this decision visible per commit; this log records the result.
