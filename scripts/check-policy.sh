#!/usr/bin/env bash
set -euo pipefail

allow_template_placeholders=false
while (($#)); do
  case "$1" in
    --allow-template-placeholders) allow_template_placeholders=true ;;
    *) echo "usage: $0 [--allow-template-placeholders]" >&2; exit 2 ;;
  esac
  shift
done

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

common_required=(
  .gitattributes
  .github/pull_request_template.md
  .github/workflows/policy-check.yml
  .claude/settings.json
  AGENTS.md
  CLAUDE.md
  CONTRIBUTING.md
  POLICY_VERSION
  README.md
  docs/AI_DEVELOPMENT_POLICY.md
  docs/PROJECT_GUIDE.md
  prompts/ADOPT_EXISTING_PROJECT.md
  prompts/NEW_PROJECT_BOOTSTRAP.md
  prompts/START_WORK.md
  prompts/SYNC_POLICY.md
  scripts/check-policy.ps1
  scripts/check-policy.sh
  scripts/initialize-project.ps1
)

for path in "${common_required[@]}"; do
  [[ -f "$path" ]] || { echo "[check-policy] missing: $path" >&2; exit 1; }
done

if [[ "$allow_template_placeholders" == true && ! -f templates/PROJECT_README.md ]]; then
  echo "[check-policy] missing: templates/PROJECT_README.md" >&2
  exit 1
fi

forbidden="$(git ls-files | grep -E '(^|/)AGENTS\.override\.md$|(^|/)CLAUDE\.local\.md$|(^|/)\.claude/settings\.local\.json$' || true)"
if [[ -n "$forbidden" ]]; then
  echo "[check-policy] forbidden tracked files:" >&2
  echo "$forbidden" >&2
  exit 1
fi

run_python() {
  local candidate path
  for candidate in python3 python; do
    if path="$(command -v "$candidate" 2>/dev/null)" && [[ "$path" != */WindowsApps/* ]] && "$candidate" -c 'import sys' >/dev/null 2>&1; then
      "$candidate" "$@"
      return
    fi
  done
  if command -v py >/dev/null 2>&1; then
    py -3 "$@"
    return
  fi
  echo "[check-policy] Python 3 is required" >&2
  exit 1
}

run_python - <<'PY'
import json
from pathlib import Path

settings = json.loads(Path('.claude/settings.json').read_text(encoding='utf-8'))
if settings.get('autoMemoryEnabled') is not False:
    raise SystemExit('[check-policy] autoMemoryEnabled must be boolean false')
PY

grep -Fx '@AGENTS.md' CLAUDE.md >/dev/null || {
  echo '[check-policy] CLAUDE.md must import @AGENTS.md' >&2
  exit 1
}

version="$(tr -d '\r\n[:space:]' < POLICY_VERSION)"
grep -F "Policy version: \`$version\`" docs/AI_DEVELOPMENT_POLICY.md >/dev/null || {
  echo "[check-policy] policy version mismatch" >&2
  exit 1
}

if [[ "$allow_template_placeholders" == false ]]; then
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
