[CmdletBinding()]
param(
    [switch]$AllowTemplatePlaceholders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    Write-Error "[check-policy] $Message"
    exit 1
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) { Fail "Git 저장소 루트에서 실행해야 합니다." }
Set-Location $repoRoot

$commonRequired = @(
    ".gitattributes",
    ".github/pull_request_template.md",
    ".github/workflows/policy-check.yml",
    ".claude/settings.json",
    "AGENTS.md",
    "CLAUDE.md",
    "CONTRIBUTING.md",
    "POLICY_VERSION",
    "README.md",
    "docs/AI_DEVELOPMENT_POLICY.md",
    "docs/PROJECT_GUIDE.md",
    "prompts/ADOPT_EXISTING_PROJECT.md",
    "prompts/NEW_PROJECT_BOOTSTRAP.md",
    "prompts/START_WORK.md",
    "prompts/SYNC_POLICY.md",
    "scripts/check-policy.ps1",
    "scripts/check-policy.sh",
    "scripts/initialize-project.ps1"
)

foreach ($path in $commonRequired) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $path) -PathType Leaf)) {
        Fail "필수 파일이 없습니다: $path"
    }
}

if ($AllowTemplatePlaceholders -and -not (Test-Path -LiteralPath (Join-Path $repoRoot "templates/PROJECT_README.md") -PathType Leaf)) {
    Fail "필수 파일이 없습니다: templates/PROJECT_README.md"
}

$trackedFiles = & git ls-files
$forbiddenPatterns = @(
    '(^|/)AGENTS\.override\.md$',
    '(^|/)CLAUDE\.local\.md$',
    '(^|/)\.claude/settings\.local\.json$'
)
foreach ($file in $trackedFiles) {
    foreach ($pattern in $forbiddenPatterns) {
        if ($file -match $pattern) { Fail "로컬 전용 또는 override 파일이 추적되고 있습니다: $file" }
    }
}

try {
    $settings = Get-Content ".claude/settings.json" -Raw | ConvertFrom-Json
} catch {
    Fail ".claude/settings.json이 유효한 JSON이 아닙니다."
}

$autoMemory = $settings.PSObject.Properties["autoMemoryEnabled"]
if (-not $autoMemory -or $autoMemory.Value -isnot [bool] -or $autoMemory.Value) {
    Fail ".claude/settings.json의 autoMemoryEnabled는 Boolean false여야 합니다."
}

$claudeLines = Get-Content "CLAUDE.md"
if (-not ($claudeLines | Where-Object { $_.Trim() -ceq "@AGENTS.md" })) {
    Fail "CLAUDE.md가 @AGENTS.md를 import하지 않습니다."
}

if (-not $AllowTemplatePlaceholders) {
    foreach ($path in @("AGENTS.md", "docs/PROJECT_GUIDE.md", "README.md")) {
        if (Test-Path $path) {
            $matches = Select-String -Path $path -Pattern '\{\{[^}]+\}\}' -AllMatches
            if ($matches) { Fail "초기화되지 않은 자리표시자가 있습니다: $path" }
        }
    }
}

$version = (Get-Content "POLICY_VERSION" -Raw).Trim()
if (-not $version) { Fail "POLICY_VERSION이 비어 있습니다." }

$policy = Get-Content "docs/AI_DEVELOPMENT_POLICY.md" -Raw
if ($policy -notmatch [regex]::Escape("Policy version: ``$version``")) {
    Fail "AI_DEVELOPMENT_POLICY.md의 버전과 POLICY_VERSION이 일치하지 않습니다."
}

if (-not $AllowTemplatePlaceholders) {
    $agents = Get-Content "AGENTS.md" -Raw
    if ($agents -notmatch [regex]::Escape("Policy version: ``$version``")) {
        Fail "AGENTS.md의 버전과 POLICY_VERSION이 일치하지 않습니다."
    }
}

Write-Host "정책 무결성 검사를 통과했습니다. Policy version: $version" -ForegroundColor Green
