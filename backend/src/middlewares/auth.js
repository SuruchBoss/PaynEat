import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { ApiError } from '../core/ApiError.js';
import { userRepository } from '../modules/users/user.repository.js';
import { branchRepository } from '../modules/branches/branch.repository.js';
import { setLocationCode } from '../core/telemetry/requestContext.js';

/**
 * token ปกติพก branchId เสมอ (สาขาที่กำลังทำงานอยู่ — null ได้เฉพาะ admin แปลว่า "ทุกสาขา" ดู
 * docs/DECISIONS.md #36) ส่วน token แบบ pendingBranchSelection (ไม่มี branchId เลย) ออกให้ตอน
 * login ครั้งแรกของ user ที่มีสิทธิ์มากกว่า 1 สาขา ใช้เรียกได้แค่ POST /auth/select-branch
 * เท่านั้นเพื่อแลกเป็น token ปกติ (ดู auth.service.js#login/selectBranch)
 */
export const signToken = (user, branchId) =>
  jwt.sign(
    { sub: user.id, username: user.username, role: user.role, name: user.name, branchId },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn },
  );

export const signPendingBranchSelectionToken = (user) =>
  jwt.sign(
    {
      sub: user.id,
      username: user.username,
      role: user.role,
      name: user.name,
      pendingBranchSelection: true,
    },
    env.jwt.secret,
    // สั้นกว่า token ปกติมาก เพราะมีไว้ให้ทำแค่ขั้นตอนเดียว (เลือกสาขา) ทันทีหลัง login
    { expiresIn: '5m' },
  );

export const verifyToken = (token) => jwt.verify(token, env.jwt.secret);

const findActiveUserOrThrow = (userId) => {
  const user = userRepository.findById(userId);
  if (!user || !user.is_active) {
    throw ApiError.unauthorized('บัญชีนี้ถูกปิดการใช้งานหรือไม่มีอยู่แล้ว');
  }
  return user;
};

/** ตรวจ Bearer token และแนบ req.user + req.branchId */
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

  if (payload.pendingBranchSelection) {
    return next(ApiError.forbidden('ต้องเลือกสาขาก่อนใช้งาน (POST /auth/select-branch)'));
  }

  let user;
  try {
    // เช็คสถานะปัจจุบันจาก DB ทุก request แทนที่จะเชื่อ role/username/name ที่ฝังอยู่ใน token
    // เฉยๆ — ไม่งั้นบัญชีที่เพิ่งถูกปิดใช้งานหรือเปลี่ยน role จะยังใช้ token เก่าทำงานต่อได้จนกว่า
    // token จะหมดอายุเอง (สูงสุด 12 ชม. ตาม JWT_EXPIRES_IN) ดูรายงาน security review #5
    user = findActiveUserOrThrow(payload.sub);
  } catch (err) {
    return next(err);
  }

  const branchId = payload.branchId ?? null;
  // เช็คสิทธิ์สาขาจาก DB ทุก request เหมือนกัน (ไม่ใช่แค่ตอน login) เผื่อสิทธิ์ถูกถอดหรือสาขาถูกปิด
  // ไปแล้วหลัง token ออกไป (ดู branch.repository.js#hasAccess) — branchId เป็น null ได้เฉพาะ admin
  // เท่านั้น (โหมด "ทุกสาขา") ถ้า role ไม่ใช่ admin แต่ branchId เป็น null แปลว่า token ผิดปกติ
  if (branchId === null ? user.role !== 'admin' : !branchRepository.hasAccess(user, branchId)) {
    return next(ApiError.unauthorized('ไม่มีสิทธิ์เข้าถึงสาขานี้แล้ว กรุณาเข้าสู่ระบบใหม่'));
  }

  req.user = {
    id: user.id,
    username: user.username,
    role: user.role,
    name: user.name,
  };
  req.branchId = branchId;
  // label location_code ของทุกบรรทัด log ของคำขอนี้ (สัญญา telemetry — ticket 24)
  if (branchId !== null) setLocationCode(branchRepository.findById(branchId)?.code);
  return next();
};

/**
 * ใช้เฉพาะ POST /auth/select-branch — รับได้ทั้ง token แบบ pendingBranchSelection (กำลัง login
 * ครั้งแรกที่มีหลายสาขา) และ token ปกติที่ login สำเร็จแล้ว (ต้องการสลับสาขาภายหลัง)
 */
export const authenticateForBranchSelection = (req, _res, next) => {
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

  let user;
  try {
    user = findActiveUserOrThrow(payload.sub);
  } catch (err) {
    return next(err);
  }

  req.user = { id: user.id, username: user.username, role: user.role, name: user.name };
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
