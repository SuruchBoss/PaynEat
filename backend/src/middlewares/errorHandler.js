import { env } from '../config/env.js';
import { ApiError } from '../core/ApiError.js';
import { languageOf, translateMessage } from '../i18n/errorMessages.js';

export const notFoundHandler = (req, _res, next) => {
  next(ApiError.notFound(`ไม่พบเส้นทาง ${req.method} ${req.originalUrl}`));
};

export const errorHandler = (err, req, res, _next) => {
  const isApiError = err instanceof ApiError;
  const statusCode = isApiError ? err.statusCode : 500;
  // แอปส่ง Accept-Language ตามภาษาที่ผู้ใช้เลือก — ข้อความต้นฉบับในโค้ดเป็นภาษาไทย (DECISIONS #64)
  const lang = languageOf(req);
  const details =
    isApiError && Array.isArray(err.details)
      ? err.details.map((d) =>
          d && typeof d === 'object' && 'message' in d
            ? { ...d, message: translateMessage(d.message, lang) }
            : d,
        )
      : isApiError
        ? err.details
        : undefined;

  if (!isApiError && !env.isTest) {
    console.error('[unhandled]', err);
  }

  res.status(statusCode).json({
    success: false,
    error: {
      code: isApiError ? err.code : 'INTERNAL_ERROR',
      message: translateMessage(isApiError ? err.message : 'เกิดข้อผิดพลาดภายในระบบ', lang),
      details,
      stack: env.nodeEnv === 'development' && !isApiError ? err.stack : undefined,
    },
  });
};
