#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}错误: 未找到 docker 命令${NC}"
    exit 1
fi

echo -e "${YELLOW}检查 MySQL 容器状态...${NC}"
if ! docker compose ps mysql >/dev/null 2>&1; then
    echo -e "${RED}错误: 当前目录不是有效的 Docker Compose 目录，或 mysql 服务不存在${NC}"
    exit 1
fi

for i in {1..30}; do
    if docker compose exec -T mysql sh -lc 'mysqladmin ping -h localhost -uroot -p"$MYSQL_ROOT_PASSWORD" >/dev/null 2>&1'; then
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo -e "${RED}错误: MySQL 容器未就绪，请先执行 docker compose up -d mysql${NC}"
        exit 1
    fi

    sleep 2
done

echo -e "${YELLOW}开始修复 Docker MySQL 字符集...${NC}"
cat <<'EOF' | docker compose exec -T mysql sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'
ALTER DATABASE `paiflow-workflow` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
ALTER DATABASE `paiflow-tenant` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
ALTER DATABASE `paiflow-console` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
ALTER DATABASE `paiflow-agent` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
ALTER DATABASE `paiflow-link` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
EOF

echo -e "${YELLOW}修复所有数据库中的表字符集...${NC}"
docker compose exec -T mysql sh -lc '
mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT CONCAT(\"ALTER TABLE \\\"`paiflow-workflow`\\\".\\\"\", table_name, \"\\\" CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;\")
    FROM information_schema.tables
    WHERE table_schema = \"paiflow-workflow\" AND table_type = \"BASE TABLE\";
" > /tmp/fix_charset.sql

mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT CONCAT(\"ALTER TABLE \\\"`paiflow-tenant`\\\".\\\"\", table_name, \"\\\" CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;\")
    FROM information_schema.tables
    WHERE table_schema = \"paiflow-tenant\" AND table_type = \"BASE TABLE\";
" >> /tmp/fix_charset.sql

mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT CONCAT(\"ALTER TABLE \\\"`paiflow-console`\\\".\\\"\", table_name, \"\\\" CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;\")
    FROM information_schema.tables
    WHERE table_schema = \"paiflow-console\" AND table_type = \"BASE TABLE\";
" >> /tmp/fix_charset.sql

mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT CONCAT(\"ALTER TABLE \\\"`paiflow-agent`\\\".\\\"\", table_name, \"\\\" CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;\")
    FROM information_schema.tables
    WHERE table_schema = \"paiflow-agent\" AND table_type = \"BASE TABLE\";
" >> /tmp/fix_charset.sql

mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
    SELECT CONCAT(\"ALTER TABLE \\\"`paiflow-link`\\\".\\\"\", table_name, \"\\\" CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;\")
    FROM information_schema.tables
    WHERE table_schema = \"paiflow-link\" AND table_type = \"BASE TABLE\";
" >> /tmp/fix_charset.sql

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "source /tmp/fix_charset.sql"
rm -f /tmp/fix_charset.sql
'

echo -e "${YELLOW}校验是否还存在 utf8mb3 表...${NC}"
docker compose exec -T mysql sh -lc 'mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA IN ('\''paiflow-workflow'\'', '\''paiflow-tenant'\'', '\''paiflow-console'\'', '\''paiflow-agent'\'', '\''paiflow-link'\'')
  AND TABLE_COLLATION LIKE '\''utf8mb3%'\'';"'

echo -e "${GREEN}✓ Docker MySQL 字符集修复完成${NC}"
