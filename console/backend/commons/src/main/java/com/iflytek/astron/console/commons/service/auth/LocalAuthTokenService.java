package com.iflytek.astron.console.commons.service.auth;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.iflytek.astron.console.commons.entity.user.UserInfo;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class LocalAuthTokenService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String HEADER_JSON = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
    private static final long ACCESS_TOKEN_EXPIRE_SECONDS = 30L * 24 * 60 * 60;

    private final ObjectMapper objectMapper;

    @Value("${local.auth.token-secret:paiflow-local-auth-secret-change-me}")
    private String tokenSecret;

    public String createAccessToken(UserInfo userInfo) {
        try {
            String header = encodeSegment(HEADER_JSON.getBytes(StandardCharsets.UTF_8));
            Map<String, Object> payloadMap = new HashMap<>();
            payloadMap.put("sub", userInfo.getUid());
            payloadMap.put("uid", userInfo.getUid());
            payloadMap.put("username", userInfo.getUsername());
            payloadMap.put("exp", Instant.now().getEpochSecond() + ACCESS_TOKEN_EXPIRE_SECONDS);
            String payload = encodeSegment(objectMapper.writeValueAsBytes(payloadMap));
            String unsignedToken = header + "." + payload;
            return unsignedToken + "." + sign(unsignedToken);
        } catch (Exception e) {
            throw new IllegalStateException("生成本地登录令牌失败", e);
        }
    }

    public LocalTokenPayload parseAccessToken(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                return null;
            }
            String unsignedToken = parts[0] + "." + parts[1];
            String expectedSignature = sign(unsignedToken);
            if (!expectedSignature.equals(parts[2])) {
                return null;
            }
            Map<String, Object> payloadMap = objectMapper.readValue(
                    Base64.getDecoder().decode(parts[1]),
                    new TypeReference<>() {});
            String uid = asString(payloadMap.get("uid"));
            String username = asString(payloadMap.get("username"));
            Long exp = asLong(payloadMap.get("exp"));
            if (uid == null || username == null || exp == null) {
                return null;
            }
            if (Instant.now().getEpochSecond() >= exp) {
                return null;
            }
            return new LocalTokenPayload(uid, username, exp);
        } catch (Exception e) {
            log.warn("解析本地登录令牌失败", e);
            return null;
        }
    }

    private String sign(String unsignedToken) throws Exception {
        Mac mac = Mac.getInstance(HMAC_ALGORITHM);
        mac.init(new SecretKeySpec(tokenSecret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
        return encodeSegment(mac.doFinal(unsignedToken.getBytes(StandardCharsets.UTF_8)));
    }

    private String encodeSegment(byte[] bytes) {
        return Base64.getEncoder().encodeToString(bytes);
    }

    private String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private Long asLong(Object value) {
        if (value instanceof Number number) {
            return number.longValue();
        }
        if (value == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(value));
        } catch (NumberFormatException e) {
            return null;
        }
    }

    public record LocalTokenPayload(String uid, String username, Long exp) {
    }
}
