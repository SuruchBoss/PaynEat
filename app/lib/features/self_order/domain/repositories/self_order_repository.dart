import '../../../../core/usecases/result.dart';
import '../../../menu/domain/entities/category.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../order/domain/entities/order.dart';
import '../../../order/domain/entities/order_item_payload.dart';
import '../entities/self_order_table.dart';

/// คุยกับ endpoint สาธารณะ `/public/tables/:qrToken/*` (ดู docs/tickets/17-qr-self-order.md) —
/// ไม่มี token/session ใดๆ เกี่ยวข้องเลยทั้ง interface นี้โดยตั้งใจ
abstract class SelfOrderRepository {
  Future<Result<({SelfOrderTable table, Order? order})>> getTable(
    String qrToken,
  );

  Future<
    Result<
      ({List<Category> categories, List<MenuItem> items, int staffOnlyCount})
    >
  >
  getMenu(String qrToken);

  /// เพิ่มรายการเข้าออเดอร์ปัจจุบันของโต๊ะนี้ (เปิดออเดอร์ใหม่ให้อัตโนมัติถ้ายังไม่มี) — คืนพรีวิว
  /// ออเดอร์ล่าสุดหลังเพิ่มแล้ว
  Future<Result<Order>> addItems(String qrToken, List<OrderItemPayload> items);
}
