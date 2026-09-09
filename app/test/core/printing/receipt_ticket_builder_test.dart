import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/printing/receipt_ticket_builder.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item.dart';
import 'package:payneat_pos/features/payment/domain/entities/payment.dart';
import 'package:payneat_pos/features/settings/domain/entities/printer_profile.dart';

Order _order() => const Order(
  id: 1,
  code: 'A001',
  type: 'dine_in',
  status: 'paid',
  tableName: 'A1',
  waiterName: 'สมชาย',
  guestCount: 2,
  subtotal: 100,
  serviceCharge: 10,
  vat: 7.7,
  total: 117.7,
  items: [
    OrderItem(
      id: 1,
      orderId: 1,
      name: 'ข้าวผัดกุ้ง',
      unitPrice: 100,
      quantity: 1,
      lineTotal: 100,
      status: 'served',
    ),
  ],
);

Receipt _receipt() => const Receipt(
  storeName: 'ร้านทดสอบ',
  currency: 'THB',
  vatRate: 0.07,
  serviceChargeRate: 0.1,
  payments: [Payment(id: 1, orderId: 1, method: 'cash', amount: 117.7)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiptTicketBuilder', () {
    test(
      'forReceipt สร้างไบต์ ESC/POS ได้โดยไม่ throw (กระดาษ 80 มม.)',
      () async {
        final bytes = await ReceiptTicketBuilder.forReceipt(
          order: _order(),
          receipt: _receipt(),
          printer: const PrinterProfile(
            ipAddress: '192.168.1.50',
            enabled: true,
          ),
        );

        expect(bytes, isNotEmpty);
      },
    );

    test('forReceipt รองรับกระดาษ 58 มม. เช่นกัน', () async {
      final bytes = await ReceiptTicketBuilder.forReceipt(
        order: _order(),
        receipt: _receipt(),
        printer: const PrinterProfile(
          ipAddress: '192.168.1.50',
          paperWidthMm: 58,
          enabled: true,
        ),
      );

      expect(bytes, isNotEmpty);
    });

    test('testPage สร้างไบต์ได้โดยไม่ throw', () async {
      final bytes = await ReceiptTicketBuilder.testPage(
        const PrinterProfile(ipAddress: '192.168.1.50', enabled: true),
      );

      expect(bytes, isNotEmpty);
    });
  });
}
