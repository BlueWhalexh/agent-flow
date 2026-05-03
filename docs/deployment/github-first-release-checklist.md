# PaiFlow GitHub 首发清单

## 目标

把当前本地改动整理成几组更适合 GitHub 首发和后续 PR 审查的提交，而不是把所有变更一次性混在一起。

## 推荐提交顺序

### 提交 1：CI/CD 与生产部署基础设施

这一提交只放 GitHub Actions、GHCR、生产 compose 和部署文档。

建议包含：

- `.gitignore`
- `.dockerignore`
- `.github/workflows/ghcr-build-images.yml`
- `.github/workflows/deploy-production.yml`
- `docker/PaiFlow/.env.prod.example`
- `docker/PaiFlow/.env.server.example`
- `docker/PaiFlow/docker-compose.prod.yaml`
- `docker/PaiFlow/docker-compose.server.yaml`
- `docs/deployment/github-actions-ghcr.md`
- `docs/deployment/do-incremental-deploy.md`
- `docs/deployment/github-first-release-checklist.md`
- `scripts/deploy-do-incremental.ps1`
- `scripts/server/deploy-ghcr.sh`

参考命令：

```powershell
git add .gitignore .dockerignore
git add .github/workflows/ghcr-build-images.yml .github/workflows/deploy-production.yml
git add docker/PaiFlow/.env.prod.example docker/PaiFlow/.env.server.example
git add docker/PaiFlow/docker-compose.prod.yaml docker/PaiFlow/docker-compose.server.yaml
git add docs/deployment/github-actions-ghcr.md docs/deployment/do-incremental-deploy.md docs/deployment/github-first-release-checklist.md
git add scripts/deploy-do-incremental.ps1 scripts/server/deploy-ghcr.sh
```

建议提交信息：

```text
chore: add GitHub Actions and production deployment pipeline
```

### 提交 2：Workflow Java 与 Xiaomi 能力接入

这一提交只放核心后端能力变更。

建议包含：

- `core-workflow-java/src/main/java/com/iflytek/astron/link/controller/tools/OfficialToolController.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/link/controller/vo/res/ToolManagerResponse.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/integration/plugins/PluginServiceClient.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/integration/plugins/mimo/XiaomiMultimodalIntegration.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/integration/plugins/mimo/XiaomiMultimodalMode.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/integration/plugins/tts/SmartTTSIntegration.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/integration/plugins/tts/XiaomiTTSIntegration.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/node/AbstractNodeExecutor.java`
- `core-workflow-java/src/main/java/com/iflytek/astron/workflow/engine/node/impl/llm/LLMNodeExecutor.java`
- `core-workflow-java/src/main/resources/application.yml`
- `docker/PaiFlow/Dockerfile.workflow`
- `docker/PaiFlow/Dockerfile.workflow.mirror`

建议提交信息：

```text
feat: add xiaomi multimodal and TTS workflow support
```

### 提交 3：部署与数据库补丁

这一提交只放线上部署相关的 SQL 和 Docker 运行时调整。

建议包含：

- `docker/PaiFlow/.env.example`
- `docker/PaiFlow/Dockerfile.backend`
- `docker/PaiFlow/Dockerfile.frontend`
- `docker/PaiFlow/docker-compose.yaml`
- `docker/PaiFlow/fix-docker-mysql-charset.sh`
- `docker/PaiFlow/mysql/link.sql`
- `docker/PaiFlow/mysql/schema.sql`
- `docker/PaiFlow/mysql/99-ai-podcast-v2.sql`
- `docker/PaiFlow/mysql/add-xiaomi-tts-tool.sql`
- `docker/PaiFlow/mysql/add-xiaomi-multimodal-tools.sql`
- `docker/PaiFlow/mysql/check_charset.sql`
- `docker/PaiFlow/mysql/fix_globals.sql`
- `docker/PaiFlow/mysql/test_charset.sql`
- `docker/PaiFlow/mysql/initdb/schema.sql`
- `docker/PaiFlow/mysql/initdb/workflow.sql`
- `docker/PaiFlow/mysql/initdb/link.sql`
- `docker/PaiFlow/mysql/initdb/tenant.sql`
- `docker/PaiFlow/mysql/initdb/agent.sql`
- `docker/PaiFlow/mysql/initdb/zz-ai-podcast-v2.sql`
- `scripts/fix-local-mysql-charset.sh`
- `scripts/run-workflow-local.ps1`
- `scripts/start-local-java-debug.ps1`

建议提交信息：

```text
chore: update deployment assets and database patches
```

### 提交 4：前端与 console 功能迭代

这一提交放 UI 和 console 侧改动，避免和基础设施混在一起。

建议包含：

- `console/backend/hub/src/main/resources/application.yml`
- `console/backend/hub/src/main/resources/application-local.yml`
- `console/backend/toolkit/src/main/java/com/iflytek/astron/console/toolkit/sse/WorkflowSseEventSourceListener.java`
- `console/frontend/src/components/markdown-render/index.tsx`
- `console/frontend/src/components/sidebar/notice-modal/index.module.scss`
- `console/frontend/src/components/workflow/hooks/use-one-click-update.tsx`
- `console/frontend/src/components/workflow/store/flow-chat-function.ts`
- `console/frontend/src/components/workflow/utils/reactflowUtils.ts`

建议提交信息：

```text
feat: improve console workflow interaction experience
```

## 暂不建议首发带上的内容

这些内容要么是本地偏好，要么是与 GitHub 首发无关：

- `AGENTS.md`
- `core/plugin/aitools/config.env`
- `docker/PaiFlow/AI 播客.yml`

## GitHub 初始化后还要做的事情

1. 创建 GitHub 仓库
2. 把本地 `origin` 切到 GitHub
3. 配置 Secrets
4. 首次 push
5. 等待 `GHCR Build Images` 成功
6. 手动触发 `Deploy Production`
