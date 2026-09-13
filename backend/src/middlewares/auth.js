import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { ApiError } from '../core/ApiError.js';
import { userRepository } from '../modules/users/user.repository.js';

export const signToken = (user) =>
  jwt.sign(
    { sub: user.id, username: user.username, role: user.role, name: user.name },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn },
  );

export const verifyToken = (token) => jwt.verify(token, env.jwt.secret);

/** ตรวจ Bearer token และแนบ req.user */
export const authenticate = (req, _res, next) => {
  const header = req.headers.authorization ?? '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return next(ApiError.unauthorized('ไม่พบ access token'));
  }

  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    return next(ApiError.unauthorized('Token ไม่ถูกต้องหรือหมดอายุ'));
  }

  // เช็คสถานะปัจจุบันจาก DB ทุก request แทนที่จะเชื่อ role/username/name ที่ฝังอยู่ใน token
  // เฉยๆ — ไม่งั้นบัญชีที่เพิ่งถูกปิดใช้งานหรือเปลี่ยน role จะยังใช้ token เก่าทำงานต่อได้จนกว่า
  // token จะหมดอายุเอง (สูงสุด 12 ชม. ตาม JWT_EXPIRES_IN) ดูรายงาน security review #5
  const user = userRepository.findById(payload.sub);
  if (!user || !user.is_active) {
    return next(ApiError.unauthorized('บัญชีนี้ถูกปิดการใช้งานหรือไม่มีอยู่แล้ว'));
  }

  req.user = {
    id: user.id,
    username: user.username,
    role: user.role,
    name: user.name,
  };
  return next();
};

/**
 * จำกัดสิทธิ์ตาม role
 * ตัวอย่าง: router.post('/', authenticate, authorize('admin', 'manager'), handler)
 */
export const authorize =
  (...roles) =>
  (req, _res, next) => {
    if (!req.user) return next(ApiError.unauthorized());
    if (roles.length > 0 && !roles.includes(req.user.role)) {
      return next(ApiError.forbidden(`ต้องมีสิทธิ์: ${roles.join(', ')}`));
    }
    return next();
  };
