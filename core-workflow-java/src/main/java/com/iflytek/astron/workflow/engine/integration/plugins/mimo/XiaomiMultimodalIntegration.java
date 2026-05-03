package com.iflytek.astron.workflow.engine.integration.plugins.mimo;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.iflytek.astron.workflow.engine.context.EngineContextHolder;
import com.iflytek.astron.workflow.engine.domain.NodeState;
import com.iflytek.astron.workflow.engine.domain.chain.Node;
import lombok.extern.slf4j.Slf4j;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Slf4j
@Component
public class XiaomiMultimodalIntegration {
    private static final MediaType JSON_MEDIA_TYPE = MediaType.parse("application/json; charset=utf-8");

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(120, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();

    @Value("${xiaomi.api-key:}")
    private String apiKey;

    @Value("${xiaomi.multimodal-model:mimo-v2.5}")
    private String multimodalModel;

    @Value("${xiaomi.web-search-model:mimo-v2.5-pro}")
    private String webSearchModel;

    @Value("${xiaomi.multimodal-url:https://api.xiaomimimo.com/v1}")
    private String multimodalUrl;

    @Value("${xiaomi.multimodal-max-tokens:1024}")
    private Integer maxTokens;

    public Map<String, Object> call(NodeState nodeState, Map<String, Object> inputs, XiaomiMultimodalMode mode) throws Exception {
        Node node = nodeState.node();
        log.info("Executing Xiaomi MiMo tool node: {}, mode: {}", node.getId(), mode);

        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("XIAOMI_API_KEY is not configured");
        }

        JSONObject response = request(inputs == null ? new HashMap<>() : inputs, mode);
        String content = extractContent(response);
        String reasoningContent = extractReasoningContent(response);
        JSONArray annotations = extractAnnotations(response);

        Map<String, Object> data = new HashMap<>();
        data.put("content", content);
        data.put("answer", content);
        if (reasoningContent != null && !reasoningContent.isBlank()) {
            data.put("reasoning_content", reasoningContent);
        }
        if (annotations != null && !annotations.isEmpty()) {
            data.put("annotations", annotations);
        }

        Map<String, Object> outputs = new HashMap<>();
        outputs.put("data", data);
        outputs.put("code", 0);
        outputs.put("message", "Success");
        outputs.put("sid", EngineContextHolder.get().getSid());
        return outputs;
    }

    private JSONObject request(Map<String, Object> inputs, XiaomiMultimodalMode mode) throws Exception {
        JSONObject body = new JSONObject();
        body.put("model", mode == XiaomiMultimodalMode.WEB_SEARCH ? webSearchModel : multimodalModel);
        body.put("messages", buildMessages(inputs, mode));
        body.put("max_completion_tokens", maxTokens == null ? 1024 : maxTokens);

        if (mode == XiaomiMultimodalMode.WEB_SEARCH) {
            body.put("tools", buildWebSearchTools(inputs));
            body.put("tool_choice", "auto");
            body.put("stream", false);
            body.put("thinking", Map.of("type", "disabled"));
        }

        Request request = new Request.Builder()
                .url(buildChatEndpoint(multimodalUrl))
                .addHeader("Authorization", "Bearer " + apiKey)
                .addHeader("api-key", apiKey)
                .post(RequestBody.create(JSON.toJSONString(body), JSON_MEDIA_TYPE))
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            ResponseBody responseBody = response.body();
            String responseText = responseBody == null ? "" : responseBody.string();
            if (!response.isSuccessful()) {
                throw new RuntimeException("Xiaomi MiMo request failed: " + response.code() + " " + responseText);
            }
            if (responseText.isBlank()) {
                throw new RuntimeException("Xiaomi MiMo response body is empty");
            }
            return JSON.parseObject(responseText);
        }
    }

    private Object[] buildMessages(Map<String, Object> inputs, XiaomiMultimodalMode mode) {
        JSONObject systemMessage = new JSONObject();
        systemMessage.put("role", "system");
        systemMessage.put("content", "You are MiMo, an AI assistant developed by Xiaomi. Today is date: "
                + LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
                + ".");

        JSONObject userMessage = new JSONObject();
        userMessage.put("role", "user");
        if (mode == XiaomiMultimodalMode.WEB_SEARCH) {
            userMessage.put("content", resolveWebSearchPrompt(inputs));
        } else {
            userMessage.put("content", buildMultimodalContent(inputs, mode));
        }
        return new Object[]{systemMessage, userMessage};
    }

    private JSONArray buildMultimodalContent(Map<String, Object> inputs, XiaomiMultimodalMode mode) {
        JSONArray content = new JSONArray();
        JSONObject media = new JSONObject();
        String prompt;

        if (mode == XiaomiMultimodalMode.IMAGE) {
            media.put("type", "image_url");
            media.put("image_url", Map.of("url", normalizeMediaData(
                    requireAnyString(inputs, "image_url", "image", "url"),
                    defaultIfBlank(getString(inputs, "image_mime_type", "mime_type"), "image/png")
            )));
            prompt = getString(inputs, "prompt", "question", "text");
            content.add(media);
            content.add(textContent(defaultIfBlank(prompt, "please describe the content of the image")));
            return content;
        }

        if (mode == XiaomiMultimodalMode.AUDIO) {
            media.put("type", "input_audio");
            media.put("input_audio", Map.of("data", normalizeMediaData(
                    requireAnyString(inputs, "audio_url", "audio", "url"),
                    defaultIfBlank(getString(inputs, "audio_mime_type", "mime_type"), "audio/wav")
            )));
            prompt = getString(inputs, "prompt", "question", "text");
            content.add(media);
            content.add(textContent(defaultIfBlank(prompt, "please describe the content of the audio")));
            return content;
        }

        media.put("type", "video_url");
        media.put("video_url", Map.of("url", normalizeMediaData(
                requireAnyString(inputs, "video_url", "video", "url"),
                defaultIfBlank(getString(inputs, "video_mime_type", "mime_type"), "video/mp4")
        )));
        media.put("fps", getInteger(inputs, "fps", 2));
        media.put("media_resolution", defaultIfBlank(getString(inputs, "media_resolution"), "default"));
        content.add(media);
        prompt = getString(inputs, "prompt", "question", "text");
        content.add(textContent(defaultIfBlank(prompt, "please describe the content of the video")));
        return content;
    }

    private JSONArray buildWebSearchTools(Map<String, Object> inputs) {
        JSONArray tools = new JSONArray();
        JSONObject webSearch = new JSONObject();
        webSearch.put("type", "web_search");
        webSearch.put("max_keyword", getInteger(inputs, "max_keyword", 3));
        webSearch.put("force_search", getBoolean(inputs, "force_search", true));
        webSearch.put("limit", getInteger(inputs, "limit", 3));

        String country = getString(inputs, "country");
        String region = getString(inputs, "region");
        String city = getString(inputs, "city");
        if (!isBlank(country) || !isBlank(region) || !isBlank(city)) {
            JSONObject location = new JSONObject();
            location.put("type", "approximate");
            if (!isBlank(country)) {
                location.put("country", country);
            }
            if (!isBlank(region)) {
                location.put("region", region);
            }
            if (!isBlank(city)) {
                location.put("city", city);
            }
            webSearch.put("user_location", location);
        }

        tools.add(webSearch);
        return tools;
    }

    private JSONObject textContent(String text) {
        JSONObject textContent = new JSONObject();
        textContent.put("type", "text");
        textContent.put("text", text);
        return textContent;
    }

    private String resolveWebSearchPrompt(Map<String, Object> inputs) {
        String query = getString(inputs, "query", "prompt", "question", "text");
        if (query == null || query.isBlank()) {
            throw new IllegalArgumentException("query is required");
        }
        return query;
    }

    private String buildChatEndpoint(String baseUrl) {
        String trimmed = baseUrl == null ? "" : baseUrl.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalStateException("Xiaomi MiMo base url is not configured");
        }
        if (trimmed.endsWith("/chat/completions")) {
            return trimmed;
        }
        return trimmed.endsWith("/") ? trimmed + "chat/completions" : trimmed + "/chat/completions";
    }

    private String extractContent(JSONObject json) {
        JSONObject message = extractMessage(json);
        return message == null ? "" : defaultIfBlank(message.getString("content"), "");
    }

    private String extractReasoningContent(JSONObject json) {
        JSONObject message = extractMessage(json);
        return message == null ? null : message.getString("reasoning_content");
    }

    private JSONArray extractAnnotations(JSONObject json) {
        JSONObject message = extractMessage(json);
        return message == null ? null : message.getJSONArray("annotations");
    }

    private JSONObject extractMessage(JSONObject json) {
        if (json == null) {
            return null;
        }
        JSONArray choices = json.getJSONArray("choices");
        if (choices == null || choices.isEmpty()) {
            return null;
        }
        JSONObject firstChoice = choices.getJSONObject(0);
        return firstChoice == null ? null : firstChoice.getJSONObject("message");
    }

    private String requireAnyString(Map<String, Object> inputs, String... keys) {
        String value = getString(inputs, keys);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(String.join("/", keys) + " is required");
        }
        return value;
    }

    private String normalizeMediaData(String value, String defaultMimeType) {
        String trimmed = value == null ? "" : value.trim();
        if (trimmed.startsWith("http://") || trimmed.startsWith("https://") || trimmed.startsWith("data:")) {
            return trimmed;
        }
        return "data:" + defaultMimeType + ";base64," + trimmed;
    }

    private String getString(Map<String, Object> inputs, String... keys) {
        if (inputs == null || keys == null) {
            return null;
        }
        for (String key : keys) {
            Object value = inputs.get(key);
            if (value != null) {
                return String.valueOf(value);
            }
        }
        return null;
    }

    private Integer getInteger(Map<String, Object> inputs, String key, Integer defaultValue) {
        if (inputs == null || key == null) {
            return defaultValue;
        }
        Object value = inputs.get(key);
        if (value == null) {
            return defaultValue;
        }
        if (value instanceof Number number) {
            return number.intValue();
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private Boolean getBoolean(Map<String, Object> inputs, String key, Boolean defaultValue) {
        if (inputs == null || key == null) {
            return defaultValue;
        }
        Object value = inputs.get(key);
        if (value == null) {
            return defaultValue;
        }
        if (value instanceof Boolean bool) {
            return bool;
        }
        String text = String.valueOf(value).toLowerCase(Locale.ROOT);
        if ("true".equals(text) || "1".equals(text) || "yes".equals(text)) {
            return true;
        }
        if ("false".equals(text) || "0".equals(text) || "no".equals(text)) {
            return false;
        }
        return defaultValue;
    }

    private String defaultIfBlank(String value, String defaultValue) {
        return value == null || value.isBlank() ? defaultValue : value;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
