import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../menu/domain/entities/category.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../repositories/self_order_repository.dart';

class GetSelfOrderMenuUseCase
    implements
        UseCase<
          ({
            List<Category> categories,
            List<MenuItem> items,
            int staffOnlyCount,
          }),
          String
        > {
  const GetSelfOrderMenuUseCase(this._repository);

  final SelfOrderRepository _repository;

  @override
  Future<
    Result<
      ({List<Category> categories, List<MenuItem> items, int staffOnlyCount})
    >
  >
  call(String qrToken) => _repository.getMenu(qrToken);
}
