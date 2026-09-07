import bcrypt from 'bcryptjs';
import { ApiError } from '../../core/ApiError.js';
import { signToken } from '../../middlewares/auth.js';
import { userRepository } from '../users/user.repository.js';
import { toUserDto } from '../users/user.mapper.js';

export const authService = {
  login({ username, password }) {
    const user = userRepository.findByUsername(username);
    if (!user || !bcrypt.compareSync(password, user.password_hash)) {
      throw ApiError.unauthorized('username หรือรหัสผ่านไม่ถูกต้อง');
    }
    if (!user.is_active) {
      throw ApiError.forbidden('บัญชีนี้ถูกปิดการใช้งาน กรุณาติดต่อผู้ดูแลระบบ');
    }
    return { token: signToken(user), user: toUserDto(user) };
  },

  me(userId) {
    const user = userRepository.findById(userId);
    if (!user) throw ApiError.unauthorized('ไม่พบบัญชีผู้ใช้');
    return toUserDto(user);
  },

  changePassword(userId, { currentPassword, newPassword }) {
    const user = userRepository.findById(userId);
    if (!user) throw ApiError.unauthorized();

    const full = userRepository.findByUsername(user.username);
    if (!bcrypt.compareSync(currentPassword, full.password_hash)) {
      throw ApiError.badRequest('รหัสผ่านปัจจุบันไม่ถูกต้อง');
    }
    userRepository.updatePassword(userId, bcrypt.hashSync(newPassword, 10));
  },
};

export default authService;
