package com.iflytek.astron.console.hub.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
        @NotBlank(message = "请输入原密码")
        String oldPassword,
        @NotBlank(message = "请输入新密码")
        @Size(min = 6, max = 64, message = "密码长度需在6-64位之间")
        String newPassword,
        @NotBlank(message = "请输入确认密码")
        String confirmPassword
) {
}
