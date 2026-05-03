package com.iflytek.astron.console.hub.controller.user;

import com.iflytek.astron.console.commons.data.UserInfoDataService;
import com.iflytek.astron.console.commons.entity.user.UserInfo;
import com.iflytek.astron.console.commons.response.ApiResult;
import com.iflytek.astron.console.hub.dto.auth.ChangePasswordRequest;
import com.iflytek.astron.console.hub.dto.user.UpdateUserBasicInfoRequest;
import com.iflytek.astron.console.hub.service.auth.LocalAccountService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/user-info")
@Tag(name = "User Information")
@Slf4j
@RequiredArgsConstructor
public class UserInfoController {

    private final UserInfoDataService userInfoDataService;
    private final LocalAccountService localAccountService;

    @GetMapping("/me")
    @Operation(summary = "Get current user information")
    public ApiResult<UserInfo> getCurrentUserInfo() {
        UserInfo userInfo = userInfoDataService.getCurrentUserInfo();
        log.debug("Successfully retrieved current user information: uid={}", userInfo.getUid());
        return ApiResult.success(userInfo);
    }

    @PostMapping("/update")
    @Operation(summary = "Update current user basic information (nickname, avatar)")
    public ApiResult<UserInfo> updateCurrentUserBasicInfo(@Valid @RequestBody UpdateUserBasicInfoRequest request) {
        if (!StringUtils.hasText(request.nickname()) && !StringUtils.hasText(request.avatar())) {
            return ApiResult.success(userInfoDataService.getCurrentUserInfo());
        }
        UserInfo updated = userInfoDataService.updateCurrentUserBasicInfo(request.nickname(), request.avatar());
        return ApiResult.success(updated);
    }

    @PostMapping("/agreement")
    @Operation(summary = "Current user agrees to user agreement")
    public ApiResult<Boolean> agreeUserAgreement() {
        return ApiResult.success(userInfoDataService.agreeUserAgreement());
    }

    @PostMapping("/change-password")
    @Operation(summary = "Current user changes password")
    public ApiResult<Boolean> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        localAccountService.changeCurrentUserPassword(
                request.oldPassword(),
                request.newPassword(),
                request.confirmPassword());
        return ApiResult.success(Boolean.TRUE);
    }
}
