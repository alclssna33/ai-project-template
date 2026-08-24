Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "TestHelpers.ps1")

$bash = "C:\Program Files\Git\bin\bash.exe"
$powershellCheckTemplate = @("-NoProfile", "-File", "./scripts/check-policy.ps1", "-AllowTemplatePlaceholders")
$bashCheckTemplate = @("./scripts/check-policy.sh", "--allow-template-placeholders")
$powershellCheckNormal = @("-NoProfile", "-File", "./scripts/check-policy.ps1")
$bashCheckNormal = @("./scripts/check-policy.sh")

function Invoke-PolicyChecks([string]$Repository, [switch]$AllowTemplatePlaceholders) {
    if ($AllowTemplatePlaceholders) {
        $powershellArgs = $powershellCheckTemplate
        $bashArgs = $bashCheckTemplate
    } else {
        $powershellArgs = $powershellCheckNormal
        $bashArgs = $bashCheckNormal
    }

    [ordered]@{
        PowerShell = Invoke-Native "pwsh" $powershellArgs $Repository
        Bash = Invoke-Native $bash $bashArgs $Repository
    }
}

function Assert-PolicyResult([string]$Scenario, [hashtable]$Results, [int]$ExpectedExitCode) {
    foreach ($name in $Results.Keys) {
        $result = $Results[$name]
        Assert-True ($result.ExitCode -eq $ExpectedExitCode) "$Scenario $name exit $($result.ExitCode), expected $ExpectedExitCode. Output: $($result.Output)"
    }
}

function Commit-FixtureMutation([string]$Repository, [scriptblock]$Mutation) {
    & $Mutation
    & git -C $Repository add --all
    & git -C $Repository commit -m "mutate fixture" | Out-Null
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

Invoke-Scenario "valid central template passes both checkers in explicit template mode" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "valid-template"

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "valid central template" $results 0
}

Invoke-Scenario "missing common required file fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "missing-common"
    Commit-FixtureMutation $repository {
        Remove-Item -LiteralPath (Join-Path $repository "prompts/START_WORK.md")
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "missing common required file" $results 1
}

Invoke-Scenario "missing template-only file fails both checkers in explicit template mode" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "missing-template"
    Commit-FixtureMutation $repository {
        Remove-Item -LiteralPath (Join-Path $repository "templates/PROJECT_README.md")
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "missing template-only file" $results 1
}

Invoke-Scenario "forbidden tracked override fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "forbidden-override"
    Commit-FixtureMutation $repository {
        Set-Content -LiteralPath (Join-Path $repository "AGENTS.override.md") -Value "local override"
        & git -C $repository add -f AGENTS.override.md
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "forbidden tracked override" $results 1
}

Invoke-Scenario "invalid JSON fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "invalid-json"
    Commit-FixtureMutation $repository {
        Set-Content -LiteralPath (Join-Path $repository ".claude/settings.json") -Value "{"
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "invalid JSON" $results 1
}

Invoke-Scenario "auto memory enabled fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "auto-memory-enabled"
    Commit-FixtureMutation $repository {
        Set-Content -LiteralPath (Join-Path $repository ".claude/settings.json") -Value '{ "autoMemoryEnabled": true }'
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "auto memory enabled" $results 1
}

Invoke-Scenario "wrong auto memory type fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "auto-memory-string"
    Commit-FixtureMutation $repository {
        Set-Content -LiteralPath (Join-Path $repository ".claude/settings.json") -Value '{ "autoMemoryEnabled": "false" }'
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "wrong auto memory type" $results 1
}

Invoke-Scenario "missing Claude import fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "missing-claude-import"
    Commit-FixtureMutation $repository {
        $claudePath = Join-Path $repository "CLAUDE.md"
        $content = (Get-Content -LiteralPath $claudePath -Raw).Replace("@AGENTS.md`r`n`r`n", "")
        if ($content.Contains("@AGENTS.md")) { $content = $content.Replace("@AGENTS.md`n`n", "") }
        Set-Content -LiteralPath $claudePath -Value $content
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "missing Claude import" $results 1
}

Invoke-Scenario "policy version drift fails both checkers" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "policy-version-drift"
    Commit-FixtureMutation $repository {
        Set-Content -LiteralPath (Join-Path $repository "POLICY_VERSION") -Value "9.9.9"
    }

    $results = Invoke-PolicyChecks $repository -AllowTemplatePlaceholders

    Assert-PolicyResult "policy version drift" $results 1
}

Invoke-Scenario "unresolved initialized token fails both checkers in normal mode" {
    param([string]$TestRoot)
    $repository = New-TestRepository $TestRoot "unresolved-token"

    $results = Invoke-PolicyChecks $repository

    Assert-PolicyResult "unresolved initialized token" $results 1
}
