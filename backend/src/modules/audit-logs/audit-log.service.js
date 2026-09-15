import { auditLogRepository } from './audit-log.repository.js';
import { toAuditLogDto } from './audit-log.mapper.js';

export const auditLogService = {
  /**
   * บันทึกเหตุการณ์ที่เสี่ยงต่อการทุจริตหน้าร้าน — เรียกจาก service อื่นเท่านั้น (ไม่มี endpoint
   * สร้าง log ตรงๆ ให้เรียกจากภายนอก) ผู้เรียกควรเรียกภายในทรานแซกชันเดียวกับการเปลี่ยนแปลงข้อมูล
   * จริงเสมอ เพื่อให้ atomic — ถ้าบันทึก log ไม่สำเร็จ การกระทำนั้นต้องล้มเหลวไปด้วย ไม่ใช่ปล่อยผ่าน
   */
  log({ actorUser, action, entityType, entityId, summary, reason, metadata }) {
    return toAuditLogDto(
      auditLogRepository.create({
        actorUserId: actorUser?.id,
        actorName: actorUser?.name ?? 'ระบบ',
        action,
        entityType,
        entityId,
        summary,
        reason,
        metadata,
      }),
    );
  },

  list(filters) {
    const { rows, total } = auditLogRepository.findAll(filters);
    return { items: rows.map(toAuditLogDto), total };
  },
};

export default auditLogService;
