import '../../domain/entities/user.dart';

/// ตัวแปลงระหว่าง JSON ↔ entity
/// วางไว้ชั้น data เพื่อให้ entity ใน domain ไม่ต้องรู้จักรูปแบบ API
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.username,
    required super.role,
    required super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        role: json['role'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'role': role,
        'isActive': isActive,
      };
}
