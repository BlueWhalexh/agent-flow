package com.iflytek.astron.console.hub.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
        @NotBlank(message = "old password is required")
        String oldPassword,
        @NotBlank(message = "new password is required")
        @Size(min = 6, max = 64, message = "new password length must be between 6 and 64")
        String newPassword,
        @NotBlank(message = "confirm password is required")
        String confirmPassword
) {
}
