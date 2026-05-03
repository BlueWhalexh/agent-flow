param(
    [string]$Message,
    [string]$Branch,
    [string]$Services = "core-workflow-java",
    [string]$ImageTag = "latest",
    [string]$Workflow = "Deploy Production",
    [string]$BuildWorkflow = "GHCR Build Images",
    [switch]$NoDeploy,
    [switch]$NoCommit,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Show-Usage {
    @'
Usage:
  .\scripts\release-gh.ps1 -Message "feat: xxx" [options]

Options:
  -Message         Git commit message
  -Branch          Branch to push, default is current branch
  -Services        Services to deploy, default is core-workflow-java
  -ImageTag        Image tag, default is latest
  -Workflow        Deploy workflow name, default is "Deploy Production"
  -BuildWorkflow   Build workflow name, default is "GHCR Build Images"
  -NoDeploy        Only commit and push
  -NoCommit        Only push and deploy
  -Help            Show help

Examples:
  .\scripts\release-gh.ps1 -Message "feat: update xiaomi flow"
  .\scripts\release-gh.ps1 -Message "fix: console hub" -Services "console-hub"
  .\scripts\release-gh.ps1 -NoDeploy -Message "chore: save progress"
  .\scripts\release-gh.ps1 -NoCommit -Branch main -Services "core-workflow-java"
'@
}

if ($Help) {
    Show-Usage
    exit 0
}

$rootDir = Split-Path -Parent $PSScriptRoot
Set-Location $rootDir

$null = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Current directory is not a Git repository"
}

$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
if ([string]::IsNullOrWhiteSpace($Branch)) {
    $Branch = $currentBranch
}

if (-not $NoCommit) {
    if ([string]::IsNullOrWhiteSpace($Message)) {
        throw 'Commit message is required in auto-commit mode: -Message "your message"'
    }

    $statusOutput = git status --porcelain
    if ($statusOutput) {
        Write-Host "[1/5] Changes detected, preparing commit"
        git add -A
        $stagedOutput = git diff --cached --name-only
        if ($stagedOutput) {
            git commit -m $Message
        } else {
            Write-Host "No staged changes to commit"
        }
    } else {
        Write-Host "[1/5] No local changes, skip commit"
    }
} else {
    Write-Host "[1/5] Auto commit skipped"
}

Write-Host "[2/5] Pushing branch to origin/$Branch"
git push origin $Branch

if ($NoDeploy) {
    Write-Host "[3/5] Deploy skipped by option"
    exit 0
}

if ($Branch -ne "main") {
    Write-Host "[3/5] Branch is not main, deploy skipped"
    Write-Host "Reason: production images are pushed only after merge into main."
    Write-Host "Suggested command after merge:"
    Write-Host ".\scripts\release-gh.ps1 -NoCommit -Branch main -Services `"$Services`" -ImageTag `"$ImageTag`""
    exit 0
}

$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghCommand) {
    Write-Host "[3/5] gh CLI not found, cannot trigger deploy automatically"
    Write-Host "Run the workflow manually in GitHub Actions:"
    Write-Host "  workflow: $Workflow"
    Write-Host "  branch:   $Branch"
    Write-Host "  tag:      $ImageTag"
    Write-Host "  services: $Services"
    exit 0
}

Write-Host "[3/5] Waiting for build workflow: $BuildWorkflow"
$headSha = (git rev-parse HEAD).Trim()
$buildRunId = ""

for ($i = 0; $i -lt 12; $i++) {
    $runList = gh run list --workflow $BuildWorkflow --branch $Branch --limit 10 --json databaseId,headSha | ConvertFrom-Json
    $matchedRun = $runList | Where-Object { $_.headSha -eq $headSha } | Select-Object -First 1
    if ($matchedRun) {
        $buildRunId = [string]$matchedRun.databaseId
        break
    }
    Start-Sleep -Seconds 5
}

if ([string]::IsNullOrWhiteSpace($buildRunId)) {
    throw "Could not find a build run for commit $headSha"
}

gh run watch $buildRunId --exit-status

Write-Host "[4/5] Triggering deploy workflow: $Workflow"
gh workflow run $Workflow --ref $Branch -f "image_tag=$ImageTag" -f "services=$Services"

Write-Host "[5/5] Latest deploy run"
gh run list --workflow $Workflow --limit 1

Write-Host "Release command finished."
