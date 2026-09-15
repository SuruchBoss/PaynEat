part of 'demo_store.dart';

// ------------------------------------------------------- audit logs -------
/// Mirror ของ backend audit-log.service.js (ดู docs/tickets/08-audit-log.md)
/// เก็บ log append-only ไว้ในหน่วยความจำเหมือนข้อมูลอื่นๆ ของ Demo Mode —
/// ไม่มี endpoint แก้ไข/ลบเปิดให้ใช้เลยเช่นเดียวกับฝั่ง backend
extension DemoStoreAuditLogs on DemoStore {
  String _auditActorName(int? actorId) {
    if (actorId == null) return 'ระบบ';
    try {
      return _findUser(actorId)['name'] as String;
    } on ApiException {
      return 'ระบบ';
    }
  }

  void _logAudit({
    int? actorId,
    required String action,
    required String entityType,
    int? entityId,
    required String summary,
    String? reason,
    Map<String, dynamic>? metadata,
  }) {
    auditLogs.add({
      'id': _nextId(),
      'actorUserId': actorId,
      'actorName': _auditActorName(actorId),
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'summary': summary,
      'reason': reason,
      'metadata': metadata,
      'createdAt': _now(),
    });
  }

  /// คืน total มาด้วยเหมือน backend (audit-log.controller.js ส่ง meta.total)
  /// เพื่อให้หน้าจอบอกได้ว่าเห็นอยู่กี่จากทั้งหมด และมีให้โหลดต่อไหม
  ({List<Map<String, dynamic>> rows, int total}) auditLogList({
    int? actorUserId,
    String? action,
    String? entityType,
    int? entityId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) {
    final matched = auditLogs.reversed
        .where((log) {
          if (actorUserId != null && log['actorUserId'] != actorUserId) {
            return false;
          }
          if (action != null && log['action'] != action) return false;
          if (entityType != null && log['entityType'] != entityType) {
            return false;
          }
          if (entityId != null && log['entityId'] != entityId) return false;

          final createdAt = log['createdAt'] as String;
          if (dateFrom != null && createdAt.compareTo(dateFrom) < 0) {
            return false;
          }
          if (dateTo != null && createdAt.compareTo('${dateTo}T23:59:59') > 0) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return (
      rows: matched
          .skip((page - 1) * limit)
          .take(limit)
          .toList(growable: false),
      total: matched.length,
    );
  }
}
