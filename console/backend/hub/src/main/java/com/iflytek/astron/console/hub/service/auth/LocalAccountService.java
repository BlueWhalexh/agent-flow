package com.iflytek.astron.console.hub.service.auth;

import com.iflytek.astron.console.commons.constant.ResponseEnum;
import com.iflytek.astron.console.commons.data.UserInfoDataService;
import com.iflytek.astron.console.commons.entity.user.UserInfo;
import com.iflytek.astron.console.commons.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class LocalAccountService {

    private final UserInfoDataService userInfoDataService;
    private final PasswordHashService passwordHashService;

    @Value("${local.auth.bootstrap-username:admin}")
    private String bootstrapUsername;

    @Value("${local.auth.bootstrap-password:}")
    private String bootstrapPassword;

    public UserInfo authenticate(String username, String password) {
        UserInfo userInfo = userInfoDataService.findByUsername(username)
                .orElseThrow(this::loginFailed);
        if (StringUtils.isBlank(userInfo.getPasswordHash())) {
            if (!canUpgradeFromBootstrapPassword(userInfo, password)) {
                throw loginFailed();
            }
            String upgradedHash = passwordHashService.hash(password);
            boolean updated = userInfoDataService.updateUserPasswordHash(userInfo.getUid(), upgradedHash);
            if (!updated) {
                throw new BusinessException(ResponseEnum.OPERATION_FAILED, "密码初始化失败");
            }
            userInfo.setPasswordHash(upgradedHash);
        }
        if (!passwordHashService.matches(password, userInfo.getPasswordHash())) {
            throw loginFailed();
        }
        return userInfo;
    }

    public void changeCurrentUserPassword(String oldPassword, String newPassword, String confirmPassword) {
        if (!StringUtils.equals(newPassword, confirmPassword)) {
            throw new BusinessException(ResponseEnum.PARAMETER_ERROR, "两次输入的新密码不一致");
        }
        UserInfo currentUser = userInfoDataService.getCurrentUserInfo();
        if (!passwordHashService.matches(oldPassword, currentUser.getPasswordHash())) {
            throw new BusinessException(ResponseEnum.PARAMETER_ERROR, "原密码错误");
        }
        if (passwordHashService.matches(newPassword, currentUser.getPasswordHash())) {
            throw new BusinessException(ResponseEnum.PARAMETER_ERROR, "新密码不能与原密码相同");
        }
        boolean updated = userInfoDataService.updateCurrentUserPasswordHash(passwordHashService.hash(newPassword));
        if (!updated) {
            throw new BusinessException(ResponseEnum.OPERATION_FAILED, "密码修改失败");
        }
    }

    private BusinessException loginFailed() {
        return new BusinessException(ResponseEnum.UNAUTHORIZED, "用户名或密码错误");
    }

    private boolean canUpgradeFromBootstrapPassword(UserInfo userInfo, String password) {
        return StringUtils.isNotBlank(bootstrapPassword)
                && StringUtils.equals(userInfo.getUsername(), bootstrapUsername)
                && StringUtils.equals(password, bootstrapPassword);
    }
}
