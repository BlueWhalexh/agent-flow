package com.iflytek.astron.workflow.engine.integration.plugins.tts;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.iflytek.astron.workflow.engine.context.EngineContextHolder;
import com.iflytek.astron.workflow.engine.domain.NodeState;
import com.iflytek.astron.workflow.engine.domain.chain.Node;
import com.iflytek.astron.workflow.engine.util.S3ClientUtil;
import jakarta.annotation.Resource;
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
import java.util.Base64;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Slf4j
@Component
public class XiaomiTTSIntegration implements TtsIntegration {
    private static final MediaType JSON_MEDIA_TYPE = MediaType.parse("application/json; charset=utf-8");

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();

    @Value("${xiaomi.source:xiaomi}")
    private String source;

    @Value("${xiaomi.api-key:}")
    private String apiKey;

    @Value("${xiaomi.model:mimo-v2-tts}")
    private String model;

    @Value("${xiaomi.tts-url:https://api.xiaomimimo.com/v1}")
    private String ttsUrl;

    @Value("${xiaomi.voice:mimo_default}")
    private String defaultVoice;

    @Value("${xiaomi.response-format:mp3}")
    private String responseFormat;

    @Resource
    private S3ClientUtil s3ClientUtil;

    @Override
    public String source() {
        return source;
    }

    @Override
    public Map<String, Object> call(NodeState nodeState, Map<String, Object> inputs) throws Exception {
        Node node = nodeState.node();
        log.info("Executing Xiaomi TTS node: {}", node.getId());

        String text = getString(inputs, "text");
        String vcn = getString(inputs, "vcn");
        Integer speed = getInteger(inputs, "speed", 50);

        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("Text is required");
        }
        if (apiKey == null || apiKey.isBlank()) {
            throw new IllegalStateException("XIAOMI_API_KEY is not configured");
        }

        String voice = resolveVoice(vcn);
        float mappedSpeed = mapSpeed(speed);
        byte[] audioData = synthesize(text, voice, mappedSpeed);

        String normalizedFormat = normalizeResponseFormat(responseFormat);
        String contentType = "mp3".equals(normalizedFormat) ? "audio/mpeg" : "audio/" + normalizedFormat;
        String objectKey = "audio/"
                + LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
                + "/"
                + UUID.randomUUID()
                + "."
                + normalizedFormat;
        String audioUrl = s3ClientUtil.uploadObject(objectKey, contentType, audioData);

        Map<String, Object> outputs = new HashMap<>();
        outputs.put("data", Map.of("voice_url", audioUrl));
        outputs.put("code", 0);
        outputs.put("message", "Success");
        outputs.put("sid", EngineContextHolder.get().getSid());
        return outputs;
    }

    private byte[] synthesize(String text, String voice, float speed) throws Exception {
        JSONObject body = new JSONObject();
        body.put("model", model);
        body.put("messages", buildMessages(text, speed));
        body.put("audio", buildAudioConfig(voice));

        Request request = new Request.Builder()
                .url(buildChatEndpoint(ttsUrl))
                .addHeader("Authorization", "Bearer " + apiKey)
                .addHeader("api-key", apiKey)
                .post(RequestBody.create(JSON.toJSONString(body), JSON_MEDIA_TYPE))
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            ResponseBody responseBody = response.body();
            if (!response.isSuccessful()) {
                String errorBody = responseBody == null ? "" : responseBody.string();
                throw new RuntimeException("Xiaomi TTS request failed: " + response.code() + " " + errorBody);
            }
            if (responseBody == null) {
                throw new RuntimeException("Xiaomi TTS response body is empty");
            }
            String responseText = responseBody.string();
            JSONObject json = JSON.parseObject(responseText);
            String audioBase64 = extractAudioBase64(json);
            if (audioBase64 == null || audioBase64.isBlank()) {
                throw new RuntimeException("Xiaomi TTS response missing choices[0].message.audio.data: " + responseText);
            }
            return Base64.getDecoder().decode(audioBase64);
        }
    }

    private String buildChatEndpoint(String baseUrl) {
        String trimmed = baseUrl == null ? "" : baseUrl.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalStateException("Xiaomi TTS base url is not configured");
        }
        if (trimmed.endsWith("/chat/completions")) {
            return trimmed;
        }
        return trimmed.endsWith("/") ? trimmed + "chat/completions" : trimmed + "/chat/completions";
    }

    private JSONObject buildAudioConfig(String voice) {
        JSONObject audio = new JSONObject();
        audio.put("format", normalizeResponseFormat(responseFormat));
        audio.put("voice", voice);
        return audio;
    }

    private Object[] buildMessages(String text, float speed) {
        String speedStyle = mapSpeedToStyle(speed);
        String assistantContent = speedStyle.isEmpty() ? text : "<style>" + speedStyle + "</style>" + text;

        JSONObject userMessage = new JSONObject();
        userMessage.put("role", "user");
        userMessage.put("content", "Generate speech audio for the provided assistant message.");

        JSONObject assistantMessage = new JSONObject();
        assistantMessage.put("role", "assistant");
        assistantMessage.put("content", assistantContent);

        return new Object[]{userMessage, assistantMessage};
    }

    private String mapSpeedToStyle(float speed) {
        if (speed >= 1.25f) {
            return "变快";
        }
        if (speed <= 0.85f) {
            return "变慢";
        }
        return "";
    }

    private String extractAudioBase64(JSONObject json) {
        if (json == null) {
            return null;
        }
        Object choicesObj = json.get("choices");
        if (!(choicesObj instanceof com.alibaba.fastjson2.JSONArray choices) || choices.isEmpty()) {
            return null;
        }
        Object firstChoiceObj = choices.get(0);
        if (!(firstChoiceObj instanceof JSONObject firstChoice)) {
            return null;
        }
        JSONObject message = firstChoice.getJSONObject("message");
        if (message == null) {
            return null;
        }
        JSONObject audio = message.getJSONObject("audio");
        if (audio == null) {
            return null;
        }
        return audio.getString("data");
    }

    private String resolveVoice(String vcn) {
        if (vcn == null || vcn.isBlank()) {
            return defaultVoice;
        }
        String normalized = vcn.trim();
        if (normalized.startsWith("x5_") || normalized.startsWith("x6_")) {
            return defaultVoice;
        }
        return normalized;
    }

    private String normalizeResponseFormat(String format) {
        if (format == null || format.isBlank()) {
            return "mp3";
        }
        return format.trim().toLowerCase(Locale.ROOT);
    }

    private float mapSpeed(Integer speed) {
        int safeSpeed = speed == null ? 50 : Math.max(0, Math.min(100, speed));
        return 0.5f + (safeSpeed / 100.0f) * 1.5f;
    }

    private String getString(Map<String, Object> map, String key) {
        if (map == null || key == null) {
            return null;
        }
        Object value = map.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private Integer getInteger(Map<String, Object> map, String key, Integer defaultValue) {
        if (map == null || key == null) {
            return defaultValue;
        }
        Object value = map.get(key);
        if (value == null) {
            return defaultValue;
        }
        if (value instanceof Integer integer) {
            return integer;
        }
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String str) {
            try {
                return Integer.parseInt(str);
            } catch (NumberFormatException ignore) {
                return defaultValue;
            }
        }
        return defaultValue;
    }
}
