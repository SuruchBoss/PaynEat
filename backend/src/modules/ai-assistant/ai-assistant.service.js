import { z } from 'zod';
import { ApiError } from '../../core/ApiError.js';
import { env } from '../../config/env.js';
import { getAnthropicClient } from './ai-assistant.llm-client.js';
import { getToolDefinitionsForRole, getToolHandler } from './ai-assistant.tools.js';
import { aiAssistantRepository } from './ai-assistant.repository.js';

// จำกัดจำนวนรอบเรียก tool สูงสุด — กันโมเดลวนเรียกไม่จบซึ่งทั้งเสียเงินจริงต่อ token และทำให้ผู้ใช้
// รอนาน รอบสุดท้ายบังคับให้เรียก submit_answer เพื่อให้จบลูปเสมอ (ดู tool_choice ด้านล่าง)
const MAX_ROUNDS = 6;

const SUBMIT_ANSWER_TOOL = {
  name: 'submit_answer',
  description:
    'ส่งคำตอบสุดท้ายให้ผู้ใช้ — เรียกได้เมื่อรวบรวมข้อมูลจริงจากเครื่องมืออื่นเพียงพอที่จะตอบแล้ว ' +
    'เท่านั้น ห้ามเรียกก่อนตรวจสอบข้อมูลจริงถ้าคำถามเกี่ยวกับตัวเลข',
  input_schema: {
    type: 'object',
    properties: {
      answerText: {
        type: 'string',
        description:
          'คำตอบที่จะแสดงให้ผู้ใช้ ตอบภาษาเดียวกับคำถาม ต้องระบุช่วงเวลาของข้อมูลที่ใช้เสมอ ' +
          '(เช่น "จากข้อมูล 1-15 ก.ย. 2569") ถ้าไม่มีข้อมูลรองรับให้บอกตรงๆ ว่าไม่มี ห้ามเดา/แต่งตัวเลข',
      },
      chart: {
        type: 'object',
        description:
          'กราฟประกอบ — ใส่เฉพาะเมื่อคำถามเกี่ยวกับตัวเลขที่ plot เทียบกันได้ เช่น ยอดขายรายวัน/' +
          'เมนูขายดี ไม่ต้องใส่ถ้าคำตอบเป็นข้อความล้วน',
        properties: {
          title: { type: 'string' },
          points: {
            type: 'array',
            items: {
              type: 'object',
              properties: { label: { type: 'string' }, value: { type: 'number' } },
              required: ['label', 'value'],
            },
          },
        },
        required: ['title', 'points'],
      },
    },
    required: ['answerText'],
    additionalProperties: false,
  },
};

const answerSchema = z.object({
  answerText: z.string().trim().min(1),
  chart: z
    .object({
      title: z.string(),
      points: z.array(z.object({ label: z.string(), value: z.number() })).max(100),
    })
    .optional(),
});

const buildSystemPrompt = () =>
  [
    'คุณเป็นผู้ช่วยวิเคราะห์ข้อมูลร้านอาหารของระบบ PaynEat POS ตอบคำถามของผู้จัดการ/ผู้ดูแลระบบ',
    'เกี่ยวกับยอดขาย เมนูขายดี ออเดอร์ ลูกค้า และประวัติการทำรายการ',
    '',
    'กฎที่ต้องทำตามเคร่งครัด:',
    '1. ห้ามตอบตัวเลขใดๆ ที่ไม่ได้มาจากผลลัพธ์ของเครื่องมือ (tool) ที่เรียกในการสนทนานี้เท่านั้น ' +
      'ห้ามเดา ห้ามแต่งขึ้นเอง ห้ามใช้ความรู้ทั่วไปของคุณตอบตัวเลขร้านนี้',
    '2. ถ้าคำถามเกี่ยวกับตัวเลข/ยอดขาย/ออเดอร์/ลูกค้า ต้องเรียก tool ที่เกี่ยวข้องก่อนตอบเสมอ',
    '3. ถ้าคำถามเปรียบเทียบสองช่วงเวลา ให้เรียก tool แยกสองครั้งด้วยคนละช่วงวันที่แล้วเทียบเอง',
    '4. ถ้าไม่มี tool ที่ตอบคำถามนี้ได้ หรือข้อมูลที่ได้ไม่พอตอบ ให้บอกตรงๆ ว่าไม่มีข้อมูล ห้ามเดา',
    '5. ตอบเป็นภาษาเดียวกับคำถามของผู้ใช้ (ไทยหรืออังกฤษ)',
    '6. เมื่อพร้อมตอบแล้ว ต้องเรียกเครื่องมือ submit_answer เสมอเป็นขั้นตอนสุดท้าย ห้ามตอบเป็นข้อความ' +
      'เฉยๆ โดยไม่เรียก submit_answer',
    '7. answerText ต้องระบุช่วงเวลาของข้อมูลที่ใช้เสมอ',
  ].join('\n');

const runConversation = async (client, model, tools, role, question) => {
  const messages = [{ role: 'user', content: question }];
  const sourcesUsed = [];
  const usage = { inputTokens: 0, outputTokens: 0 };

  for (let round = 0; round < MAX_ROUNDS; round += 1) {
    const forceSubmit = round === MAX_ROUNDS - 1;
    const response = await client.messages.create({
      model,
      max_tokens: 4096,
      system: buildSystemPrompt(),
      tools,
      tool_choice: forceSubmit ? { type: 'tool', name: 'submit_answer' } : { type: 'auto' },
      messages,
    });

    usage.inputTokens += response.usage?.input_tokens ?? 0;
    usage.outputTokens += response.usage?.output_tokens ?? 0;

    if (response.stop_reason === 'refusal') {
      return {
        result: { answerText: 'ผู้ช่วย AI ไม่สามารถตอบคำถามนี้ได้' },
        sourcesUsed,
        usage,
        isError: true,
      };
    }

    const toolUseBlocks = response.content.filter((block) => block.type === 'tool_use');
    const submitBlock = toolUseBlocks.find((block) => block.name === 'submit_answer');
    if (submitBlock) {
      const parsed = answerSchema.safeParse(submitBlock.input);
      if (parsed.success) return { result: parsed.data, sourcesUsed, usage, isError: false };
      // โมเดลเรียก submit_answer แต่รูปแบบข้อมูลไม่ตรง schema — ตกกลับไปใช้ข้อความดิบแทนไม่ถือว่า error
      return {
        result: { answerText: String(submitBlock.input?.answerText ?? 'ไม่พบคำตอบที่ถูกต้อง') },
        sourcesUsed,
        usage,
        isError: false,
      };
    }

    if (toolUseBlocks.length === 0) {
      const textBlock = response.content.find((block) => block.type === 'text');
      return {
        result: { answerText: textBlock?.text?.trim() || 'ไม่พบคำตอบ' },
        sourcesUsed,
        usage,
        isError: false,
      };
    }

    messages.push({ role: 'assistant', content: response.content });

    const toolResults = toolUseBlocks.map((block) => {
      const tool = getToolHandler(role, block.name);
      if (!tool) {
        return {
          type: 'tool_result',
          tool_use_id: block.id,
          is_error: true,
          content: `ไม่รู้จักเครื่องมือชื่อ ${block.name}`,
        };
      }

      // SDK อาจ parse tool input ที่ถูกตัดตอนกลางแบบเงียบๆ ได้ (ดู eager input streaming ใน
      // skill claude-api) จึง validate ซ้ำด้วย schema ของ tool เองเสมอก่อนเรียก handler จริง
      const parsedInput = tool.inputSchema.safeParse(block.input ?? {});
      if (!parsedInput.success) {
        return {
          type: 'tool_result',
          tool_use_id: block.id,
          is_error: true,
          content: `พารามิเตอร์ไม่ถูกต้อง: ${parsedInput.error.issues.map((i) => i.message).join(', ')}`,
        };
      }

      try {
        const output = tool.handler(parsedInput.data);
        sourcesUsed.push({ tool: block.name, args: parsedInput.data });
        return { type: 'tool_result', tool_use_id: block.id, content: JSON.stringify(output) };
      } catch (err) {
        return {
          type: 'tool_result',
          tool_use_id: block.id,
          is_error: true,
          content: `เครื่องมือทำงานผิดพลาด: ${err.message}`,
        };
      }
    });

    messages.push({ role: 'user', content: toolResults });
  }

  // ไม่ควรมาถึงจุดนี้ได้จริง เพราะรอบสุดท้ายบังคับ tool_choice เป็น submit_answer เสมอ
  return {
    result: { answerText: 'ผู้ช่วย AI ใช้เวลาคิดนานเกินไป กรุณาลองถามใหม่' },
    sourcesUsed,
    usage,
    isError: true,
  };
};

export const aiAssistantService = {
  async ask(user, question) {
    const client = getAnthropicClient();
    if (!client) {
      throw new ApiError(
        503,
        'ผู้ช่วย AI ยังไม่ได้เปิดใช้งาน (ยังไม่ได้ตั้งค่า ANTHROPIC_API_KEY)',
        {
          code: 'AI_ASSISTANT_DISABLED',
        },
      );
    }

    const usedToday = aiAssistantRepository.countToday(user.id);
    if (usedToday >= env.aiAssistant.dailyLimitPerUser) {
      throw new ApiError(
        429,
        `ถามผู้ช่วย AI ครบโควตาวันนี้แล้ว (${env.aiAssistant.dailyLimitPerUser} คำถาม/วัน) กรุณาลองใหม่พรุ่งนี้`,
        { code: 'AI_ASSISTANT_RATE_LIMITED' },
      );
    }

    const tools = [...getToolDefinitionsForRole(user.role), SUBMIT_ANSWER_TOOL];

    let outcome;
    try {
      outcome = await runConversation(client, env.aiAssistant.model, tools, user.role, question);
    } catch (err) {
      aiAssistantRepository.log({
        actorUser: user,
        question,
        isError: true,
        errorMessage: err.message,
      });
      throw new ApiError(502, 'เรียกผู้ช่วย AI ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง', {
        code: 'AI_ASSISTANT_UPSTREAM_ERROR',
      });
    }

    const { result, sourcesUsed, usage, isError } = outcome;
    aiAssistantRepository.log({
      actorUser: user,
      question,
      answer: result.answerText,
      toolCalls: sourcesUsed,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      isError,
    });

    return {
      answerText: result.answerText,
      chart: result.chart ?? null,
      sources: sourcesUsed,
      remainingToday: Math.max(0, env.aiAssistant.dailyLimitPerUser - usedToday - 1),
    };
  },
};

export default aiAssistantService;
