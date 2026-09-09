import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/shift.dart';

class ShiftModel extends Shift {
  const ShiftModel({
    required super.id,
    required super.status,
    required super.openedBy,
    super.openedByName,
    required super.openedAt,
    required super.openingCash,
    super.closedBy,
    super.closedByName,
    super.closedAt,
    super.expectedCash,
    super.countedCash,
    super.variance,
    super.note,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) => ShiftModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? ShiftStatus.open,
    openedBy: (json['openedBy'] as num?)?.toInt() ?? 0,
    openedByName: json['openedByName'] as String?,
    openedAt: json['openedAt'] as String? ?? '',
    openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0,
    closedBy: (json['closedBy'] as num?)?.toInt(),
    closedByName: json['closedByName'] as String?,
    closedAt: json['closedAt'] as String?,
    expectedCash: (json['expectedCash'] as num?)?.toDouble(),
    countedCash: (json['countedCash'] as num?)?.toDouble(),
    variance: (json['variance'] as num?)?.toDouble(),
    note: json['note'] as String?,
  );
}
