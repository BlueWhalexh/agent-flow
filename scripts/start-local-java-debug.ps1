$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$composeDir = Join-Path $repoRoot "docker\PaiFlow"

Set-Location $composeDir
docker compose up -d mysql redis minio core-aitools console-hub console-frontend

Write-Host ""
Write-Host "Docker services are ready for local Java debugging."
Write-Host "Open IDEA and run core-workflow-java with these environment variables:"
Write-Host ""
Write-Host "MYSQL_HOST=localhost"
Write-Host "MYSQL_PORT=3307"
Write-Host "MYSQL_USER=root"
Write-Host "MYSQL_PASSWORD=123456"
Write-Host "MYSQL_DB=paiflow-workflow"
Write-Host "MYSQL_LINK_DB=paiflow-link"
Write-Host "REDIS_HOST=localhost"
Write-Host "REDIS_PORT=6379"
Write-Host "OSS_ENDPOINT=http://localhost:9000"
Write-Host "OSS_REMOTE_ENDPOINT=http://localhost:9000"
Write-Host "OSS_ACCESS_KEY_ID=minioadmin"
Write-Host "OSS_ACCESS_KEY_SECRET=minioadmin"
Write-Host "OSS_BUCKET_CONSOLE=aitools"
Write-Host "MODEL_SERVICE_URL=http://localhost:8081"
Write-Host "AITOOLS_URL=http://localhost:18668"
Write-Host "SERVER_PORT=7882"
Write-Host ""
Write-Host "Optional TTS variables depend on your local .env values in docker/PaiFlow/.env."
