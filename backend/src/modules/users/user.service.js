import bcrypt from 'bcryptjs';
import { ApiError } from '../../core/ApiError.js';
import { getDb } from '../../db/index.js';
import { auditLogService } from '../audit-logs/audit-log.service.js';
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

    const run = getDb().transaction(() => {
      const updated = userRepository.update(id, payload);
      // แก้ role กับปิดการใช้งานเป็นการกระทำที่เสี่ยง ต้อง log แยกจากกัน (แก้ชื่อเฉยๆ ไม่ต้อง log)
      // ดู docs/tickets/08-audit-log.md
      if (payload.role !== undefined && payload.role !== target.role) {
        auditLogService.log({
          actorUser: actingUser,
          action: 'user.role_change',
          entityType: 'user',
          entityId: target.id,
          summary: `เปลี่ยนสิทธิ์บัญชี "${target.name}" จาก ${target.role} เป็น ${payload.role}`,
          metadata: { username: target.username, previousRole: target.role, newRole: payload.role },
        });
      }
      if (payload.isActive === false && target.isActive) {
        auditLogService.log({
          actorUser: actingUser,
          action: 'user.deactivate',
          entityType: 'user',
          entityId: target.id,
          summary: `ปิดการใช้งานบัญชี "${target.name}" (${target.username})`,
          metadata: { username: target.username },
        });
      }
      return updated;
    });
    return toUserDto(run());
  },

  resetPassword(id, password, actingUser) {
    const target = this.getById(id);
    assertAdminBoundary(actingUser, { targetRole: target.role });

    const run = getDb().transaction(() => {
      const updated = userRepository.updatePassword(id, bcrypt.hashSync(password, 10));
      auditLogService.log({
        actorUser: actingUser,
        action: 'user.password_reset',
        entityType: 'user',
        entityId: target.id,
        summary: `ตั้งรหัสผ่านใหม่ให้บัญชี "${target.name}" (${target.username})`,
        metadata: { username: target.username },
      });
      return updated;
    });
    return toUserDto(run());
  },

  remove(id, actingUser) {
    if (Number(id) === Number(actingUser.id)) {
      throw ApiError.badRequest('ไม่สามารถลบบัญชีของตัวเองได้');
    }
    const target = this.getById(id);

    const run = getDb().transaction(() => {
      userRepository.remove(id);
      auditLogService.log({
        actorUser: actingUser,
        action: 'user.delete',
        entityType: 'user',
        entityId: target.id,
        summary: `ลบบัญชี "${target.name}" (${target.username}) ออกจากระบบ`,
        metadata: { username: target.username, role: target.role },
      });
    });
    run();
  },
};

export default userService;
