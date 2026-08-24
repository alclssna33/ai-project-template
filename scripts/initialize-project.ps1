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

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    throw "[initialize-project] $Message"
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

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
        if (-not $path) { return $false }
        if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $RepositoryRoot $path }
        Test-Path -LiteralPath $path
    })
}

function Get-RemoteUrls([string]$RepositoryRoot, [string[]]$Arguments) {
    $lines = @(& git -C $RepositoryRoot @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) { return @() }
    @($lines | Where-Object { $_ })
}

function Resolve-RelativePath([string]$RepositoryRoot, [string]$RelativePath) {
    Join-Path $RepositoryRoot $RelativePath
}

function Get-InitializedContent([string]$Path, [System.Collections.Specialized.OrderedDictionary]$Replacements) {
    $content = Get-Content -LiteralPath $Path -Raw
    foreach ($pair in $Replacements.GetEnumerator()) {
        $content = $content.Replace($pair.Key, $pair.Value)
    }
    $content
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) { Fail "Git 저장소 루트에서 실행해야 합니다." }
Set-Location $repoRoot

$branch = (& git -C $repoRoot symbolic-ref --quiet --short HEAD 2>$null).Trim()
if (-not $branch) { Fail "detached HEAD에서는 초기화할 수 없습니다." }
if ($branch -ceq $DefaultBranch) { Fail "기본 브랜치 '$DefaultBranch'에서는 초기화할 수 없습니다." }

$operations = @(Get-GitOperationState $repoRoot)
if ($operations.Count -gt 0) { Fail "진행 중인 Git 작업이 있습니다: $($operations -join ', ')" }

$status = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
if ($status.Count -gt 0) { Fail "작업 폴더와 index가 clean하지 않습니다." }

$fetchUrls = @(Get-RemoteUrls $repoRoot @("remote", "get-url", "--all", $PrimaryRemote))
$pushUrls = @(Get-RemoteUrls $repoRoot @("remote", "get-url", "--push", "--all", $PrimaryRemote))
if ($fetchUrls.Count -eq 0) { Fail "fetch 원격 URL을 확인하지 못했습니다." }
if ($pushUrls.Count -eq 0) { Fail "push 원격 URL을 확인하지 못했습니다." }

$normalizedRepositories = @()
foreach ($url in @($fetchUrls + $pushUrls)) {
    $repository = ConvertTo-GitHubRepositoryName $url
    if (-not $repository) { Fail "원격 URL이 GitHub owner/repo 형식이 아닙니다." }
    $normalizedRepositories += $repository
}

$uniqueRepositories = @($normalizedRepositories | Sort-Object -Unique)
if ($uniqueRepositories.Count -ne 1) { Fail "fetch/push 원격 저장소가 서로 일치하지 않습니다." }
if (-not $RepositoryFullName) {
    $RepositoryFullName = $uniqueRepositories[0]
}
if ($RepositoryFullName -notmatch '^[^/]+/[^/]+$') { Fail "RepositoryFullName은 owner/repo 형식이어야 합니다." }
foreach ($repository in $normalizedRepositories) {
    if (-not [string]::Equals($repository, $RepositoryFullName, [StringComparison]::OrdinalIgnoreCase)) {
        Fail "원격 저장소와 RepositoryFullName이 일치하지 않습니다."
    }
}

$requiredFiles = @(
    ".gitattributes",
    ".github/workflows/policy-check.yml",
    ".github/pull_request_template.md",
    "CLAUDE.md",
    ".claude/settings.json",
    "POLICY_VERSION",
    $PolicyPath,
    $ProjectGuidePath,
    "prompts/ADOPT_EXISTING_PROJECT.md",
    "prompts/NEW_PROJECT_BOOTSTRAP.md",
    "prompts/START_WORK.md",
    "prompts/SYNC_POLICY.md",
    "scripts/check-policy.ps1",
    "scripts/check-policy.sh",
    "scripts/initialize-project.ps1",
    "CONTRIBUTING.md",
    "README.md",
    "templates/PROJECT_README.md",
    "AGENTS.md"
)
foreach ($relativePath in @($requiredFiles | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath (Resolve-RelativePath $repoRoot $relativePath))) {
        Fail "필수 파일이 없습니다: $relativePath"
    }
}

$versionFromFile = (Get-Content -LiteralPath (Resolve-RelativePath $repoRoot "POLICY_VERSION") -Raw).Trim()
if (-not $versionFromFile) { Fail "POLICY_VERSION이 비어 있습니다." }
if (-not $PolicyVersion) {
    $PolicyVersion = $versionFromFile
} elseif ($PolicyVersion -cne $versionFromFile) {
    Fail "지정한 PolicyVersion이 POLICY_VERSION 파일과 일치하지 않습니다."
}

$policyContent = Get-Content -LiteralPath (Resolve-RelativePath $repoRoot $PolicyPath) -Raw
$expectedPolicyLine = "Policy version: ``$PolicyVersion``"
if (-not $policyContent.Contains($expectedPolicyLine)) {
    Fail "$PolicyPath 파일의 정책 버전이 POLICY_VERSION과 일치하지 않습니다."
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

$agentsContent = Get-InitializedContent (Resolve-RelativePath $repoRoot "AGENTS.md") $replacements
$guideContent = Get-InitializedContent (Resolve-RelativePath $repoRoot $ProjectGuidePath) $replacements
if ($KeepTemplateReadme) {
    $readmeSource = "README.md"
    $readmeTarget = "README.md"
} else {
    $readmeSource = "templates/PROJECT_README.md"
    $readmeTarget = "README.md"
}
$readmeContent = Get-InitializedContent (Resolve-RelativePath $repoRoot $readmeSource) $replacements

$contentsToScan = [ordered]@{
    "AGENTS.md" = $agentsContent
    $ProjectGuidePath = $guideContent
    $readmeTarget = $readmeContent
}
foreach ($entry in $contentsToScan.GetEnumerator()) {
    if ($entry.Value -match '\{\{[^}]+\}\}') {
        Fail "자리표시자가 남아 있습니다: $($entry.Key)"
    }
}

$templateTarget = if ($KeepTemplateReadme) { "templates/PROJECT_README.md (keep)" } else { "templates/PROJECT_README.md (remove)" }
Write-Host "Project:        $ProjectName"
Write-Host "Repository:     $RepositoryFullName"
Write-Host "Branch:         $branch"
Write-Host "Policy:         $PolicyVersion"
Write-Host "Targets:        AGENTS.md, $ProjectGuidePath, README.md, $templateTarget"

if (-not $PSCmdlet.ShouldProcess($repoRoot, "initialize project policy files")) { return }

Write-Utf8NoBom (Resolve-RelativePath $repoRoot "AGENTS.md") $agentsContent
Write-Utf8NoBom (Resolve-RelativePath $repoRoot $ProjectGuidePath) $guideContent
Write-Utf8NoBom (Resolve-RelativePath $repoRoot "README.md") $readmeContent

if (-not $KeepTemplateReadme) {
    $templateReadme = Resolve-RelativePath $repoRoot "templates/PROJECT_README.md"
    Remove-Item -LiteralPath $templateReadme
    $templateDir = Split-Path $templateReadme -Parent
    if ((Test-Path -LiteralPath $templateDir) -and -not (Get-ChildItem -LiteralPath $templateDir)) {
        Remove-Item -LiteralPath $templateDir
    }
}

Write-Host "프로젝트 초기화 파일을 생성했습니다." -ForegroundColor Green
Write-Host "다음 단계:"
Write-Host "1. git diff로 변경을 검토합니다."
Write-Host "2. AGENTS.md와 docs/PROJECT_GUIDE.md의 미정·미구성 항목을 실제 프로젝트에 맞게 채웁니다."
Write-Host "3. scripts/check-policy.ps1을 실행합니다."
Write-Host "4. 초기화 브랜치에 commit·push하고 Pull Request를 만듭니다."
