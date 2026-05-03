package com.iflytek.astron.console.hub.controller.user;

import com.iflytek.astron.console.commons.data.UserInfoDataService;
import com.iflytek.astron.console.commons.entity.user.UserInfo;
import com.iflytek.astron.console.hub.dto.auth.ChangePasswordRequest;
import com.iflytek.astron.console.hub.dto.user.UpdateUserBasicInfoRequest;
import com.iflytek.astron.console.hub.service.auth.LocalAccountService;
import com.iflytek.astron.console.toolkit.common.Result;
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
@Tag(name = "用户信息")
@Slf4j
@RequiredArgsConstructor
public class UserInfoController {

    private final UserInfoDataService userInfoDataService;
    private final LocalAccountService localAccountService;

    @GetMapping("/me")
    @Operation(summary = "获取当前用户信息")
    public Result<UserInfo> getCurrentUserInfo() {
        UserInfo userInfo = userInfoDataService.getCurrentUserInfo();
        log.debug("获取当前用户信息成功: uid={}", userInfo.getUid());
        return Result.success(userInfo);
    }

    @PostMapping("/update")
    @Operation(summary = "更新当前用户基本信息（昵称、头像）")
    public Result<UserInfo> updateCurrentUserBasicInfo(@Valid @RequestBody UpdateUserBasicInfoRequest request) {
        if (!StringUtils.hasText(request.nickname()) && !StringUtils.hasText(request.avatar())) {
            return Result.success(userInfoDataService.getCurrentUserInfo());
        }
        UserInfo updated = userInfoDataService.updateCurrentUserBasicInfo(request.nickname(), request.avatar());
        return Result.success(updated);
    }

    @PostMapping("/agreement")
    @Operation(summary = "当前用户同意用户协议")
    public Result<Boolean> agreeUserAgreement() {
        return Result.success(userInfoDataService.agreeUserAgreement());
    }

    @PostMapping("/change-password")
    @Operation(summary = "当前用户修改密码")
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
