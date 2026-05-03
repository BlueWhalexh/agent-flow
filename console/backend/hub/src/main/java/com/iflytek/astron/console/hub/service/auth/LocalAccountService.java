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
                throw new BusinessException(ResponseEnum.OPERATION_FAILED, "bootstrap password upgrade failed");
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
            throw new BusinessException(ResponseEnum.PARAMETER_ERROR, "new passwords do not match");
        }
        UserInfo currentUser = userInfoDataService.getCurrentUserInfo();
        if (!passwordHashService.matches(oldPassword, currentUser.getPasswordHash())) {
            throw new BusinessException(ResponseEnum.PARAMETER_ERROR, "old password is incorrect");
        }
        if (passwordHashService.matches(newPassword, currentUser.getPasswordHash())) {
            throw new BusinessException(ResponseEnum.PARAMETER_ERROR, "new password must be different");
        }
        boolean updated = userInfoDataService.updateCurrentUserPasswordHash(passwordHashService.hash(newPassword));
        if (!updated) {
            throw new BusinessException(ResponseEnum.OPERATION_FAILED, "password update failed");
        }
    }

    private BusinessException loginFailed() {
        return new BusinessException(ResponseEnum.UNAUTHORIZED, "username or password is incorrect");
    }

    private boolean canUpgradeFromBootstrapPassword(UserInfo userInfo, String password) {
        return StringUtils.isNotBlank(bootstrapPassword)
                && StringUtils.equals(userInfo.getUsername(), bootstrapUsername)
                && StringUtils.equals(password, bootstrapPassword);
    }
}
