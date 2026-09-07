import '../../../../core/constants/app_constants.dart';

/// ผู้ใช้งานระบบ — entity บริสุทธิ์ ไม่ผูกกับ JSON หรือ framework ใด ๆ
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String name;
  final String username;
  final String role;
  final bool isActive;

  String get roleLabel => UserRole.label(role);

  bool get isManagement => UserRole.isManagement(role);
  bool get canTakeOrder => UserRole.canTakeOrder(role);
  bool get canCollectPayment => UserRole.canCollectPayment(role);
  bool get canSeeReports => UserRole.canSeeReports(role);
  bool get isKitchen => role == UserRole.kitchen;

  /// ตัวอักษรย่อสำหรับแสดงใน avatar
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
