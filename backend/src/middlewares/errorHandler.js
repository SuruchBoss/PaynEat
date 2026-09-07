import { env } from '../config/env.js';
import { ApiError } from '../core/ApiError.js';

export const notFoundHandler = (req, _res, next) => {
  next(ApiError.notFound(`ไม่พบเส้นทาง ${req.method} ${req.originalUrl}`));
};

// eslint-disable-next-line no-unused-vars -- Express ต้องการ 4 อาร์กิวเมนต์เพื่อระบุว่านี่คือ error middleware
export const errorHandler = (err, _req, res, _next) => {
  const isApiError = err instanceof ApiError;
  const statusCode = isApiError ? err.statusCode : 500;

  if (!isApiError && !env.isTest) {
    console.error('[unhandled]', err);
  }

  res.status(statusCode).json({
    success: false,
    error: {
      code: isApiError ? err.code : 'INTERNAL_ERROR',
      message: isApiError ? err.message : 'เกิดข้อผิดพลาดภายในระบบ',
      details: isApiError ? err.details : undefined,
      stack: env.nodeEnv === 'development' && !isApiError ? err.stack : undefined,
    },
  });
};
