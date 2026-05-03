$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$workflowDir = Join-Path $repoRoot "core-workflow-java"

$env:JAVA_HOME = "C:\Users\xuehang\.jdks\ms-21.0.10"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

$env:MYSQL_HOST = "localhost"
$env:MYSQL_PORT = "3307"
$env:MYSQL_USER = "root"
$env:MYSQL_PASSWORD = "123456"
$env:MYSQL_DB = "paiflow-workflow"
$env:MYSQL_LINK_DB = "paiflow-link"

$env:REDIS_HOST = "localhost"
$env:REDIS_PORT = "6379"
$env:REDIS_PASSWORD = ""

$env:OSS_ENDPOINT = "http://localhost:9000"
$env:OSS_REMOTE_ENDPOINT = "http://localhost:9000"
$env:OSS_ACCESS_KEY_ID = "minioadmin"
$env:OSS_ACCESS_KEY_SECRET = "minioadmin"
$env:OSS_BUCKET_CONSOLE = "aitools"

$env:MODEL_SERVICE_URL = "http://localhost:8081"
$env:AITOOLS_URL = "http://localhost:18668"

$env:TTS_SOURCE = "spark"
$env:SPARK_APP_ID = "ae60f864"
$env:SPARK_API_KEY = "40daadbe66eaeb3343d7e387d658a50f"
$env:SPARK_API_SECRET = "YTRhNWU4NmEwODJlZDJiOGQ2OGI2MzNm"
$env:SPARK_TTS_URL = "wss://cbm01.cn-huabei-1.xf-yun.com/v1/private/mcd9m97e6"

Set-Location $workflowDir
mvn "-Dmaven.repo.local=E:\DevPath\apache-maven-3.9.10-bin\apache-maven-3.9.10\repository" "spring-boot:run" "-Dspring-boot.run.main-class=com.iflytek.astron.workflow.WorkflowApplication"
