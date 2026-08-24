#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

required=(
  AGENTS.md
  CLAUDE.md
  POLICY_VERSION
  docs/AI_DEVELOPMENT_POLICY.md
  docs/PROJECT_GUIDE.md
  .github/pull_request_template.md
  .claude/settings.json
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "[check-policy] missing: $path" >&2; exit 1; }
done

forbidden="$(git ls-files | grep -E '(^|/)AGENTS\.override\.md$|(^|/)CLAUDE\.local\.md$|(^|/)\.claude/settings\.local\.json$' || true)"
if [[ -n "$forbidden" ]]; then
  echo "[check-policy] forbidden tracked files:" >&2
  echo "$forbidden" >&2
  exit 1
fi

python3 -m json.tool .claude/settings.json >/dev/null

version="$(tr -d '\r\n[:space:]' < POLICY_VERSION)"
grep -F "Policy version: \`$version\`" docs/AI_DEVELOPMENT_POLICY.md >/dev/null || {
  echo "[check-policy] policy version mismatch" >&2
  exit 1
}

if [[ "${GITHUB_REPOSITORY:-}" != "alclssna33/ai-project-template" ]]; then
  if grep -R -n -E '\{\{[^}]+\}\}' AGENTS.md docs/PROJECT_GUIDE.md README.md; then
    echo "[check-policy] unresolved template placeholders" >&2
    exit 1
  fi
  grep -F "Policy version: \`$version\`" AGENTS.md >/dev/null || {
    echo "[check-policy] AGENTS.md policy version mismatch" >&2
    exit 1
  }
fi

echo "Policy integrity check passed: $version"
