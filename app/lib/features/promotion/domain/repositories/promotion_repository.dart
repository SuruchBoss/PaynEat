import '../../../../core/usecases/result.dart';
import '../entities/promotion.dart';

abstract class PromotionRepository {
  Future<Result<List<Promotion>>> getPromotions({bool activeOnly});
  Future<Result<Promotion>> getPromotion(int id);
  Future<Result<Promotion>> createPromotion(Map<String, dynamic> payload);
  Future<Result<Promotion>> updatePromotion(
    int id,
    Map<String, dynamic> changes,
  );
  Future<Result<void>> deletePromotion(int id);
}
