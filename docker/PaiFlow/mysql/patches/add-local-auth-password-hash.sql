ALTER TABLE user_info
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(512) NULL COMMENT 'Password hash' AFTER mobile;
