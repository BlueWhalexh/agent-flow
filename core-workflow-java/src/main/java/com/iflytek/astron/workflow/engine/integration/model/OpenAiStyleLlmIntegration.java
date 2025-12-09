package com.iflytek.astron.workflow.engine.integration.model;

import com.iflytek.astron.workflow.engine.constants.MsgTypeEnum;
import com.iflytek.astron.workflow.engine.integration.model.bo.LlmCallback;
import com.iflytek.astron.workflow.engine.integration.model.bo.LlmReqBo;
import com.iflytek.astron.workflow.engine.integration.model.bo.LlmResVo;
import io.micrometer.common.util.StringUtils;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.metadata.EmptyUsage;
import org.springframework.ai.chat.metadata.Usage;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.List;

/**
 * 基于OpenAI接口风格的LLM 交互集成
 * - 如讯飞：https://spark-api-open.xf-yun.com/v1/chat/completions
 * - 如智谱：https://open.bigmodel.cn/api/paas/v4/
 *
 * @author YiHui
 * @date 2025/12/1
 */
@Slf4j
@Component
public class OpenAiStyleLlmIntegration {
    // 使用正则表达式分别提取域名和路径部分
    final static java.util.regex.Pattern PATTERN = java.util.regex.Pattern.compile("^(https?://[^/]+)(/.*)?$");

    private OpenAiApi initClient(String key, String apiUrl) {
        java.util.regex.Matcher matcher = PATTERN.matcher(apiUrl);

        String baseUrl;
        String basePath = null;

        if (matcher.matches()) {
            baseUrl = matcher.group(1);  // 域名部分
            basePath = matcher.group(2);           // 路径部分（可能为null）
        } else {
            // 如果不匹配，默认使用原baseUrl
            baseUrl = apiUrl;
        }

        OpenAiApi.Builder builder = OpenAiApi.builder().apiKey(key).baseUrl(baseUrl);
        if (StringUtils.isNotBlank(basePath)) {
            builder.completionsPath(basePath);
        }

        log.info("OpenAI Style API URL: {} - {}", baseUrl, basePath);
        return builder.build();
    }

    public LlmResVo call(LlmReqBo req, LlmCallback callback) {
        OpenAiApi openAiApi = initClient(req.getApiKey(), req.getUrl());
        OpenAiChatOptions.Builder optionBuilder = OpenAiChatOptions.builder().model(req.getModel()).streamUsage(true);
        if (req.getMaxTokens() != null) {
            optionBuilder.maxTokens(req.getMaxTokens());
        }

        OpenAiChatModel chatModel = OpenAiChatModel.builder().openAiApi(openAiApi).defaultOptions(optionBuilder.build()).build();

        // 构建聊天历史
        List<Message> msgList = new ArrayList<>();
        if (StringUtils.isNotBlank(req.getSystemMsg())) {
            msgList.add(new SystemMessage(req.getSystemMsg()));
        }
        if (!CollectionUtils.isEmpty(req.getHistory())) {
            // 访问历史非空，构建对话历史
            for (LlmChatHistory.ChatItem item : req.getHistory()) {
                for (LlmChatHistory.ChatMessage message : item.userInputs()) {
                    if (message.role() == MsgTypeEnum.SYSTEM) {
                        // 说明：构建LLM对话历史时，不保留原有的系统消息，避免和现在使用的系统消息冲突
                        continue;
                    } else {
                        msgList.add(new UserMessage(message.content()));
                    }
                }
                if (!CollectionUtils.isEmpty(item.llmResponses())) {
                    msgList.add(new AssistantMessage(item.llmResponses().get(0).content()));
                }
            }
        }
        msgList.add(new UserMessage(req.getUserMsg()));
        Prompt prompt = new Prompt(msgList);

        // 流式请求
        // todo 需要处理支持推理过程的模型中，推理结果的返回
        Flux<ChatResponse> flux = chatModel.stream(prompt);
        StringBuilder response = new StringBuilder();
        try {
            // 在每个响应到达时进行处理
            ChatResponse lastResponse = flux.doOnNext(chatResponse -> {
                if (!CollectionUtils.isEmpty(chatResponse.getResults())) {
                    String text = chatResponse.getResults().get(0).getOutput().getText();
                    if (!StringUtils.isBlank(text)) {
                        response.append(text);
                        callback.onResponse(chatResponse);
                    }
                }
            }).blockLast(); // 阻塞等待最后一个响应

            Usage tokenUsage = lastResponse != null ? lastResponse.getMetadata().getUsage() : new EmptyUsage();
            return new LlmResVo(tokenUsage, response.toString(), "");
        } catch (Exception e) {
            log.error("Error calling OpenAI API", e);
            throw new RuntimeException("Failed to call OpenAI API", e);
        }
    }
}