import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/promotion.dart';
import '../repositories/promotion_repository.dart';

class GetPromotionsUseCase implements UseCase<List<Promotion>, bool> {
  const GetPromotionsUseCase(this._repository);

  final PromotionRepository _repository;

  @override
  Future<Result<List<Promotion>>> call(bool params) =>
      _repository.getPromotions(activeOnly: params);
}

/// ข้อมูลจากฟอร์มสร้าง/แก้ไขโปรโมชัน — แยกจาก entity เพราะรูปร่าง input ต่างจากที่แสดงผล
class PromotionFormData {
  const PromotionFormData({
    required this.name,
    required this.type,
    required this.value,
    this.code,
    this.conditions = const PromotionConditions(),
    this.isActive = true,
    this.validFrom,
    this.validTo,
  });

  final String name;
  final String type;
  final double value;

  /// null/ว่าง = ไม่ใช้โค้ด (apply อัตโนมัติ)
  final String? code;
  final PromotionConditions conditions;
  final bool isActive;
  final String? validFrom;
  final String? validTo;

  Map<String, dynamic> _conditionsJson() => {
    if (conditions.daysOfWeek.isNotEmpty) 'daysOfWeek': conditions.daysOfWeek,
    if (conditions.startTime != null) 'startTime': conditions.startTime,
    if (conditions.endTime != null) 'endTime': conditions.endTime,
    if (conditions.categoryIds.isNotEmpty)
      'categoryIds': conditions.categoryIds,
    if (conditions.menuItemIds.isNotEmpty)
      'menuItemIds': conditions.menuItemIds,
    if (conditions.minSubtotal > 0) 'minSubtotal': conditions.minSubtotal,
  };

  /// ตอนสร้างใหม่ — field `code` ต้อง "ไม่ส่งเลย" ถ้าไม่ใช้โค้ด (schema ฝั่ง backend
  /// ไม่รับ null สำหรับสร้างใหม่ ต่างจากตอนแก้ไขที่ส่ง null เพื่อ "ลบโค้ดออก" ได้)
  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'type': type,
    'value': value,
    if (code != null && code!.isNotEmpty) 'code': code,
    'conditions': _conditionsJson(),
    'isActive': isActive,
    if (validFrom != null) 'validFrom': validFrom,
    if (validTo != null) 'validTo': validTo,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'type': type,
    'value': value,
    'code': code != null && code!.isNotEmpty ? code : null,
    'conditions': _conditionsJson(),
    'isActive': isActive,
    'validFrom': validFrom,
    'validTo': validTo,
  };
}

class SavePromotionParams {
  const SavePromotionParams({this.id, required this.data});

  final int? id;
  final PromotionFormData data;
}

class SavePromotionUseCase implements UseCase<Promotion, SavePromotionParams> {
  const SavePromotionUseCase(this._repository);

  final PromotionRepository _repository;

  @override
  Future<Result<Promotion>> call(SavePromotionParams params) {
    if (params.id == null) {
      return _repository.createPromotion(params.data.toCreateJson());
    }
    return _repository.updatePromotion(params.id!, params.data.toUpdateJson());
  }
}

class SetPromotionActiveParams {
  const SetPromotionActiveParams({required this.id, required this.isActive});

  final int id;
  final bool isActive;
}

class SetPromotionActiveUseCase
    implements UseCase<Promotion, SetPromotionActiveParams> {
  const SetPromotionActiveUseCase(this._repository);

  final PromotionRepository _repository;

  @override
  Future<Result<Promotion>> call(SetPromotionActiveParams params) =>
      _repository.updatePromotion(params.id, {'isActive': params.isActive});
}

class DeletePromotionUseCase implements UseCase<void, int> {
  const DeletePromotionUseCase(this._repository);

  final PromotionRepository _repository;

  @override
  Future<Result<void>> call(int params) => _repository.deletePromotion(params);
}
