import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.pointsBalance,
    super.createdAt,
    super.updatedAt,
    super.creditLimit,
    super.creditTermDays,
    super.taxId,
    super.address,
    super.creditOutstanding,
    super.creditAvailable,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String?,
    pointsBalance: (json['pointsBalance'] as num?)?.toInt() ?? 0,
    createdAt: json['createdAt'] as String?,
    updatedAt: json['updatedAt'] as String?,
    creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
    creditTermDays: (json['creditTermDays'] as num?)?.toInt() ?? 30,
    taxId: json['taxId'] as String?,
    address: json['address'] as String?,
    creditOutstanding: (json['creditOutstanding'] as num?)?.toDouble(),
    creditAvailable: (json['creditAvailable'] as num?)?.toDouble(),
  );
}
