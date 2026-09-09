import '../../../../core/constants/app_constants.dart';

/// กะทำงานของแคชเชียร์ — เปิดกะพร้อมเงินตั้งต้น แล้วปิดกะเทียบยอดเงินสดจริงกับที่ระบบคาดไว้
class Shift {
  const Shift({
    required this.id,
    required this.status,
    required this.openedBy,
    this.openedByName,
    required this.openedAt,
    required this.openingCash,
    this.closedBy,
    this.closedByName,
    this.closedAt,
    this.expectedCash,
    this.countedCash,
    this.variance,
    this.note,
  });

  final int id;
  final String status;
  final int openedBy;
  final String? openedByName;
  final String openedAt;
  final double openingCash;
  final int? closedBy;
  final String? closedByName;
  final String? closedAt;
  final double? expectedCash;
  final double? countedCash;
  final double? variance;
  final String? note;

  bool get isOpen => status == ShiftStatus.open;
}
