package com.iflytek.astron.workflow.exception;

/**
 * Error codes for workflow engine exceptions.
 * 
 * This enumeration defines all possible error codes and their corresponding
 * messages used throughout the workflow engine.
 */
public enum ErrorCode {
    Success(0, "Success"),
    NODE_RUN_ERROR(1001, "Node run error"),
    WORKFLOW_EXECUTION_ERROR(1002, "Workflow execution error"),
    INVALID_NODE_CONFIGURATION(1003, "Invalid node configuration"),
    MISSING_DEPENDENCY(1004, "Missing dependency"),
    TIMEOUT_ERROR(1005, "Execution timeout"),
    INTERRUPTED_ERROR(1006, "Execution interrupted");
    
    private final int code;
    private final String msg;
    
    ErrorCode(int code, String msg) {
        this.code = code;
        this.msg = msg;
    }
    
    public int getCode() {
        return code;
    }
    
    public String getMsg() {
        return msg;
    }
    
    @Override
    public String toString() {
        return code + ": " + msg;
    }
}