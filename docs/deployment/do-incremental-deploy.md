# PaiFlow 线上增量部署说明

## 目标

这套流程专门用于维护 `146.190.97.62:/opt/PaiFlow` 的线上环境，重点解决三个问题：

- 线上目录不是 `git clone`，不能指望服务器直接 `git pull`
- 本地开发配置和线上收口配置不同，不能直接把开发用 `docker-compose.yaml` 覆盖到线上
- 数据变更和代码变更经常一起出现，最好能在一次发布里按顺序完成

## 推荐做法

优先使用 `scripts/deploy-do-incremental.ps1` 进行发布。脚本做的事情是：

1. 从当前仓库挑出需要同步的文件，打成一个临时增量包
2. 通过 `scp` 上传到服务器
3. 解压覆盖到 `/opt/PaiFlow`
4. 用 `docker/PaiFlow/docker-compose.server.yaml` 刷新线上 `docker-compose.yaml`
5. 按需要重建指定服务
6. 按顺序执行指定 SQL 补丁
7. 输出容器状态和健康检查结果

## 常用命令

只看本次会上传什么，不真正发布：

```powershell
.\scripts\deploy-do-incremental.ps1 -CheckOnly
```

发布 workflow、aitools 和 docker 配置，并补 Xiaomi 工具数据：

```powershell
.\scripts\deploy-do-incremental.ps1 `
  -PathPrefixes @("core-workflow-java","docker/PaiFlow") `
  -Services @("core-workflow-java","core-aitools") `
  -SqlFiles @("docker/PaiFlow/mysql/add-xiaomi-tts-tool.sql","docker/PaiFlow/mysql/add-xiaomi-multimodal-tools.sql")
```

只补数据库，不重建镜像：

```powershell
.\scripts\deploy-do-incremental.ps1 `
  -PathPrefixes @("docker/PaiFlow") `
  -SkipBuild `
  -SqlFiles @("docker/PaiFlow/mysql/add-xiaomi-tts-tool.sql","docker/PaiFlow/mysql/add-xiaomi-multimodal-tools.sql")
```

## 本次已确认的线上差异

- 线上数据库里还没有 Xiaomi TTS / Image / Audio / Video / Web Search 这 5 条工具记录
- 线上目录是上传式工作目录，不是 git 仓库
- 线上实际运行的是“服务器专用 compose 逻辑”，本地仓库需要独立保存，不要再混进开发 compose
- MySQL 初始化脚本里，播客 SQL 必须放在基础库脚本之后执行

## 注意事项

- 不要把 `docker/PaiFlow/.env` 提交进仓库
- 发布前先确认本地未跟踪的调试文件不会被脚本带上
- 如果本次只改了 SQL，不要顺手重建全套服务
- 如果要全量重建数据库卷，先确认 `docker/PaiFlow/mysql/initdb/zz-ai-podcast-v2.sql` 排在最后
