import bcrypt from 'bcryptjs';
import { ApiError } from '../../core/ApiError.js';
import { userRepository } from './user.repository.js';
import { toUserDto } from './user.mapper.js';

// เฉพาะ admin เท่านั้นที่แตะบัญชีระดับ admin ได้ (สร้างใหม่/แก้ไข/ตั้งรหัสใหม่ให้)
// กัน manager ยกระดับตัวเองเป็น admin ผ่าน role หรือ reset รหัสผ่านของ admin คนอื่นแล้วสวมรอย
// (ดูรายงาน security review — privilege escalation ผ่าน PATCH /users/:id และ reset-password)
const assertAdminBoundary = (actingUser, { targetRole, newRole } = {}) => {
  if (actingUser.role === 'admin') return;
  if (targetRole === 'admin' || newRole === 'admin') {
    throw ApiError.forbidden('ต้องมีสิทธิ์ admin สำหรับบัญชีนี้');
  }
};

export const userService = {
  list(filters) {
    return userRepository.findAll(filters).map(toUserDto);
  },

  getById(id) {
    const user = userRepository.findById(id);
    if (!user) throw ApiError.notFound('ไม่พบผู้ใช้งานนี้');
    return toUserDto(user);
  },

  create({ name, username, password, role }, actingUser) {
    assertAdminBoundary(actingUser, { newRole: role });
    if (userRepository.findByUsername(username)) {
      throw ApiError.conflict('username นี้ถูกใช้งานแล้ว');
    }
    const passwordHash = bcrypt.hashSync(password, 10);
    return toUserDto(userRepository.create({ name, username, passwordHash, role }));
  },

  update(id, payload, actingUser) {
    const target = this.getById(id);
    assertAdminBoundary(actingUser, { targetRole: target.role, newRole: payload.role });
    return toUserDto(userRepository.update(id, payload));
  },

  resetPassword(id, password, actingUser) {
    const target = this.getById(id);
    assertAdminBoundary(actingUser, { targetRole: target.role });
    return toUserDto(userRepository.updatePassword(id, bcrypt.hashSync(password, 10)));
  },

  remove(id, currentUserId) {
    if (Number(id) === Number(currentUserId)) {
      throw ApiError.badRequest('ไม่สามารถลบบัญชีของตัวเองได้');
    }
    this.getById(id);
    userRepository.remove(id);
  },
};

export default userService;
