SELECT id, category, name, LEFT(value, 100) as value_preview FROM `paiflow-console`.`config_info` WHERE category = 'WORKFLOW_NODE_TEMPLATE' LIMIT 3;
SELECT TABLE_NAME, TABLE_COLLATION FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'paiflow-console' AND TABLE_NAME = 'config_info';
