import { ApiError } from '../core/ApiError.js';

/**
 * ตรวจ request ด้วย zod schema แล้วเขียนค่าที่ผ่านการ parse กลับเข้า req
 * รองรับ { body, query, params }
 */
export const validate = (schemas) => (req, _res, next) => {
  const validated = {};

  for (const key of ['body', 'query', 'params']) {
    const schema = schemas[key];
    if (!schema) continue;

    const result = schema.safeParse(req[key]);
    if (!result.success) {
      const details = result.error.issues.map((issue) => ({
        field: issue.path.join('.') || key,
        message: issue.message,
      }));
      return next(
        new ApiError(422, 'ข้อมูลที่ส่งมาไม่ถูกต้อง', { code: 'VALIDATION_ERROR', details }),
      );
    }
    validated[key] = result.data;
  }

  // Express 5 ทำให้ req.query เป็น getter อย่างเดียว จึงเก็บผลลัพธ์ไว้ที่ req.validated
  req.validated = validated;
  if (validated.body) req.body = validated.body;
  return next();
};

export default validate;
