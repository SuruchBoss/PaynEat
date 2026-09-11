import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/repositories/promotion_repository.dart';
import '../datasources/promotion_remote_data_source.dart';

class PromotionRepositoryImpl implements PromotionRepository {
  const PromotionRepositoryImpl(this._remote);

  final PromotionRemoteDataSource _remote;

  @override
  Future<Result<List<Promotion>>> getPromotions({bool activeOnly = false}) =>
      guard(() async => await _remote.getPromotions(activeOnly: activeOnly));

  @override
  Future<Result<Promotion>> getPromotion(int id) =>
      guard(() async => await _remote.getPromotion(id));

  @override
  Future<Result<Promotion>> createPromotion(Map<String, dynamic> payload) =>
      guard(() async => await _remote.createPromotion(payload));

  @override
  Future<Result<Promotion>> updatePromotion(
    int id,
    Map<String, dynamic> changes,
  ) => guard(() async => await _remote.updatePromotion(id, changes));

  @override
  Future<Result<void>> deletePromotion(int id) =>
      guard(() => _remote.deletePromotion(id));
}
