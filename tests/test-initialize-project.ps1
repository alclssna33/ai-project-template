Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "TestHelpers.ps1")

$initializerArgs = @(
    "-NoProfile", "-File", "./scripts/initialize-project.ps1",
    "-ProjectName", "Generated Project",
    "-RepositoryFullName", "example/generated-project",
    "-DefaultBranch", "main"
)

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

function Assert-NoPlaceholders([string]$Repository, [string[]]$RelativePaths) {
    foreach ($relativePath in $RelativePaths) {
        $content = Get-Content -LiteralPath (Join-Path $Repository $relativePath) -Raw
        Assert-True ($content -notmatch '\{\{[^}]+\}\}') "unresolved placeholder remains in $relativePath"
    }
}

function Invoke-Scenario([string]$Name, [scriptblock]$Scenario) {
    $testRoot = New-TestRoot
    try {
        & $Scenario $testRoot
        Write-Host "[pass] $Name"
    } finally {
        Remove-TestRoot $testRoot
    }
}

Invoke-Scenario "success initializes project files and passes PowerShell policy check" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "success" -FeatureBranch

    $result = Invoke-Native "pwsh" $initializerArgs $repository
    Assert-True ($result.ExitCode -eq 0) $result.Output
    Assert-NoPlaceholders $repository @("AGENTS.md", "docs/PROJECT_GUIDE.md", "README.md")
    Assert-True (-not (Test-Path (Join-Path $repository "templates/PROJECT_README.md"))) "template README still exists after initialization"

    $agents = Get-Content -LiteralPath (Join-Path $repository "AGENTS.md") -Raw
    $guide = Get-Content -LiteralPath (Join-Path $repository "docs/PROJECT_GUIDE.md") -Raw
    $readme = Get-Content -LiteralPath (Join-Path $repository "README.md") -Raw
    Assert-True ($agents.Contains("Generated Project")) "AGENTS.md did not receive project name"
    Assert-True ($guide.Contains("example/generated-project")) "project guide did not receive repository name"
    Assert-True ($readme.Contains("# Generated Project")) "README was not generated from project template"

    $policy = Invoke-Native "pwsh" @("-NoProfile", "-File", "./scripts/check-policy.ps1") $repository
    Assert-True ($policy.ExitCode -eq 0) $policy.Output
}

Invoke-Scenario "rejects default branch without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "default-branch"

    Assert-RejectedWithoutMutation $repository $initializerArgs
}

Invoke-Scenario "rejects detached HEAD without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "detached-head" -FeatureBranch
    & git -C $repository checkout --detach | Out-Null

    Assert-RejectedWithoutMutation $repository $initializerArgs
}

Invoke-Scenario "rejects dirty tree without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "dirty-tree" -FeatureBranch
    Set-Content -LiteralPath (Join-Path $repository "dirty.txt") -Value "dirty"

    Assert-RejectedWithoutMutation $repository $initializerArgs
}

Invoke-Scenario "rejects cherry-pick marker without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "cherry-pick" -FeatureBranch
    $marker = (& git -C $repository rev-parse --git-path CHERRY_PICK_HEAD).Trim()
    Set-Content -LiteralPath (Join-Path $repository $marker) -Value ((& git -C $repository rev-parse HEAD).Trim())

    Assert-RejectedWithoutMutation $repository $initializerArgs
}

Invoke-Scenario "rejects repository mismatch without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "repository-mismatch" -FeatureBranch
    $arguments = @(
        "-NoProfile", "-File", "./scripts/initialize-project.ps1",
        "-ProjectName", "Generated Project",
        "-RepositoryFullName", "example/another-project",
        "-DefaultBranch", "main"
    )

    Assert-RejectedWithoutMutation $repository $arguments
}

Invoke-Scenario "rejects missing required file without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "missing-required-file" -FeatureBranch
    Remove-Item -LiteralPath (Join-Path $repository ".claude/settings.json")
    & git -C $repository add --all
    & git -C $repository commit -m "remove required file" | Out-Null

    Assert-RejectedWithoutMutation $repository $initializerArgs
}

Invoke-Scenario "whatif returns success without mutation" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "dry-run" -FeatureBranch
    $result = Invoke-Native "pwsh" ($initializerArgs + "-WhatIf") $repository

    Assert-True ($result.ExitCode -eq 0) $result.Output
    $status = (& git -C $repository status --porcelain=v1) -join "`n"
    Assert-True ($status -ceq "") "WhatIf changed repository status"
    Assert-True (Test-Path (Join-Path $repository "templates/PROJECT_README.md")) "WhatIf removed template README"
}
