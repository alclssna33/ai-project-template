[CmdletBinding()]
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
    [switch]$KeepTemplateReadme,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw "[initialize-project] $Message"
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-RepositoryFromRemote([string]$RemoteName) {
    $url = (& git remote get-url $RemoteName 2>$null).Trim()
    if (-not $url) { return $null }

    $withoutQuery = ($url -split '[?#]', 2)[0]
    $withoutGit = $withoutQuery -replace '\.git$', ''

    if ($withoutGit -match '^https?://(?:[^@/]+@)?github\.com/(?<repo>[^/]+/[^/]+)$') {
        return $Matches.repo
    }
    if ($withoutGit -match '^ssh://(?:[^@/]+@)?github\.com/(?<repo>[^/]+/[^/]+)$') {
        return $Matches.repo
    }
    if ($withoutGit -match '^(?:[^@/:]+@)?github\.com:(?<repo>[^/]+/[^/]+)$') {
        return $Matches.repo
    }
    return $null
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) { Fail "Git 저장소 루트에서 실행해야 합니다." }
Set-Location $repoRoot

$status = & git status --porcelain
if ($status -and -not $Force) {
    Fail "작업 폴더가 clean하지 않습니다. 변경을 검토하거나 -Force를 명시하세요."
}

if (-not $RepositoryFullName) {
    $RepositoryFullName = Get-RepositoryFromRemote $PrimaryRemote
}
if (-not $RepositoryFullName) {
    Fail "RepositoryFullName을 자동 확인하지 못했습니다. -RepositoryFullName owner/repo를 지정하세요."
}

if (-not $PolicyVersion) {
    $versionFile = Join-Path $repoRoot "POLICY_VERSION"
    if (-not (Test-Path $versionFile)) { Fail "POLICY_VERSION 파일이 없습니다." }
    $PolicyVersion = (Get-Content $versionFile -Raw).Trim()
}

$replacements = [ordered]@{
    '{{PROJECT_NAME}}'          = $ProjectName
    '{{REPOSITORY_FULL_NAME}}' = $RepositoryFullName
    '{{PRIMARY_REMOTE}}'       = $PrimaryRemote
    '{{DEFAULT_BRANCH}}'       = $DefaultBranch
    '{{MERGE_METHOD}}'         = $MergeMethod
    '{{POLICY_VERSION}}'       = $PolicyVersion
    '{{POLICY_PATH}}'          = $PolicyPath
    '{{PROJECT_GUIDE_PATH}}'   = $ProjectGuidePath
    '{{ISSUE_TRACKER}}'        = $IssueTracker
}

$filesToInitialize = @(
    "AGENTS.md",
    $ProjectGuidePath
)

foreach ($relativePath in $filesToInitialize) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path $fullPath)) { Fail "필수 파일이 없습니다: $relativePath" }

    $content = Get-Content $fullPath -Raw
    foreach ($pair in $replacements.GetEnumerator()) {
        $content = $content.Replace($pair.Key, $pair.Value)
    }
    Write-Utf8NoBom $fullPath $content
}

$templateReadme = Join-Path $repoRoot "templates/PROJECT_README.md"
$readme = Join-Path $repoRoot "README.md"
if ((Test-Path $templateReadme) -and -not $KeepTemplateReadme) {
    $content = Get-Content $templateReadme -Raw
    foreach ($pair in $replacements.GetEnumerator()) {
        $content = $content.Replace($pair.Key, $pair.Value)
    }
    Write-Utf8NoBom $readme $content
    Remove-Item $templateReadme -Force
    $templateDir = Split-Path $templateReadme -Parent
    if ((Test-Path $templateDir) -and -not (Get-ChildItem $templateDir -Force)) {
        Remove-Item $templateDir -Force
    }
}

$remaining = @()
foreach ($relativePath in @("AGENTS.md", $ProjectGuidePath, "README.md")) {
    $fullPath = Join-Path $repoRoot $relativePath
    if (Test-Path $fullPath) {
        $matches = Select-String -Path $fullPath -Pattern '\{\{[^}]+\}\}' -AllMatches
        if ($matches) { $remaining += $relativePath }
    }
}

if ($remaining.Count -gt 0) {
    Fail "자리표시자가 남아 있습니다: $($remaining -join ', ')"
}

Write-Host "프로젝트 초기화 파일을 생성했습니다." -ForegroundColor Green
Write-Host "Project:    $ProjectName"
Write-Host "Repository: $RepositoryFullName"
Write-Host "Policy:     $PolicyVersion"
Write-Host ""
Write-Host "다음 단계:"
Write-Host "1. git diff로 변경을 검토합니다."
Write-Host "2. AGENTS.md와 docs/PROJECT_GUIDE.md의 미정·미구성 항목을 실제 프로젝트에 맞게 채웁니다."
Write-Host "3. scripts/check-policy.ps1을 실행합니다."
Write-Host "4. 초기화 브랜치에 commit·push하고 Pull Request를 만듭니다."
