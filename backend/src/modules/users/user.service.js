import bcrypt from 'bcryptjs';
import { ApiError } from '../../core/ApiError.js';
import { userRepository } from './user.repository.js';
import { toUserDto } from './user.mapper.js';

export const userService = {
  list(filters) {
    return userRepository.findAll(filters).map(toUserDto);
  },

  getById(id) {
    const user = userRepository.findById(id);
    if (!user) throw ApiError.notFound('ไม่พบผู้ใช้งานนี้');
    return toUserDto(user);
  },

  create({ name, username, password, role }) {
    if (userRepository.findByUsername(username)) {
      throw ApiError.conflict('username นี้ถูกใช้งานแล้ว');
    }
    const passwordHash = bcrypt.hashSync(password, 10);
    return toUserDto(userRepository.create({ name, username, passwordHash, role }));
  },

  update(id, payload) {
    this.getById(id);
    return toUserDto(userRepository.update(id, payload));
  },

  resetPassword(id, password) {
    this.getById(id);
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
