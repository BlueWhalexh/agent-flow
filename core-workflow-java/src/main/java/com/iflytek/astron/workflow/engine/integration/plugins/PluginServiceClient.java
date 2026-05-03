package com.iflytek.astron.workflow.engine.integration.plugins;

import com.iflytek.astron.workflow.engine.domain.NodeState;
import com.iflytek.astron.workflow.engine.domain.chain.Node;
import com.iflytek.astron.workflow.engine.integration.plugins.aitools.AiToolsIntegration;
import com.iflytek.astron.workflow.engine.integration.plugins.mimo.XiaomiMultimodalIntegration;
import com.iflytek.astron.workflow.engine.integration.plugins.mimo.XiaomiMultimodalMode;
import com.iflytek.astron.workflow.engine.integration.plugins.tts.TtsIntegration;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * @author YiHui
 * @date 2025/12/4
 */
@Slf4j
@Service
public class PluginServiceClient {
    private static final Set<String> TTS_TOOL_IDS = Set.of(
            "tool@8b2262bef821000",
            "tool@8b22xmtts21000"
    );
    private static final Map<String, XiaomiMultimodalMode> XIAOMI_MULTIMODAL_TOOL_IDS = Map.of(
            "tool@8b22xmimg21000", XiaomiMultimodalMode.IMAGE,
            "tool@8b22xmaud21000", XiaomiMultimodalMode.AUDIO,
            "tool@8b22xmvid21000", XiaomiMultimodalMode.VIDEO,
            "tool@8b22xmweb21000", XiaomiMultimodalMode.WEB_SEARCH
    );

    @Autowired
    private AiToolsIntegration aiToolsIntegration;
    @Autowired
    private List<TtsIntegration> smartTTSIntegration;
    @Autowired
    private XiaomiMultimodalIntegration xiaomiMultimodalIntegration;

    @Value("${tts.source:qwen}")
    private String ttsSource;

    public Map<String, Object> toolCall(NodeState nodeState, Map<String, Object> inputs) throws Exception {
        Node node = nodeState.node();
        Map<String, Object> output;
        String pluginId = String.valueOf(node.getData().getNodeParam().get("pluginId"));
        XiaomiMultimodalMode xiaomiMultimodalMode = XIAOMI_MULTIMODAL_TOOL_IDS.get(pluginId);
        if (xiaomiMultimodalMode != null) {
            output = xiaomiMultimodalIntegration.call(nodeState, inputs, xiaomiMultimodalMode);
        } else if (TTS_TOOL_IDS.contains(pluginId)) {
            output = getTtsIntegration().call(nodeState, inputs);
        } else {
            output = aiToolsIntegration.call(nodeState, inputs);
        }

        return output;
    }

    public TtsIntegration getTtsIntegration() {
        for (TtsIntegration ttsIntegration : smartTTSIntegration) {
            if (Objects.equals(ttsIntegration.source(), ttsSource)) {
                return ttsIntegration;
            }
        }
        throw new RuntimeException("TTS source not found");
    }
}
