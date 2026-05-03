package com.iflytek.astron.console.hub.service.auth;

import com.iflytek.astron.console.commons.data.UserInfoDataService;
import com.iflytek.astron.console.commons.entity.user.UserInfo;
import com.iflytek.astron.console.commons.enums.space.EnterpriseServiceTypeEnum;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Component
@RequiredArgsConstructor
public class LocalAuthBootstrapService implements ApplicationRunner {

    private final UserInfoDataService userInfoDataService;
    private final PasswordHashService passwordHashService;

    @Value("${local.auth.bootstrap.username:admin}")
    private String bootstrapUsername;

    @Value("${local.auth.bootstrap.password:ChangeMe123!}")
    private String bootstrapPassword;

    @Override
    public void run(ApplicationArguments args) {
        if (StringUtils.isBlank(bootstrapUsername) || StringUtils.isBlank(bootstrapPassword)) {
            log.warn("Local auth bootstrap skipped because username or password is blank.");
            return;
        }

        Optional<UserInfo> userInfoOpt = userInfoDataService.findByUsername(bootstrapUsername);
        if (userInfoOpt.isPresent()) {
            UserInfo existingUser = userInfoOpt.get();
            if (StringUtils.isBlank(existingUser.getPasswordHash())) {
                userInfoDataService.updateUserPasswordHash(existingUser.getUid(), passwordHashService.hash(bootstrapPassword));
                log.warn("Bootstrapped password hash for local account [{}]. Change this password after first login.", bootstrapUsername);
            }
            return;
        }

        UserInfo bootstrapUser = new UserInfo();
        bootstrapUser.setUid(bootstrapUsername);
        bootstrapUser.setUsername(bootstrapUsername);
        bootstrapUser.setNickname(bootstrapUsername);
        bootstrapUser.setAccountStatus(1);
        bootstrapUser.setEnterpriseServiceType(EnterpriseServiceTypeEnum.NONE);
        bootstrapUser.setUserAgreement(0);
        bootstrapUser.setDeleted(0);
        bootstrapUser.setCreateTime(LocalDateTime.now());
        bootstrapUser.setUpdateTime(LocalDateTime.now());
        bootstrapUser.setPasswordHash(passwordHashService.hash(bootstrapPassword));
        userInfoDataService.createOrGetUser(bootstrapUser);
        log.warn("Created bootstrap local account [{}]. Change this password after first login.", bootstrapUsername);
    }
}
