/// รายการ audit log — บันทึกการกระทำที่เสี่ยงต่อการทุจริตหน้าร้าน (ดู
/// docs/tickets/08-audit-log.md) append-only เสมอ ไม่มีทางแก้ไข/ลบจากแอปนี้
class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorName,
    required this.action,
    required this.entityType,
    required this.summary,
    required this.createdAt,
    this.actorUserId,
    this.entityId,
    this.reason,
    this.metadata,
  });

  final int id;
  final int? actorUserId;
  final String actorName;
  final String action;
  final String entityType;
  final int? entityId;
  final String summary;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final String createdAt;
}
