#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"

if [ -z "$MYSQL_PASSWORD" ]; then
    echo -e "${YELLOW}请输入 MySQL root 用户密码 (直接回车使用默认值: 123456):${NC}"
    read -s MYSQL_PASSWORD
    echo ""

    if [ -z "$MYSQL_PASSWORD" ]; then
        MYSQL_PASSWORD="123456"
    fi
fi

MYSQL_CNF=$(mktemp)
echo "[client]" > "$MYSQL_CNF"
echo "user=$MYSQL_USER" >> "$MYSQL_CNF"
echo "password=$MYSQL_PASSWORD" >> "$MYSQL_CNF"
echo "host=$MYSQL_HOST" >> "$MYSQL_CNF"
echo "port=$MYSQL_PORT" >> "$MYSQL_CNF"

trap 'rm -f "$MYSQL_CNF"' EXIT

echo -e "${YELLOW}开始修复本地 MySQL 字符集...${NC}"

# Fix database character sets
mysql --defaults-extra-file="$MYSQL_CNF" <<'EOF'
ALTER DATABASE `paiflow-workflow` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
ALTER DATABASE `paiflow-tenant` CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
ALTER DATABASE `paiflow-console` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
ALTER DATABASE `paiflow-agent` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
ALTER DATABASE `paiflow-link` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
EOF

# Generate and execute table conversion statements for all databases
for db in paiflow-workflow paiflow-tenant paiflow-console paiflow-agent paiflow-link; do
    collation="utf8mb4_0900_ai_ci"
    if [ "$db" = "paiflow-tenant" ]; then
        collation="utf8mb4_bin"
    fi

    echo -e "${YELLOW}修复数据库 $db 中的所有表...${NC}"

    mysql --defaults-extra-file="$MYSQL_CNF" -N -e "
        SELECT CONCAT('ALTER TABLE \`$db\`.\`', table_name, '\` CONVERT TO CHARACTER SET utf8mb4 COLLATE $collation;')
        FROM information_schema.tables
        WHERE table_schema = '$db' AND table_type = 'BASE TABLE';
    " | mysql --defaults-extra-file="$MYSQL_CNF"
done

echo -e "${YELLOW}校验是否还存在 utf8mb3 表...${NC}"
mysql --defaults-extra-file="$MYSQL_CNF" -N -e "
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA IN ('paiflow-workflow', 'paiflow-tenant', 'paiflow-console', 'paiflow-agent', 'paiflow-link')
  AND TABLE_COLLATION LIKE 'utf8mb3%';"

echo -e "${GREEN}✓ 本地 MySQL 字符集修复完成${NC}"
