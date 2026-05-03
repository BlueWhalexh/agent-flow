package com.iflytek.astron.console.hub.dto.auth;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "username is required")
        String username,
        @NotBlank(message = "password is required")
        String password
) {
}
