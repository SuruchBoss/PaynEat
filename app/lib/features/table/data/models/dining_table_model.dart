import '../../domain/entities/dining_table.dart';

class DiningTableModel extends DiningTable {
  const DiningTableModel({
    required super.id,
    required super.name,
    required super.zone,
    required super.seats,
    required super.status,
    super.isActive,
    super.currentOrder,
  });

  factory DiningTableModel.fromJson(Map<String, dynamic> json) {
    final order = json['currentOrder'];
    return DiningTableModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'available',
      isActive: json['isActive'] as bool? ?? true,
      currentOrder: order is Map<String, dynamic>
          ? TableOrderSummary(
              id: (order['id'] as num).toInt(),
              code: order['code'] as String? ?? '',
              status: order['status'] as String? ?? '',
              total: (order['total'] as num?)?.toDouble() ?? 0,
              guestCount: (order['guestCount'] as num?)?.toInt() ?? 0,
              createdAt: order['createdAt'] as String?,
            )
          : null,
    );
  }
}
