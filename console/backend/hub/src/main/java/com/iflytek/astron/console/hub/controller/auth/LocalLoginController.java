package com.iflytek.astron.console.hub.controller.auth;

import com.iflytek.astron.console.commons.entity.user.UserInfo;
import com.iflytek.astron.console.commons.service.auth.LocalAuthTokenService;
import com.iflytek.astron.console.hub.dto.auth.ChangePasswordRequest;
import com.iflytek.astron.console.hub.dto.auth.LoginRequest;
import com.iflytek.astron.console.hub.service.auth.LocalAccountService;
import com.iflytek.astron.console.toolkit.common.Result;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class LocalLoginController {

    private final LocalAccountService localAccountService;
    private final LocalAuthTokenService localAuthTokenService;

    @PostMapping("/login")
    public Result<Map<String, String>> login(@Valid @RequestBody LoginRequest request) {
        try {
            log.info("登录请求: username={}", request.username());
            UserInfo userInfo = localAccountService.authenticate(request.username(), request.password());

            Map<String, String> result = new HashMap<>();
            result.put("accessToken", localAuthTokenService.createAccessToken(userInfo));
            log.info("登录成功: username={}", request.username());
            return Result.success(result);
        } catch (Exception e) {
            log.warn("登录失败: username={}, reason={}", request.username(), e.getMessage());
            return Result.failure(40001, e.getMessage());
        }
    }

    @PostMapping("/auth/change-password")
    public Result<Boolean> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        try {
            localAccountService.changeCurrentUserPassword(
                    request.oldPassword(),
                    request.newPassword(),
                    request.confirmPassword());
            return Result.success(Boolean.TRUE);
        } catch (Exception e) {
            return Result.failure(e.getMessage());
        }
    }
}
