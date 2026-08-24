# AI Project Template v1.1 Governance Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `alclssna33/ai-project-template` safely bootstrap new repositories, enforce the same policy invariants on Windows and Ubuntu, and protect `main` with repository settings and a post-merge ruleset.

**Architecture:** Keep the existing PowerShell initializer and two native policy checkers, but add a pre-write Git safety gate and shared invariant definitions. Exercise those behaviors with dependency-free PowerShell fixture tests, run the native checkers in stable GitHub Actions jobs, and apply GitHub administration in two phases so required checks are not configured before GitHub has observed them on `main`.

**Tech Stack:** PowerShell 7, Bash, Python 3 standard library, Git, GitHub Actions, GitHub CLI/REST API

**Spec:** `docs/superpowers/specs/2026-08-24-template-governance-hardening-design.md`

## Global Constraints

- Target policy version is exactly `1.1.0`.
- Preserve the existing PowerShell initializer; do not add a Bash or Python initializer.
- Add no external package, module, action, or runtime dependency.
- `scripts/initialize-project.ps1` must reject detached/default branches, dirty state, in-progress Git operations, missing or mismatched remotes, missing files, and policy-version drift before writing.
- Remove the initializer's `-Force` bypass and support native `-WhatIf` through `SupportsShouldProcess`.
- PowerShell and Bash policy checks must enforce the same invariants and expose explicit template-placeholder options.
- Use CRLF for `*.ps1`; use LF for `*.sh`, Markdown, YAML, and JSON.
- GitHub Actions retains `contents: read` and has stable Windows and Ubuntu job names.
- Do not merge PR #2 without a new explicit conditional merge instruction naming PR #2.
- Create the `main` ruleset only after PR #2 is merged, both new checks succeed on `main`, and a new session reloads the merged policy.

---

## File Structure

- Create `.gitattributes`: repository-wide line-ending contract.
- Create `tests/TestHelpers.ps1`: dependency-free disposable Git-repository fixture helpers.
- Create `tests/test-initialize-project.ps1`: initializer success, rejection, and no-mutation scenarios.
- Create `tests/test-policy-checks.ps1`: parity scenarios for the PowerShell and Bash policy checkers.
- Modify `scripts/initialize-project.ps1`: pre-write Git safety gate, plan rendering, in-memory transformation, and `ShouldProcess` boundary.
- Modify `scripts/check-policy.ps1`: canonical required files and policy invariants for Windows.
- Modify `scripts/check-policy.sh`: the same canonical invariants and explicit template-mode argument for Ubuntu/Linux/macOS.
- Modify `.github/workflows/policy-check.yml`: stable Ubuntu and Windows jobs plus native syntax/check/test commands.
- Modify `POLICY_VERSION`: set version `1.1.0`.
- Modify `docs/AI_DEVELOPMENT_POLICY.md`: set the embedded policy version `1.1.0`.
- Modify `README.md`: document the hardened bootstrap, both checks, stable CI jobs, and applied repository settings.
- Modify `prompts/NEW_PROJECT_BOOTSTRAP.md`: require dry-run, real initialization, and both native policy checks.
- Modify `docs/superpowers/specs/2026-08-24-template-governance-hardening-design.md`: record the user's approval.
- Create this plan under `docs/superpowers/plans/`.
- No change is planned for `AGENTS.md`; its `{{POLICY_VERSION}}` token remains intentional in the central template and resolves to `1.1.0` during bootstrap.

---

### Task 1: Apply the Pre-PR Repository Settings

**Files:**
- Modify: GitHub repository settings for `alclssna33/ai-project-template` only

**Interfaces:**
- Consumes: the user's explicit approval for template and merge-policy administration.
- Produces: `is_template=true`, squash-only merging, and automatic merged-branch deletion; Task 8 later adds the ruleset.

- [ ] **Step 1: Re-read current settings before mutation**

Run:

```powershell
gh api repos/alclssna33/ai-project-template --jq '{visibility,is_template,allow_squash_merge,allow_merge_commit,allow_rebase_merge,delete_branch_on_merge,default_branch}'
gh api repos/alclssna33/ai-project-template/rulesets --jq 'map({id,name,enforcement,target})'
```

Expected: public repository, default branch `main`, and no unexpected active ruleset. If an unexpected ruleset exists, stop without changing settings.

- [ ] **Step 2: Apply only the approved general settings**

Run:

```powershell
gh api --method PATCH repos/alclssna33/ai-project-template `
  -F is_template=true `
  -F allow_squash_merge=true `
  -F allow_merge_commit=false `
  -F allow_rebase_merge=false `
  -F delete_branch_on_merge=true
```

Expected: HTTP success. Do not create the `main` ruleset in this task.

- [ ] **Step 3: Read back the exact settings**

Run:

```powershell
gh api repos/alclssna33/ai-project-template --jq '{is_template,allow_squash_merge,allow_merge_commit,allow_rebase_merge,delete_branch_on_merge}'
```

Expected:

```json
{"is_template":true,"allow_squash_merge":true,"allow_merge_commit":false,"allow_rebase_merge":false,"delete_branch_on_merge":true}
```

No Git commit is created because this task changes repository administration only. Record the before/after values in Issue #1 and PR #2.

---

### Task 2: Establish the Line-Ending Contract

**Files:**
- Create: `.gitattributes`

**Interfaces:**
- Consumes: native PowerShell and Bash execution requirements.
- Produces: deterministic checkout line endings used by Tasks 3-6 and CI.

- [ ] **Step 1: Add the exact attributes file**

```gitattributes
*.sh  text eol=lf
*.ps1 text eol=crlf
*.md  text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.json text eol=lf
```

- [ ] **Step 2: Inspect attribute decisions without bulk renormalization**

Run:

```powershell
git check-attr text eol -- scripts/check-policy.sh scripts/check-policy.ps1 .github/workflows/policy-check.yml README.md .claude/settings.json
git diff --check
git diff -- .gitattributes
```

Expected: LF for Bash/Markdown/YAML/JSON, CRLF for PowerShell, and no unrelated file rewrite. Do not run `git add --renormalize .` in this PR.

- [ ] **Step 3: Commit the line-ending contract**

```powershell
git add .gitattributes
git diff --cached --check
git commit -m "chore: define policy file line endings"
```

---

### Task 3: Test and Harden the Project Initializer

**Files:**
- Create: `tests/TestHelpers.ps1`
- Create: `tests/test-initialize-project.ps1`
- Modify: `scripts/initialize-project.ps1:1-138`

**Interfaces:**
- Consumes: a clean feature branch, `ProjectName`, `RepositoryFullName`, `PrimaryRemote`, `DefaultBranch`, and the tracked template files.
- Produces: `ConvertTo-GitHubRepositoryName([string]) -> string|null`, `Get-GitOperationState() -> string[]`, a single pre-mutation `ShouldProcess` decision, and initialized in-memory file content.

- [ ] **Step 1: Create dependency-free fixture helpers**

`tests/TestHelpers.ps1` must export these functions by dot-sourcing:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:TemplateRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "[test] $Message" }
}

function Invoke-Native([string]$FilePath, [string[]]$ArgumentList, [string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        $output = & $FilePath @ArgumentList 2>&1 | Out-String
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output.TrimEnd() }
    } finally {
        Pop-Location
    }
}

function New-TestRoot() {
    $path = Join-Path ([IO.Path]::GetTempPath()) ("ai-project-template-tests-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $path | Out-Null
    $path
}

function New-TestRepository([string]$TestRoot, [string]$Name, [switch]$FeatureBranch) {
    $repository = Join-Path $TestRoot $Name
    New-Item -ItemType Directory -Path $repository | Out-Null
    foreach ($relativePath in (& git -C $script:TemplateRoot ls-files)) {
        $destination = Join-Path $repository $relativePath
        $parent = Split-Path $destination -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item (Join-Path $script:TemplateRoot $relativePath) $destination
    }
    & git -C $repository init -b main | Out-Null
    & git -C $repository config user.name "Policy Test"
    & git -C $repository config user.email "policy-test@example.invalid"
    & git -C $repository add --all
    & git -C $repository commit -m "test fixture" | Out-Null
    & git -C $repository remote add origin "https://github.com/example/generated-project.git"
    if ($FeatureBranch) { & git -C $repository switch -c ai/codex/bootstrap-test | Out-Null }
    $repository
}

function Remove-TestRoot([string]$TestRoot) {
    $resolved = (Resolve-Path -LiteralPath $TestRoot).Path
    $temp = [IO.Path]::GetTempPath().TrimEnd([IO.Path]::DirectorySeparatorChar)
    $tempPrefix = $temp + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "[test] cleanup target is outside the temp directory: $resolved"
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
```

- [ ] **Step 2: Write initializer acceptance scenarios before changing the initializer**

`tests/test-initialize-project.ps1` must create a fresh fixture per scenario and assert this matrix:

| Scenario | Setup | Expected exit | Mutation assertion |
| --- | --- | --- | --- |
| success | feature branch, matching fetch/push remote | 0 | AGENTS/guide/README resolved, template README removed, both normal policy checks pass |
| default branch | remain on `main` | nonzero | `git status --porcelain=v1` unchanged |
| detached HEAD | `git checkout --detach` | nonzero | status unchanged |
| dirty tree | create `dirty.txt` before invocation | nonzero | status remains exactly the pre-run value |
| cherry-pick marker | write current HEAD to the path from `git rev-parse --git-path CHERRY_PICK_HEAD` | nonzero | tracked content unchanged |
| repository mismatch | pass `example/another-project` | nonzero | status unchanged |
| missing required file | remove `.claude/settings.json` and commit the removal | nonzero | status unchanged |
| dry run | feature branch plus `-WhatIf` | 0 | status remains clean and template README still exists |

Use this invocation for successful initialization:

```powershell
$result = Invoke-Native "pwsh" @(
    "-NoProfile", "-File", "./scripts/initialize-project.ps1",
    "-ProjectName", "Generated Project",
    "-RepositoryFullName", "example/generated-project",
    "-DefaultBranch", "main"
) $repository
Assert-True ($result.ExitCode -eq 0) $result.Output
```

Use this helper for every no-mutation failure:

```powershell
function Assert-RejectedWithoutMutation([string]$Repository, [string[]]$Arguments) {
    $statusBefore = (& git -C $Repository status --porcelain=v1) -join "`n"
    $diffBefore = (& git -C $Repository diff --binary) -join "`n"
    $result = Invoke-Native "pwsh" $Arguments $Repository
    Assert-True ($result.ExitCode -ne 0) "initializer unexpectedly succeeded"
    $statusAfter = (& git -C $Repository status --porcelain=v1) -join "`n"
    $diffAfter = (& git -C $Repository diff --binary) -join "`n"
    Assert-True ($statusAfter -ceq $statusBefore) "status changed after rejected initialization"
    Assert-True ($diffAfter -ceq $diffBefore) "tracked content changed after rejected initialization"
}
```

- [ ] **Step 3: Run the initializer tests and confirm they fail against v1.0**

Run:

```powershell
pwsh -NoProfile -File ./tests/test-initialize-project.ps1
```

Expected: FAIL because the current initializer permits default-branch/detached/mismatched-remote contexts and does not implement `-WhatIf`.

- [ ] **Step 4: Replace the unsafe parameter and add the Git-state helpers**

Start the script with:

```powershell
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName,
    [string]$RepositoryFullName,
    [string]$PrimaryRemote = "origin",
    [string]$DefaultBranch = "main",
    [ValidateSet("squash", "merge", "rebase")]
    [string]$MergeMethod = "squash",
    [string]$PolicyVersion,
    [string]$PolicyPath = "docs/AI_DEVELOPMENT_POLICY.md",
    [string]$ProjectGuidePath = "docs/PROJECT_GUIDE.md",
    [string]$IssueTracker = "GitHub Issues",
    [switch]$KeepTemplateReadme
)
```

Remove `-Force` completely. Implement URL normalization without ever printing the raw URL:

```powershell
function ConvertTo-GitHubRepositoryName([string]$Url) {
    if (-not $Url) { return $null }
    $candidate = (($Url -split '[?#]', 2)[0] -replace '\.git$', '').TrimEnd('/')
    foreach ($pattern in @(
        '^https?://(?:[^@/]+@)?github\.com/(?<repo>[^/]+/[^/]+)$',
        '^ssh://(?:[^@/]+@)?github\.com/(?<repo>[^/]+/[^/]+)$',
        '^(?:[^@/:]+@)?github\.com:(?<repo>[^/]+/[^/]+)$'
    )) {
        if ($candidate -match $pattern) { return $Matches.repo }
    }
    return $null
}

function Get-GitOperationState([string]$RepositoryRoot) {
    $markers = @('MERGE_HEAD', 'CHERRY_PICK_HEAD', 'REVERT_HEAD', 'rebase-merge', 'rebase-apply')
    @($markers | Where-Object {
        $path = (& git -C $RepositoryRoot rev-parse --git-path $_ 2>$null).Trim()
        $path -and (Test-Path -LiteralPath (if ([IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $RepositoryRoot $path }))
    })
}
```

- [ ] **Step 5: Implement the complete pre-write gate**

Perform checks in this order and throw through `Fail()` on the first violation:

```powershell
$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) { Fail "Git 저장소 루트에서 실행해야 합니다." }

$branch = (& git -C $repoRoot symbolic-ref --quiet --short HEAD 2>$null).Trim()
if (-not $branch) { Fail "detached HEAD에서는 초기화할 수 없습니다." }
if ($branch -ceq $DefaultBranch) { Fail "기본 브랜치 '$DefaultBranch'에서는 초기화할 수 없습니다." }

$operations = Get-GitOperationState $repoRoot
if ($operations.Count -gt 0) { Fail "진행 중인 Git 작업이 있습니다: $($operations -join ', ')" }

$status = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
if ($status.Count -gt 0) { Fail "작업 폴더와 index가 clean하지 않습니다." }
```

Read all fetch and push URLs with `git remote get-url --all` and `git remote get-url --push --all`. Require at least one of each, normalize every value, derive `RepositoryFullName` only when all normalized repositories agree, and compare every normalized value to the resolved repository name with ordinal-ignore-case equality. A non-GitHub or mismatched URL fails without echoing that URL.

Use one canonical pre-bootstrap required list containing `.gitattributes`, the GitHub workflow/PR template, Claude files, policy/guide files, all four prompts, both checkers, the initializer, `CONTRIBUTING.md`, `README.md`, and `templates/PROJECT_README.md`. `-KeepTemplateReadme` changes whether the file is converted and removed, not whether a valid template must contain it.

Read `POLICY_VERSION`, reject an empty value, resolve the parameter to that file value when omitted, reject a supplied value that differs, and require the exact line ``Policy version: `$PolicyVersion` `` in `$PolicyPath`.

- [ ] **Step 6: Build every target in memory and cross one mutation boundary**

Before `ShouldProcess`, read and replace `AGENTS.md`, `$ProjectGuidePath`, and the README source in memory; scan the resulting strings for unresolved `{{...}}` tokens; and print this safe plan:

```text
Project:        Generated Project
Repository:     example/generated-project
Branch:         ai/codex/bootstrap-test
Policy:         1.1.0
Targets:        AGENTS.md, docs/PROJECT_GUIDE.md, README.md, templates/PROJECT_README.md (remove)
```

Then cross exactly one mutation boundary:

```powershell
if (-not $PSCmdlet.ShouldProcess($repoRoot, "initialize project policy files")) { return }
```

Only after it returns true, write the precomputed UTF-8-no-BOM strings and remove the template README/directory. Do not use `-Force` on file writes or removal. A `-WhatIf` invocation must return before the first write/delete.

- [ ] **Step 7: Run parser and initializer tests**

Run:

```powershell
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path ./scripts/initialize-project.ps1), [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count) { $errors | Format-List | Out-String | Write-Error; exit 1 }
pwsh -NoProfile -File ./tests/test-initialize-project.ps1
```

Expected: parser succeeds and every fixture scenario passes.

- [ ] **Step 8: Commit initializer behavior and tests**

```powershell
git add tests/TestHelpers.ps1 tests/test-initialize-project.ps1 scripts/initialize-project.ps1
git diff --cached --check
git commit -m "fix: harden project initialization gates"
```

---

### Task 4: Test and Align Both Policy Checkers

**Files:**
- Create: `tests/test-policy-checks.ps1`
- Modify: `scripts/check-policy.ps1:1-75`
- Modify: `scripts/check-policy.sh:1-47`

**Interfaces:**
- Consumes: `-AllowTemplatePlaceholders` on PowerShell or `--allow-template-placeholders` on Bash.
- Produces: identical pass/fail decisions for required files, forbidden tracked files, Claude settings/import, policy version, and initialized placeholders.

- [ ] **Step 1: Write checker parity scenarios first**

`tests/test-policy-checks.ps1` must use `TestHelpers.ps1`, create a fresh committed fixture per scenario, and invoke both commands:

```powershell
$powershellCheck = @("-NoProfile", "-File", "./scripts/check-policy.ps1", "-AllowTemplatePlaceholders")
$bashCheck = @("./scripts/check-policy.sh", "--allow-template-placeholders")
```

Assert the same result for both checkers:

| Scenario | Fixture mutation | Expected |
| --- | --- | --- |
| valid central template | none | both pass in explicit template mode |
| missing common required file | delete and commit `prompts/START_WORK.md` | both fail |
| missing template-only file | delete and commit `templates/PROJECT_README.md` | both fail in template mode |
| forbidden tracked override | force-add and commit `AGENTS.override.md` | both fail |
| invalid JSON | replace `.claude/settings.json` with `{` and commit | both fail |
| auto memory enabled | set `autoMemoryEnabled` to `true` and commit | both fail |
| wrong auto-memory type | set `autoMemoryEnabled` to string `"false"` and commit | both fail |
| missing Claude import | remove the exact `@AGENTS.md` line and commit | both fail |
| policy version drift | write `9.9.9` to `POLICY_VERSION` and commit | both fail |
| unresolved initialized token | invoke both without template option on the untouched template | both fail |

- [ ] **Step 2: Run parity tests and confirm v1.0 fails**

Run:

```powershell
pwsh -NoProfile -File ./tests/test-policy-checks.ps1
```

Expected: FAIL because the v1.0 checkers have different required-file lists, Bash lacks an explicit template option, and neither enforces every Claude invariant.

- [ ] **Step 3: Define the same common and template-only lists in both scripts**

Use this exact common list in the same order:

```text
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
```

Use `templates/PROJECT_README.md` as the template-only required file. This file is allowed to be absent after successful initialization because the initializer converts it into the project README.

- [ ] **Step 4: Add exact Claude settings and import validation**

PowerShell must reject a missing property, a non-Boolean value, or `true`:

```powershell
$settings = Get-Content ".claude/settings.json" -Raw | ConvertFrom-Json
$autoMemory = $settings.PSObject.Properties["autoMemoryEnabled"]
if (-not $autoMemory -or $autoMemory.Value -isnot [bool] -or $autoMemory.Value) {
    Fail ".claude/settings.json의 autoMemoryEnabled는 Boolean false여야 합니다."
}
$claudeLines = Get-Content "CLAUDE.md"
if (-not ($claudeLines | Where-Object { $_.Trim() -ceq "@AGENTS.md" })) {
    Fail "CLAUDE.md가 @AGENTS.md를 import하지 않습니다."
}
```

Bash must use Python's standard library for the same typed JSON assertion and exact-line grep for the import:

```bash
python3 - <<'PY'
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
```

- [ ] **Step 5: Replace Bash's repository-name heuristic with an explicit option**

Parse arguments before other checks:

```bash
allow_template_placeholders=false
while (($#)); do
  case "$1" in
    --allow-template-placeholders) allow_template_placeholders=true ;;
    *) echo "usage: $0 [--allow-template-placeholders]" >&2; exit 2 ;;
  esac
  shift
done
```

When the option is false, both scripts scan `AGENTS.md`, `docs/PROJECT_GUIDE.md`, and `README.md` for `{{...}}`, and require the initialized `AGENTS.md` policy-version line. When true, both require `templates/PROJECT_README.md` and intentionally skip only those initialized-value checks. The central policy file version check always runs.

- [ ] **Step 6: Run syntax and parity tests**

Run:

```powershell
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path ./scripts/check-policy.ps1), [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count) { $errors | Format-List | Out-String | Write-Error; exit 1 }
bash -n ./scripts/check-policy.sh
pwsh -NoProfile -File ./tests/test-policy-checks.ps1
pwsh -NoProfile -File ./tests/test-initialize-project.ps1
```

Expected: both parsers and both test suites pass.

- [ ] **Step 7: Commit checker parity and tests**

```powershell
git add tests/test-policy-checks.ps1 scripts/check-policy.ps1 scripts/check-policy.sh
git diff --cached --check
git commit -m "test: enforce policy checker parity"
```

---

### Task 5: Run Native Checks in Stable CI Jobs

**Files:**
- Modify: `.github/workflows/policy-check.yml:1-20`

**Interfaces:**
- Consumes: the explicit checker options and dependency-free tests from Tasks 3-4.
- Produces: stable check contexts `Policy integrity / Ubuntu` and `Policy integrity / Windows` for the later ruleset.

- [ ] **Step 1: Replace the single job with this two-job workflow**

```yaml
name: Policy integrity

on:
  pull_request:
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  policy-integrity-ubuntu:
    name: Policy integrity / Ubuntu
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Validate Bash syntax
        run: bash -n scripts/check-policy.sh
      - name: Check policy files
        shell: bash
        run: |
          args=()
          if [[ "$GITHUB_REPOSITORY" == "alclssna33/ai-project-template" ]]; then
            args+=(--allow-template-placeholders)
          fi
          bash scripts/check-policy.sh "${args[@]}"

  policy-integrity-windows:
    name: Policy integrity / Windows
    runs-on: windows-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Validate PowerShell syntax
        shell: pwsh
        run: |
          foreach ($path in @('scripts/initialize-project.ps1', 'scripts/check-policy.ps1')) {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path), [ref]$tokens, [ref]$errors) | Out-Null
            if ($errors.Count) { $errors | Format-List | Out-String | Write-Error; exit 1 }
          }
      - name: Check policy files
        shell: pwsh
        run: |
          $params = @{}
          if ($env:GITHUB_REPOSITORY -eq 'alclssna33/ai-project-template') {
            $params.AllowTemplatePlaceholders = $true
          }
          ./scripts/check-policy.ps1 @params
      - name: Test policy behavior
        shell: pwsh
        run: |
          ./tests/test-policy-checks.ps1
          ./tests/test-initialize-project.ps1
```

- [ ] **Step 2: Validate YAML content and referenced commands locally**

Run:

```powershell
rg -n "Policy integrity / Ubuntu|Policy integrity / Windows|contents: read|AllowTemplatePlaceholders|allow-template-placeholders" .github/workflows/policy-check.yml
bash -n scripts/check-policy.sh
pwsh -NoProfile -File ./scripts/check-policy.ps1 -AllowTemplatePlaceholders
bash ./scripts/check-policy.sh --allow-template-placeholders
pwsh -NoProfile -File ./tests/test-policy-checks.ps1
pwsh -NoProfile -File ./tests/test-initialize-project.ps1
```

Expected: both stable job names occur once, workflow permissions remain read-only, and all commands pass.

- [ ] **Step 3: Commit the CI split**

```powershell
git add .github/workflows/policy-check.yml
git diff --cached --check
git commit -m "ci: validate policy on windows and ubuntu"
```

---

### Task 6: Publish Policy Version 1.1 Documentation

**Files:**
- Modify: `POLICY_VERSION:1`
- Modify: `docs/AI_DEVELOPMENT_POLICY.md:3`
- Modify: `README.md:1-207`
- Modify: `prompts/NEW_PROJECT_BOOTSTRAP.md:1-21`

**Interfaces:**
- Consumes: the implemented initializer/checker/CI behavior.
- Produces: one documented version and commands that exactly match the implementation.

- [ ] **Step 1: Bump both authoritative version locations together**

Write `1.1.0` plus a trailing newline to `POLICY_VERSION`, and change the policy header to:

```markdown
- Policy version: `1.1.0`
```

- [ ] **Step 2: Update the bootstrap guide with dry-run and safety behavior**

In `README.md`, replace the single initializer example with:

```powershell
pwsh ./scripts/initialize-project.ps1 `
  -ProjectName "New Clinic Project" `
  -RepositoryFullName "alclssna33/new-clinic-project" `
  -DefaultBranch "main" `
  -WhatIf

pwsh ./scripts/initialize-project.ps1 `
  -ProjectName "New Clinic Project" `
  -RepositoryFullName "alclssna33/new-clinic-project" `
  -DefaultBranch "main"
```

Document that the script rejects default/detached branches, dirty state, in-progress Git operations, remote mismatch, missing required files, and policy-version drift before mutation. State that `-Force` does not exist.

- [ ] **Step 3: Update repository-settings and validation documentation**

Change the template-setting section from a pending manual action to the current intended state, document squash-only and automatic branch deletion, and state that the required-check ruleset is applied only after version 1.1 passes on `main`.

Show both explicit template checks:

```powershell
pwsh ./scripts/check-policy.ps1 -AllowTemplatePlaceholders
bash ./scripts/check-policy.sh --allow-template-placeholders
```

Show both normal downstream checks:

```powershell
pwsh ./scripts/check-policy.ps1
bash ./scripts/check-policy.sh
```

Name the CI checks exactly `Policy integrity / Ubuntu` and `Policy integrity / Windows`.

- [ ] **Step 4: Strengthen the new-project agent prompt**

In `prompts/NEW_PROJECT_BOOTSTRAP.md`, require this order:

```text
1. Read AGENTS.md and the common policy from the latest default branch.
2. Confirm repository identity, default branch SHA, open work, unique branch, and isolated environment.
3. Resolve initializer inputs from the actual repository.
4. Run initialize-project.ps1 with -WhatIf and verify that no file changed.
5. Run initialize-project.ps1 without -WhatIf only after the dry-run plan is correct.
6. Review AGENTS.md, PROJECT_GUIDE.md, README.md, and the deleted template README.
7. Run both check-policy.ps1 and check-policy.sh without template-placeholder options.
8. Commit only initialization files and open a Draft PR; do not push or merge the default branch.
```

Keep the Korean prose style of the existing prompt while preserving this exact order and meaning.

- [ ] **Step 5: Run version, placeholder, and documentation checks**

Run:

```powershell
pwsh -NoProfile -File ./scripts/check-policy.ps1 -AllowTemplatePlaceholders
bash ./scripts/check-policy.sh --allow-template-placeholders
rg -n "1\.0\.0|-Force|Policy integrity / Ubuntu|Policy integrity / Windows|WhatIf" POLICY_VERSION docs/AI_DEVELOPMENT_POLICY.md README.md prompts/NEW_PROJECT_BOOTSTRAP.md scripts/initialize-project.ps1 .github/workflows/policy-check.yml
```

Expected: no stale `1.0.0`; `-Force` appears only in explanatory text saying it is unavailable; both CI names and `WhatIf` are documented.

- [ ] **Step 6: Commit the versioned documentation**

```powershell
git add POLICY_VERSION docs/AI_DEVELOPMENT_POLICY.md README.md prompts/NEW_PROJECT_BOOTSTRAP.md
git diff --cached --check
git commit -m "docs: publish policy version 1.1"
```

---

### Task 7: Verify the Complete Branch and Prepare PR #2

**Files:**
- Review: every file in `git diff origin/main...HEAD`
- Update: PR #2 body and Issue #1 coordination record

**Interfaces:**
- Consumes: all tracked commits from Tasks 2-6 and current `origin/main`.
- Produces: a clean, current, reviewable PR whose checks are green; it does not merge the PR.

- [ ] **Step 1: Fetch and merge the latest main if needed**

Run the required identity checks before network access, then:

```powershell
git fetch origin --prune
git log --oneline HEAD..origin/main
git diff --stat HEAD...origin/main
```

If new `main` commits exist and do not change policy instructions unexpectedly:

```powershell
git merge --no-edit origin/main
```

If policy instructions changed, stop and restart under the new rules instead of continuing this plan.

- [ ] **Step 2: Run the complete local verification suite**

Run:

```powershell
foreach ($path in @('scripts/initialize-project.ps1', 'scripts/check-policy.ps1', 'tests/TestHelpers.ps1', 'tests/test-initialize-project.ps1', 'tests/test-policy-checks.ps1')) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $path), [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count) { $errors | Format-List | Out-String | Write-Error; exit 1 }
}
bash -n scripts/check-policy.sh
pwsh -NoProfile -File ./scripts/check-policy.ps1 -AllowTemplatePlaceholders
bash ./scripts/check-policy.sh --allow-template-placeholders
pwsh -NoProfile -File ./tests/test-policy-checks.ps1
pwsh -NoProfile -File ./tests/test-initialize-project.ps1
git diff --check origin/main...HEAD
```

Expected: every command exits 0.

- [ ] **Step 3: Review scope, secrets, deletions, and commit history**

Run:

```powershell
git status --short
git diff --name-status origin/main...HEAD
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
git log --oneline origin/main..HEAD
git grep -n -I -E '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z_-]{30,})' HEAD -- .
```

Expected: clean status; only the files declared in this plan; the only deletion in disposable test fixtures, not in the PR; no secret match; small conventional commits.

- [ ] **Step 4: Push without history rewriting and update PR #2**

Run:

```powershell
git push origin HEAD
$headSha = (git rev-parse HEAD).Trim()
$baseSha = (git merge-base origin/main HEAD).Trim()
$changedFiles = (git diff --name-status origin/main...HEAD) -join "`n"
$prBodyPath = Join-Path ([IO.Path]::GetTempPath()) "ai-project-template-pr-2.md"
$prBody = @"
Closes #1

Agent/session: Codex / ai/codex/1-template-governance-hardening
Base main SHA: $baseSha
Head SHA: $headSha

Changed files:
````text
$changedFiles
````

Summary:
- harden project initialization gates and add WhatIf
- align PowerShell and Bash policy invariants
- validate policy on Windows and Ubuntu
- publish policy version 1.1.0

Tests:
- PASS: PowerShell parser validation for scripts and test harnesses
- PASS: bash -n scripts/check-policy.sh
- PASS: pwsh ./scripts/check-policy.ps1 -AllowTemplatePlaceholders
- PASS: bash ./scripts/check-policy.sh --allow-template-placeholders
- PASS: pwsh ./tests/test-policy-checks.ps1
- PASS: pwsh ./tests/test-initialize-project.ps1

Administration:
- template repository enabled
- squash-only merge and automatic head-branch deletion enabled
- main ruleset deferred until both checks succeed on merged main

Risk/rollback:
- changes agent policy, CI, and bootstrap behavior
- revert file behavior through a new PR; restore repository settings through the admin audit trail
"@
[IO.File]::WriteAllText($prBodyPath, $prBody, [Text.UTF8Encoding]::new($false))
gh pr edit 2 --title "fix: harden template bootstrap and governance" --body-file $prBodyPath
Remove-Item -LiteralPath $prBodyPath
gh pr ready 2
gh pr view 2 --json number,state,isDraft,baseRefName,headRefName,headRefOid,mergeable,mergeStateStatus,url
gh pr checks 2 --watch
```

The prepared PR body must contain Issue #1, agent/session, base SHA, changed files, exact test commands/results, administrative setting changes, risks, rollback, and the deferred post-merge ruleset. Create the body as an explicit temporary file outside the repository and remove it after `gh pr edit` succeeds.

Expected: PR #2 targets `main`, head is `ai/codex/1-template-governance-hardening`, both stable checks pass, and the worktree is clean. Do not merge.

---

### Task 8: Post-Merge Main Ruleset in a New Session

**Files:**
- Modify: GitHub repository ruleset for `refs/heads/main` only

**Interfaces:**
- Consumes: an explicit user instruction naming PR #2, a verified squash merge, merged policy reloaded in a new session, and two successful check runs on the merged `main` SHA.
- Produces: one active ruleset named `main governance` with no routine bypass actor.

API reference: [GitHub REST API — repository rulesets](https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10)

- [ ] **Step 1: Stop until the merge gate is satisfied**

Do not execute this task in the implementation session. PR #2 must first be reviewed and merged only after the user says to check and merge PR #2. After merge, start a new session and read the merged `AGENTS.md` and policy before any administration.

- [ ] **Step 2: Verify the merged main and observed check contexts**

Run:

```powershell
git fetch origin --prune
$mainSha = (git rev-parse origin/main).Trim()
gh api "repos/alclssna33/ai-project-template/commits/$mainSha/check-runs" --jq '.check_runs[] | {name,status,conclusion,head_sha}'
gh api repos/alclssna33/ai-project-template/rulesets --jq 'map({id,name,enforcement,target})'
```

Expected: both `Policy integrity / Ubuntu` and `Policy integrity / Windows` have `status=completed`, `conclusion=success`, and `head_sha=$mainSha`; no conflicting ruleset exists. If the observed check names differ from the planned names, stop and use the exact observed names only after reviewing why they differ.

- [ ] **Step 3: Create the exact active ruleset**

Create the exact ruleset payload in memory:

```powershell
$rulesetJson = @'
{
  "name": "main governance",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"],
      "exclude": []
    }
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {"type": "required_linear_history"},
    {
      "type": "pull_request",
      "parameters": {
        "allowed_merge_methods": ["squash"],
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_approving_review_count": 0,
        "required_review_thread_resolution": true
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "do_not_enforce_on_create": true,
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          {"context": "Policy integrity / Ubuntu"},
          {"context": "Policy integrity / Windows"}
        ]
      }
    }
  ]
}
'@
```

Post it with the versioned GitHub REST API:

```powershell
$rulesetPath = Join-Path ([IO.Path]::GetTempPath()) "ai-project-template-main-governance.json"
[IO.File]::WriteAllText($rulesetPath, $rulesetJson, [Text.UTF8Encoding]::new($false))
gh api --method POST repos/alclssna33/ai-project-template/rulesets `
  -H "Accept: application/vnd.github+json" `
  -H "X-GitHub-Api-Version: 2026-03-10" `
  --input $rulesetPath
Remove-Item -LiteralPath $rulesetPath
```

Do not add an admin, user, app, or repository-role bypass actor.

- [ ] **Step 4: Verify effective protection and record the result**

Run:

```powershell
gh api repos/alclssna33/ai-project-template/rulesets --jq '.[] | select(.name=="main governance") | {id,name,target,enforcement}'
gh api repos/alclssna33/ai-project-template/rules/branches/main --jq 'map(.type)'
gh api repos/alclssna33/ai-project-template --jq '{is_template,allow_squash_merge,allow_merge_commit,allow_rebase_merge,delete_branch_on_merge}'
```

Expected effective rule types include `deletion`, `non_fast_forward`, `required_linear_history`, `pull_request`, and `required_status_checks`; repository settings remain template/squash-only/auto-delete. Record the ruleset ID, merged main SHA, observed check names, and verification output in Issue #1, then close Issue #1 only when a disposable project generated from merged `main` also passes bootstrap and both policy checks.

---

## Completion Evidence

The implementation handoff must report:

```text
Mode: write
Branch: ai/codex/1-template-governance-hardening
Base main SHA: the verified origin/main SHA used for the final diff
Head SHA: the pushed PR head SHA
PR: #2
Changed files: exact git diff --name-status output
Tests passed: exact commands and exit results
Tests not run: none, or an explicit command and reason
Main synchronized: yes/no with ahead/behind counts
Known risks: policy behavior, CI, and repository administration
Next action: user review and explicit conditional merge instruction for PR #2
```
