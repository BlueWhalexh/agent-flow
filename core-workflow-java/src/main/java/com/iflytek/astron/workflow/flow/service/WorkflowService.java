package com.iflytek.astron.workflow.flow.service;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.iflytek.astron.workflow.engine.domain.WorkflowDSL;
import com.iflytek.astron.workflow.flow.entity.WorkflowEntity;
import com.iflytek.astron.workflow.flow.mapper.WorkflowMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Workflow service
 * Handles workflow storage and retrieval
 */
@Slf4j
@Service
public class WorkflowService {
    private final WorkflowMapper workflowMapper;

    public WorkflowService(WorkflowMapper workflowMapper) {
        this.workflowMapper = workflowMapper;
    }

    /**
     * Get workflow DSL by workflow ID
     *
     * @param workflowId workflow ID (e.g., "184736")
     * @return workflow DSL
     */
    public WorkflowDSL getWorkflowDSL(String workflowId) {
        if (log.isDebugEnabled()) {
            log.debug("Loading workflow: {}", workflowId);
        }

        LambdaQueryWrapper<WorkflowEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(WorkflowEntity::getId, workflowId);

        WorkflowEntity entity = workflowMapper.selectOne(queryWrapper);

        if (entity == null) {
            throw new IllegalArgumentException("Workflow not found: " + workflowId);
        }

        String dslData = JSONObject.parse(entity.getData()).getString("data");
        WorkflowDSL dsl = JSON.parseObject(dslData, WorkflowDSL.class);
        dsl.setFlowId(workflowId);

        if (log.isDebugEnabled()) {
            log.info("Loaded workflow: id={}, nodes={}, edges={}",
                    workflowId, dsl.getNodes().size(), dsl.getEdges().size());
        }
        return dsl;
    }
}
