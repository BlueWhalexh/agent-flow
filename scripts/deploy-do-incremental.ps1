param(
    [string]$ServerHost = "146.190.97.62",
    [string]$User = "xuehang",
    [string]$KeyPath = "$env:USERPROFILE\\.ssh\\do_digitalocean_ed25519",
    [string]$RemoteRoot = "/opt/PaiFlow",
    [string[]]$PathPrefixes = @(),
    [string[]]$Services = @(),
    [string[]]$SqlFiles = @(),
    [switch]$SkipBuild,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

function Normalize-ListParameter {
    param([string[]]$Values)

    $items = @()
    foreach ($value in $Values) {
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }
        $items += $value.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    }
    return $items | Where-Object { $_ } | Sort-Object -Unique
}

function Resolve-RepoRoot {
    $scriptDir = Split-Path -Parent $PSCommandPath
    return (Resolve-Path (Join-Path $scriptDir "..")).Path
}

function Get-RelativeRepoFiles {
    param(
        [string]$RepoRoot,
        [string[]]$InputFiles
    )

    $items = @()
    foreach ($file in $InputFiles) {
        $full = if ([System.IO.Path]::IsPathRooted($file)) {
            (Resolve-Path $file).Path
        } else {
            (Resolve-Path (Join-Path $RepoRoot $file)).Path
        }

        if (-not $full.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "文件必须位于仓库内: $file"
        }

        $relative = $full.Substring($RepoRoot.Length).TrimStart('\').Replace('\', '/')
        $items += $relative
    }
    return $items
}

function Get-ChangedFiles {
    param([string]$RepoRoot)

    $tracked = @()
    $tracked += git -c core.safecrlf=false -C $RepoRoot diff --name-only 2>$null
    $tracked += git -c core.safecrlf=false -C $RepoRoot diff --cached --name-only 2>$null
    $tracked += git -c core.safecrlf=false -C $RepoRoot ls-files --others --exclude-standard 2>$null
    return $tracked | Where-Object { $_ } | Sort-Object -Unique
}

function Get-DefaultDeployFiles {
    return @(
        ".dockerignore",
        "docker/PaiFlow/docker-compose.server.yaml",
        "docker/PaiFlow/.env.server.example",
        "docker/PaiFlow/mysql/initdb/zz-ai-podcast-v2.sql"
    )
}

function Get-ExcludedDeployFiles {
    return @(
        "AGENTS.md",
        "console/backend/hub/src/main/resources/application-local.yml",
        "core/plugin/aitools/config.env"
    )
}

function Get-InferredServices {
    param([string[]]$Paths)

    $set = New-Object System.Collections.Generic.HashSet[string]
    foreach ($path in $Paths) {
        $normalized = $path.Replace('\', '/')
        if ($normalized.StartsWith("console/frontend/")) {
            [void]$set.Add("console-frontend")
        }
        if ($normalized.StartsWith("console/backend/")) {
            [void]$set.Add("console-hub")
        }
        if ($normalized.StartsWith("core-workflow-java/")) {
            [void]$set.Add("core-workflow-java")
        }
        if ($normalized.StartsWith("core/plugin/aitools/")) {
            [void]$set.Add("core-aitools")
        }
        if ($normalized.StartsWith("docker/PaiFlow/")) {
            if ($normalized -match "Dockerfile\.frontend") {
                [void]$set.Add("console-frontend")
            }
            if ($normalized -match "Dockerfile\.backend") {
                [void]$set.Add("console-hub")
            }
            if ($normalized -match "Dockerfile\.workflow") {
                [void]$set.Add("core-workflow-java")
            }
            if ($normalized -match "docker-compose|\.env\.server\.example") {
                [void]$set.Add("console-frontend")
                [void]$set.Add("console-hub")
                [void]$set.Add("core-workflow-java")
                [void]$set.Add("core-aitools")
            }
        }
    }
    return @($set) | Sort-Object -Unique
}

function Copy-StagedFile {
    param(
        [string]$RepoRoot,
        [string]$StageRoot,
        [string]$RelativePath
    )

    $source = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path $source)) {
        throw "文件不存在: $RelativePath"
    }

    $target = Join-Path $StageRoot $RelativePath
    $parent = Split-Path -Parent $target
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $source -Destination $target -Force
}

$repoRoot = Resolve-RepoRoot
$PathPrefixes = Normalize-ListParameter -Values $PathPrefixes
$Services = Normalize-ListParameter -Values $Services
$SqlFiles = Normalize-ListParameter -Values $SqlFiles
$changedFiles = Get-ChangedFiles -RepoRoot $repoRoot
$sqlRelativeFiles = Get-RelativeRepoFiles -RepoRoot $repoRoot -InputFiles $SqlFiles

$deployFiles = @()
$deployFiles += Get-DefaultDeployFiles
$deployFiles += $changedFiles
$deployFiles += $sqlRelativeFiles

$excludedFiles = Get-ExcludedDeployFiles
$deployFiles = $deployFiles |
    Where-Object { $_ -and $_ -notin $excludedFiles } |
    Where-Object { $_ -and $_ -notmatch '^(analyze_api|byte_check|check_all_chinese|decode_|fix_|search_|template_search|api_|chinese_check|garbled_search|node_template_search|nul)' } |
    Sort-Object -Unique

if ($PathPrefixes.Count -gt 0) {
    $alwaysInclude = (Get-DefaultDeployFiles) + $sqlRelativeFiles
    $deployFiles = $deployFiles | Where-Object {
        $path = $_.Replace('\', '/')
        $alwaysInclude -contains $_ -or ($PathPrefixes | Where-Object { $path.StartsWith($_.Replace('\', '/')) } | Measure-Object).Count -gt 0
    } | Sort-Object -Unique
}

$effectiveServices = if ($Services.Count -gt 0) { $Services } else { Get-InferredServices -Paths $deployFiles }

Write-Host "仓库路径: $repoRoot"
Write-Host "本次同步文件数: $($deployFiles.Count)"
Write-Host "本次重建服务: $([string]::Join(', ', $effectiveServices))"
if ($sqlRelativeFiles.Count -gt 0) {
    Write-Host "本次执行 SQL:"
    $sqlRelativeFiles | ForEach-Object { Write-Host "  - $_" }
}

if ($CheckOnly) {
    Write-Host ""
    Write-Host "将上传的文件:"
    $deployFiles | ForEach-Object { Write-Host "  - $_" }
    exit 0
}

$stageRoot = Join-Path $env:TEMP ("paiflow-deploy-" + [System.Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $env:TEMP ("paiflow-deploy-" + [System.Guid]::NewGuid().ToString("N") + ".tar.gz")
New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

try {
    foreach ($relativePath in $deployFiles) {
        Copy-StagedFile -RepoRoot $repoRoot -StageRoot $stageRoot -RelativePath $relativePath
    }

    tar -czf $archivePath -C $stageRoot .
    if ($LASTEXITCODE -ne 0) {
        throw "打包失败"
    }

    $remoteArchive = "/tmp/" + [System.IO.Path]::GetFileName($archivePath)
    & scp -i $KeyPath $archivePath "${User}@${ServerHost}:$remoteArchive"
    if ($LASTEXITCODE -ne 0) {
        throw "上传失败"
    }

    $remoteBuildBlock = ""
    if (-not $SkipBuild -and $effectiveServices.Count -gt 0) {
        $serviceList = [string]::Join(" ", $effectiveServices)
        $remoteBuildBlock = @"
docker compose up -d --build $serviceList
"@
    }

    $remoteSqlBlock = ""
    if ($sqlRelativeFiles.Count -gt 0) {
        $remoteSqlBlock = @"
MYSQL_PASSWORD=`$(grep '^MYSQL_ROOT_PASSWORD=' .env | head -n 1 | cut -d= -f2-)
if [ -z "`$MYSQL_PASSWORD" ]; then
  echo '未能从 .env 读取 MYSQL_ROOT_PASSWORD' >&2
  exit 1
fi
"@
        foreach ($sql in $sqlRelativeFiles) {
            $remoteSqlBlock += @"
echo '执行 SQL: $sql'
MYSQL_PWD="`$MYSQL_PASSWORD" docker exec -i paiflow-mysql mysql -uroot < "$RemoteRoot/$sql"
"@
        }
    }

    $remoteScript = @"
set -e
mkdir -p $RemoteRoot
tar -xzf $remoteArchive -C $RemoteRoot
cd $RemoteRoot/docker/PaiFlow
cp docker-compose.server.yaml docker-compose.yaml
$remoteBuildBlock
$remoteSqlBlock
docker compose ps
echo '--- console-hub health ---'
docker exec paiflow-console-hub wget -qO- http://localhost:8080/actuator/health || true
echo
echo '--- core-workflow-java health ---'
docker exec paiflow-core-workflow-java wget -qO- http://localhost:7880/actuator/health || true
rm -f $remoteArchive
"@

    & ssh -i $KeyPath "${User}@${ServerHost}" $remoteScript
    if ($LASTEXITCODE -ne 0) {
        throw "远端发布失败"
    }
}
finally {
    if (Test-Path $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    if (Test-Path $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
}
