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
    & git -C $repository config core.autocrlf false
    & git -C $repository config core.safecrlf false
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
