SET @output_schema = JSON_OBJECT(
  'toolRequestOutput', JSON_ARRAY(
    JSON_OBJECT('id', 'out_code', 'name', 'code', 'description', 'Status code', 'type', 'integer', 'open', true),
    JSON_OBJECT('id', 'out_message', 'name', 'message', 'description', 'Status message', 'type', 'string', 'open', true),
    JSON_OBJECT('id', 'out_sid', 'name', 'sid', 'description', 'Workflow session id', 'type', 'string', 'open', true),
    JSON_OBJECT(
      'id', 'out_data',
      'name', 'data',
      'description', 'Response data',
      'type', 'object',
      'open', true,
      'children', JSON_ARRAY(
        JSON_OBJECT('id', 'out_data_content', 'name', 'content', 'description', 'Generated content', 'type', 'string', 'open', true, 'fatherType', 'object'),
        JSON_OBJECT('id', 'out_data_answer', 'name', 'answer', 'description', 'Generated answer', 'type', 'string', 'open', true, 'fatherType', 'object'),
        JSON_OBJECT('id', 'out_data_reasoning', 'name', 'reasoning_content', 'description', 'Reasoning content', 'type', 'string', 'open', true, 'fatherType', 'object'),
        JSON_OBJECT(
          'id', 'out_data_annotations',
          'name', 'annotations',
          'description', 'Web search citations',
          'type', 'array',
          'open', true,
          'fatherType', 'object',
          'children', JSON_ARRAY(
            JSON_OBJECT(
              'id', 'out_data_annotations_item',
              'name', 'item',
              'description', 'Citation item',
              'type', 'object',
              'open', true,
              'fatherType', 'array',
              'children', JSON_ARRAY(
                JSON_OBJECT('id', 'out_data_annotations_item_type', 'name', 'type', 'description', 'Citation type', 'type', 'string', 'open', true, 'fatherType', 'object'),
                JSON_OBJECT('id', 'out_data_annotations_item_url', 'name', 'url', 'description', 'Citation URL', 'type', 'string', 'open', true, 'fatherType', 'object'),
                JSON_OBJECT('id', 'out_data_annotations_item_title', 'name', 'title', 'description', 'Citation title', 'type', 'string', 'open', true, 'fatherType', 'object'),
                JSON_OBJECT('id', 'out_data_annotations_item_summary', 'name', 'summary', 'description', 'Citation summary', 'type', 'string', 'open', true, 'fatherType', 'object'),
                JSON_OBJECT('id', 'out_data_annotations_item_site_name', 'name', 'site_name', 'description', 'Citation site name', 'type', 'string', 'open', true, 'fatherType', 'object')
              )
            )
          )
        )
      )
    )
  )
);

SET @image_web_schema = JSON_MERGE_PATCH(
  JSON_OBJECT(
    'toolRequestInput', JSON_ARRAY(
      JSON_OBJECT('id', 'in_image_url', 'name', 'image_url', 'description', 'Public image URL or data URL/base64 string', 'type', 'string', 'location', 'body', 'required', true, 'default', '', 'open', true, 'from', 2, 'startDisabled', true),
      JSON_OBJECT('id', 'in_image_mime_type', 'name', 'image_mime_type', 'description', 'MIME type used when image_url is raw base64', 'type', 'string', 'location', 'body', 'required', false, 'default', 'image/png', 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_prompt', 'name', 'prompt', 'description', 'Question or instruction for the image', 'type', 'string', 'location', 'body', 'required', true, 'default', 'please describe the content of the image', 'open', true, 'from', 2)
    )
  ),
  @output_schema
);

SET @audio_web_schema = JSON_MERGE_PATCH(
  JSON_OBJECT(
    'toolRequestInput', JSON_ARRAY(
      JSON_OBJECT('id', 'in_audio_url', 'name', 'audio_url', 'description', 'Public audio URL or data URL/base64 string', 'type', 'string', 'location', 'body', 'required', true, 'default', '', 'open', true, 'from', 2, 'startDisabled', true),
      JSON_OBJECT('id', 'in_audio_mime_type', 'name', 'audio_mime_type', 'description', 'MIME type used when audio_url is raw base64', 'type', 'string', 'location', 'body', 'required', false, 'default', 'audio/wav', 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_prompt', 'name', 'prompt', 'description', 'Question or instruction for the audio', 'type', 'string', 'location', 'body', 'required', true, 'default', 'please describe the content of the audio', 'open', true, 'from', 2)
    )
  ),
  @output_schema
);

SET @video_web_schema = JSON_MERGE_PATCH(
  JSON_OBJECT(
    'toolRequestInput', JSON_ARRAY(
      JSON_OBJECT('id', 'in_video_url', 'name', 'video_url', 'description', 'Public video URL or data URL/base64 string', 'type', 'string', 'location', 'body', 'required', true, 'default', '', 'open', true, 'from', 2, 'startDisabled', true),
      JSON_OBJECT('id', 'in_video_mime_type', 'name', 'video_mime_type', 'description', 'MIME type used when video_url is raw base64', 'type', 'string', 'location', 'body', 'required', false, 'default', 'video/mp4', 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_prompt', 'name', 'prompt', 'description', 'Question or instruction for the video', 'type', 'string', 'location', 'body', 'required', true, 'default', 'please describe the content of the video', 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_fps', 'name', 'fps', 'description', 'Video frame sampling rate', 'type', 'integer', 'location', 'body', 'required', false, 'default', 2, 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_media_resolution', 'name', 'media_resolution', 'description', 'Video resolution mode: default or max', 'type', 'string', 'location', 'body', 'required', false, 'default', 'default', 'open', true, 'from', 2)
    )
  ),
  @output_schema
);

SET @web_search_schema = JSON_MERGE_PATCH(
  JSON_OBJECT(
    'toolRequestInput', JSON_ARRAY(
      JSON_OBJECT('id', 'in_query', 'name', 'query', 'description', 'Search question or task', 'type', 'string', 'location', 'body', 'required', true, 'default', '', 'open', true, 'from', 2, 'startDisabled', true),
      JSON_OBJECT('id', 'in_max_keyword', 'name', 'max_keyword', 'description', 'Maximum search keywords', 'type', 'integer', 'location', 'body', 'required', false, 'default', 3, 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_limit', 'name', 'limit', 'description', 'Maximum returned pages per search', 'type', 'integer', 'location', 'body', 'required', false, 'default', 3, 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_force_search', 'name', 'force_search', 'description', 'Force web search', 'type', 'boolean', 'location', 'body', 'required', false, 'default', true, 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_country', 'name', 'country', 'description', 'Optional user country', 'type', 'string', 'location', 'body', 'required', false, 'default', 'China', 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_region', 'name', 'region', 'description', 'Optional user region', 'type', 'string', 'location', 'body', 'required', false, 'default', '', 'open', true, 'from', 2),
      JSON_OBJECT('id', 'in_city', 'name', 'city', 'description', 'Optional user city', 'type', 'string', 'location', 'body', 'required', false, 'default', '', 'open', true, 'from', 2)
    )
  ),
  @output_schema
);

SET @image_openapi = JSON_OBJECT('openapi', '3.0.0', 'info', JSON_OBJECT('title', 'Xiaomi Image Understanding', 'version', '1.0.0'));
SET @audio_openapi = JSON_OBJECT('openapi', '3.0.0', 'info', JSON_OBJECT('title', 'Xiaomi Audio Understanding', 'version', '1.0.0'));
SET @video_openapi = JSON_OBJECT('openapi', '3.0.0', 'info', JSON_OBJECT('title', 'Xiaomi Video Understanding', 'version', '1.0.0'));
SET @web_openapi = JSON_OBJECT('openapi', '3.0.0', 'info', JSON_OBJECT('title', 'Xiaomi Web Search', 'version', '1.0.0'));

DELETE FROM `paiflow-console`.tool_box
WHERE tool_id IN ('tool@8b22xmimg21000', 'tool@8b22xmaud21000', 'tool@8b22xmvid21000', 'tool@8b22xmweb21000');

INSERT INTO `paiflow-console`.tool_box (
  tool_id, name, description, icon, user_id, app_id, end_point, method, web_schema, `schema`,
  visibility, deleted, create_time, update_time, is_public, favorite_count, usage_count, tool_tag,
  operation_id, creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, version, temporary_data, space_id
)
SELECT 'tool@8b22xmimg21000', 'Xiaomi Image Understanding', 'Xiaomi MiMo image understanding', icon, user_id, app_id, 'http://core-aitools:18668/aitools/v1/mimo/image', 'post', CAST(@image_web_schema AS CHAR), CAST(@image_web_schema AS CHAR),
  visibility, deleted, NOW(), NOW(), is_public, favorite_count, usage_count, tool_tag,
  'xiaomi-image-understanding', creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, 'V1.0', temporary_data, space_id
FROM (SELECT * FROM `paiflow-console`.tool_box WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

INSERT INTO `paiflow-console`.tool_box (
  tool_id, name, description, icon, user_id, app_id, end_point, method, web_schema, `schema`,
  visibility, deleted, create_time, update_time, is_public, favorite_count, usage_count, tool_tag,
  operation_id, creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, version, temporary_data, space_id
)
SELECT 'tool@8b22xmaud21000', 'Xiaomi Audio Understanding', 'Xiaomi MiMo audio understanding', icon, user_id, app_id, 'http://core-aitools:18668/aitools/v1/mimo/audio', 'post', CAST(@audio_web_schema AS CHAR), CAST(@audio_web_schema AS CHAR),
  visibility, deleted, NOW(), NOW(), is_public, favorite_count, usage_count, tool_tag,
  'xiaomi-audio-understanding', creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, 'V1.0', temporary_data, space_id
FROM (SELECT * FROM `paiflow-console`.tool_box WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

INSERT INTO `paiflow-console`.tool_box (
  tool_id, name, description, icon, user_id, app_id, end_point, method, web_schema, `schema`,
  visibility, deleted, create_time, update_time, is_public, favorite_count, usage_count, tool_tag,
  operation_id, creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, version, temporary_data, space_id
)
SELECT 'tool@8b22xmvid21000', 'Xiaomi Video Understanding', 'Xiaomi MiMo video understanding', icon, user_id, app_id, 'http://core-aitools:18668/aitools/v1/mimo/video', 'post', CAST(@video_web_schema AS CHAR), CAST(@video_web_schema AS CHAR),
  visibility, deleted, NOW(), NOW(), is_public, favorite_count, usage_count, tool_tag,
  'xiaomi-video-understanding', creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, 'V1.0', temporary_data, space_id
FROM (SELECT * FROM `paiflow-console`.tool_box WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

INSERT INTO `paiflow-console`.tool_box (
  tool_id, name, description, icon, user_id, app_id, end_point, method, web_schema, `schema`,
  visibility, deleted, create_time, update_time, is_public, favorite_count, usage_count, tool_tag,
  operation_id, creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, version, temporary_data, space_id
)
SELECT 'tool@8b22xmweb21000', 'Xiaomi Web Search', 'Xiaomi MiMo web search', icon, user_id, app_id, 'http://core-aitools:18668/aitools/v1/mimo/web-search', 'post', CAST(@web_search_schema AS CHAR), CAST(@web_search_schema AS CHAR),
  visibility, deleted, NOW(), NOW(), is_public, favorite_count, usage_count, tool_tag,
  'xiaomi-web-search', creation_method, auth_type, auth_info, top, source, display_source, avatar_color,
  status, 'V1.0', temporary_data, space_id
FROM (SELECT * FROM `paiflow-console`.tool_box WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

DELETE FROM `paiflow-link`.tools_schema
WHERE tool_id IN ('tool@8b22xmimg21000', 'tool@8b22xmaud21000', 'tool@8b22xmvid21000', 'tool@8b22xmweb21000');

INSERT INTO `paiflow-link`.tools_schema (app_id, tool_id, name, description, open_api_schema, create_at, update_at, mcp_server_url, `schema`, version, is_deleted)
SELECT app_id, 'tool@8b22xmimg21000', 'Xiaomi Image Understanding', 'Xiaomi MiMo image understanding', CAST(@image_openapi AS CHAR), NOW(6), NOW(6), mcp_server_url, CAST(@image_web_schema AS CHAR), 'V1.0', is_deleted
FROM (SELECT * FROM `paiflow-link`.tools_schema WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

INSERT INTO `paiflow-link`.tools_schema (app_id, tool_id, name, description, open_api_schema, create_at, update_at, mcp_server_url, `schema`, version, is_deleted)
SELECT app_id, 'tool@8b22xmaud21000', 'Xiaomi Audio Understanding', 'Xiaomi MiMo audio understanding', CAST(@audio_openapi AS CHAR), NOW(6), NOW(6), mcp_server_url, CAST(@audio_web_schema AS CHAR), 'V1.0', is_deleted
FROM (SELECT * FROM `paiflow-link`.tools_schema WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

INSERT INTO `paiflow-link`.tools_schema (app_id, tool_id, name, description, open_api_schema, create_at, update_at, mcp_server_url, `schema`, version, is_deleted)
SELECT app_id, 'tool@8b22xmvid21000', 'Xiaomi Video Understanding', 'Xiaomi MiMo video understanding', CAST(@video_openapi AS CHAR), NOW(6), NOW(6), mcp_server_url, CAST(@video_web_schema AS CHAR), 'V1.0', is_deleted
FROM (SELECT * FROM `paiflow-link`.tools_schema WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

INSERT INTO `paiflow-link`.tools_schema (app_id, tool_id, name, description, open_api_schema, create_at, update_at, mcp_server_url, `schema`, version, is_deleted)
SELECT app_id, 'tool@8b22xmweb21000', 'Xiaomi Web Search', 'Xiaomi MiMo web search', CAST(@web_openapi AS CHAR), NOW(6), NOW(6), mcp_server_url, CAST(@web_search_schema AS CHAR), 'V1.0', is_deleted
FROM (SELECT * FROM `paiflow-link`.tools_schema WHERE tool_id IN ('tool@8b22xmtts21000', 'tool@8b2262bef821000') ORDER BY FIELD(tool_id, 'tool@8b22xmtts21000', 'tool@8b2262bef821000') LIMIT 1) src;

SELECT tool_id, name, operation_id, version
FROM `paiflow-console`.tool_box
WHERE tool_id IN ('tool@8b22xmimg21000', 'tool@8b22xmaud21000', 'tool@8b22xmvid21000', 'tool@8b22xmweb21000')
ORDER BY tool_id;

SELECT tool_id, name, version
FROM `paiflow-link`.tools_schema
WHERE tool_id IN ('tool@8b22xmimg21000', 'tool@8b22xmaud21000', 'tool@8b22xmvid21000', 'tool@8b22xmweb21000')
ORDER BY tool_id;
