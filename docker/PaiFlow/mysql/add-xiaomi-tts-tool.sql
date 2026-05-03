DELETE FROM `paiflow-console`.tool_box
WHERE tool_id = 'tool@8b22xmtts21000';

INSERT INTO `paiflow-console`.tool_box (
  tool_id,
  name,
  description,
  icon,
  user_id,
  app_id,
  end_point,
  method,
  web_schema,
  `schema`,
  visibility,
  deleted,
  create_time,
  update_time,
  is_public,
  favorite_count,
  usage_count,
  tool_tag,
  operation_id,
  creation_method,
  auth_type,
  auth_info,
  top,
  source,
  display_source,
  avatar_color,
  status,
  version,
  temporary_data,
  space_id
)
SELECT
  'tool@8b22xmtts21000',
  'Xiaomi TTS',
  'Xiaomi MiMo TTS voice synthesis',
  icon,
  user_id,
  app_id,
  end_point,
  method,
  REPLACE(
    REPLACE(web_schema, 'x5_lingfeiyi_flow', 'mimo_default'),
    'x6_lingfeiyi_pro', 'mimo_default'
  ),
  REPLACE(
    REPLACE(`schema`, 'x5_lingfeiyi_flow', 'mimo_default'),
    'x6_lingfeiyi_pro', 'mimo_default'
  ),
  visibility,
  deleted,
  NOW(),
  NOW(),
  is_public,
  favorite_count,
  usage_count,
  tool_tag,
  operation_id,
  creation_method,
  auth_type,
  auth_info,
  top,
  source,
  display_source,
  avatar_color,
  status,
  version,
  temporary_data,
  space_id
FROM `paiflow-console`.tool_box
WHERE tool_id = 'tool@8b2262bef821000';

UPDATE `paiflow-console`.tool_box
SET
  name = 'Xiaomi TTS',
  description = 'Xiaomi MiMo TTS voice synthesis'
WHERE tool_id = 'tool@8b22xmtts21000';

DELETE FROM `paiflow-link`.tools_schema
WHERE tool_id = 'tool@8b22xmtts21000';

INSERT INTO `paiflow-link`.tools_schema (
  app_id,
  tool_id,
  name,
  description,
  open_api_schema,
  create_at,
  update_at,
  mcp_server_url,
  `schema`,
  version,
  is_deleted
)
SELECT
  app_id,
  'tool@8b22xmtts21000',
  'Xiaomi TTS',
  'Xiaomi MiMo TTS voice synthesis',
  REPLACE(
    REPLACE(open_api_schema, 'x5_lingfeiyi_flow', 'mimo_default'),
    'x6_lingfeiyi_pro', 'mimo_default'
  ),
  NOW(6),
  NOW(6),
  mcp_server_url,
  `schema`,
  version,
  is_deleted
FROM `paiflow-link`.tools_schema
WHERE tool_id = 'tool@8b2262bef821000';

SELECT id, tool_id, name, operation_id
FROM `paiflow-console`.tool_box
WHERE tool_id = 'tool@8b22xmtts21000';

SELECT id, tool_id, name, version
FROM `paiflow-link`.tools_schema
WHERE tool_id = 'tool@8b22xmtts21000';
