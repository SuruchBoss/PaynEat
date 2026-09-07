import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { ApiError } from '../core/ApiError.js';

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

  try {
    const payload = verifyToken(token);
    req.user = {
      id: payload.sub,
      username: payload.username,
      role: payload.role,
      name: payload.name,
    };
    return next();
  } catch {
    return next(ApiError.unauthorized('Token ไม่ถูกต้องหรือหมดอายุ'));
  }
};

/**
 * จำกัดสิทธิ์ตาม role
 * ตัวอย่าง: router.post('/', authenticate, authorize('admin', 'manager'), handler)
 */
export const authorize = (...roles) => (req, _res, next) => {
  if (!req.user) return next(ApiError.unauthorized());
  if (roles.length > 0 && !roles.includes(req.user.role)) {
    return next(ApiError.forbidden(`ต้องมีสิทธิ์: ${roles.join(', ')}`));
  }
  return next();
};
