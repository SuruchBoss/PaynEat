/**
 * ข้อผิดพลาดระดับ application ที่แปลงเป็น HTTP response ได้ตรง ๆ
 */
export class ApiError extends Error {
  constructor(statusCode, message, { code = undefined, details = undefined } = {}) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code ?? ApiError.defaultCode(statusCode);
    this.details = details;
    this.isOperational = true;
  }

  static defaultCode(statusCode) {
    const map = {
      400: 'BAD_REQUEST',
      401: 'UNAUTHORIZED',
      403: 'FORBIDDEN',
      404: 'NOT_FOUND',
      409: 'CONFLICT',
      422: 'UNPROCESSABLE_ENTITY',
      429: 'TOO_MANY_REQUESTS',
    };
    return map[statusCode] ?? 'INTERNAL_ERROR';
  }

  static badRequest(message, details) {
    return new ApiError(400, message, { details });
  }

  static unauthorized(message = 'ต้องเข้าสู่ระบบก่อนใช้งาน') {
    return new ApiError(401, message);
  }

  static forbidden(message = 'สิทธิ์ไม่เพียงพอสำหรับการทำรายการนี้') {
    return new ApiError(403, message);
  }

  static notFound(message = 'ไม่พบข้อมูลที่ต้องการ') {
    return new ApiError(404, message);
  }

  static conflict(message, details) {
    return new ApiError(409, message, { details });
  }

  static tooManyRequests(message = 'ทำรายการถี่เกินไป กรุณาลองใหม่อีกครั้งในอีกสักครู่') {
    return new ApiError(429, message);
  }
}

export default ApiError;
