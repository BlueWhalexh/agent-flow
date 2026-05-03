SET NAMES utf8mb4;
SELECT id, name, LEFT(value, 50) as value_preview FROM `paiflow-console`.`config_info` WHERE category = 'WORKFLOW_NODE_TEMPLATE' LIMIT 1;
SELECT HEX(LEFT(value, 20)) as hex_value FROM `paiflow-console`.`config_info` WHERE id = 1421;
