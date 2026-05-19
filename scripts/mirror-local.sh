#!/usr/bin/env bash
set -euo pipefail

# mirror-local.sh — Mirror kit artifacts into the local kit repo so they are
# active during kit development. Run via: just mirror-local
#
# To add an entry: append a row to MIRROR_TABLE below.
# Columns are tab-separated: SOURCE  DESTINATION  [MODE]
# MODE is optional. The only recognized value is `+x` (set executable bit).
#
# Explicitly excluded (do not add to the table):
#   kit/scripts/sync.sh       — ephemeral kit infra, runs only from $TMP
#   kit/scripts/check.py      — kit-internal scripts/check.py is different (would clobber)
#   kit/scripts/release.py    — kit-internal scripts/release-kit.py is different
#   kit/scripts/list-fe-test-targets.py — no kit-internal trigger
#   kit/scripts/merge.py — invoked by /justfile via `python3 kit/scripts/merge.py`
#     directly from source, no mirror needed
#   kit/githooks/README.md    — documentation, not a hook

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

MIRROR_TABLE=$(
    cat <<'EOF'
kit/skills/smart-commit/SKILL.md	.claude/skills/smart-commit/SKILL.md
kit/skills/whats-next/SKILL.md	.claude/skills/whats-next/SKILL.md
kit/skills/create-pr/SKILL.md	.claude/skills/create-pr/SKILL.md
kit/skills/review-triage/SKILL.md	.claude/skills/review-triage/SKILL.md
kit/githooks/commit-msg	.githooks/commit-msg	+x
kit/githooks/pre-commit	.githooks/pre-commit	+x
kit/githooks/pre-merge-commit	.githooks/pre-merge-commit	+x
kit/githooks/pre-push	.githooks/pre-push	+x
kit/scripts/branch.sh	scripts/branch.sh	+x
kit/scripts/branch-files.sh	scripts/branch-files.sh	+x
kit/scripts/changed-files.sh	scripts/changed-files.sh	+x
kit/scripts/report-path.sh	scripts/report-path.sh	+x
kit/scripts/review-path.sh	scripts/review-path.sh	+x
kit/scripts/list-fresh-reviews.sh	scripts/list-fresh-reviews.sh	+x
kit/scripts/validate-sync.sh	scripts/validate-sync.sh	+x
kit/scripts/whats-next.py	scripts/whats-next.py
EOF
)

while IFS=$'\t' read -r src dst mode; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    full_src="$PROJECT_ROOT/$src"
    full_dst="$PROJECT_ROOT/$dst"
    if [ ! -f "$full_src" ]; then
        echo "⚠  Skipping $src — source not found"
        continue
    fi
    mkdir -p "$(dirname "$full_dst")"
    cp "$full_src" "$full_dst"
    [ "$mode" = "+x" ] && chmod +x "$full_dst"
    echo "✅ $src → $dst"
done <<<"$MIRROR_TABLE"

# Auto-activate kit hooks if not active. Idempotent. Skip on opt-out
# (SYNC_NO_HOOKS=1) or when the project already configured a non-.githooks
# hook path (e.g. Husky). Mirrors the behavior of kit/scripts/sync.sh
# `_maybe_activate_hooks` so kit-maintainer and downstream get identical
# semantics — see gh#25.
HOOKS_PATH="$(git -C "$PROJECT_ROOT" config core.hooksPath 2>/dev/null || true)"
# Opt-out is explicit (=1), not "any non-empty value" — matches the docs
# and avoids surprising SYNC_NO_HOOKS=0/false users.
if [ "${SYNC_NO_HOOKS:-0}" = "1" ]; then
    :
elif [ "$HOOKS_PATH" = ".githooks" ]; then
    :
elif [ -n "$HOOKS_PATH" ]; then
    echo ""
    echo "ℹ core.hooksPath = '$HOOKS_PATH' (not .githooks) — leaving as-is."
else
    git -C "$PROJECT_ROOT" config core.hooksPath .githooks
    echo ""
    echo "✅ Activated kit hooks (set core.hooksPath = .githooks)"
fi
