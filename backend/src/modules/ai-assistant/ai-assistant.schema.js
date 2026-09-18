import { z } from 'zod';

export const askQuestionSchema = z.object({
  question: z
    .string()
    .trim()
    .min(1, 'กรุณากรอกคำถาม')
    .max(500, 'คำถามยาวเกินไป (สูงสุด 500 ตัวอักษร)'),
});

export default askQuestionSchema;
