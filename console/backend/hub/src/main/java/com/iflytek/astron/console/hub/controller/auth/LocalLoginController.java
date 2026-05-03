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
        log.info("Local login attempt: username={}", request.username());
        UserInfo userInfo = localAccountService.authenticate(request.username(), request.password());

        Map<String, String> result = new HashMap<>();
        result.put("accessToken", localAuthTokenService.createAccessToken(userInfo));
        log.info("Local login successful for user: {}", request.username());
        return Result.success(result);
    }

    @PostMapping("/auth/change-password")
    public Result<Boolean> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        localAccountService.changeCurrentUserPassword(
                request.oldPassword(),
                request.newPassword(),
                request.confirmPassword());
        return Result.success(Boolean.TRUE);
    }
}
