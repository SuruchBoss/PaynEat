import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

import '../../features/order/domain/entities/order.dart';
import '../../features/payment/domain/entities/payment.dart';
import '../../features/settings/domain/entities/printer_profile.dart';
import '../errors/failures.dart';
import '../usecases/result.dart';
import 'printer_transport_stub.dart'
    if (dart.library.io) 'printer_transport_io.dart'
    as transport;
import 'receipt_ticket_builder.dart';

/// ส่งใบเสร็จไปพิมพ์จริงที่เครื่องพิมพ์ความร้อนผ่าน LAN/WiFi (ราว ESC/POS พอร์ต 9100)
///
/// ทำงานได้เฉพาะแพลตฟอร์มที่มี `dart:io` (Android/iOS/desktop) — เว็บเปิด TCP socket ตรง ๆ
/// จาก browser ไม่ได้ จึงคืนความล้มเหลวพร้อมข้อความอธิบายทันที ใบเสร็จบนจอยังใช้งานได้ตาม
/// ปกติเสมอไม่ว่าผลการพิมพ์จะเป็นอย่างไร (ไม่กระทบ demo mode)
class ReceiptPrinterService {
  Future<Result<void>> printReceipt({
    required PrinterProfile printer,
    required Order order,
    required Receipt receipt,
  }) => _send(
    () => ReceiptTicketBuilder.forReceipt(
      order: order,
      receipt: receipt,
      printer: printer,
    ),
    printer,
  );

  Future<Result<void>> printTestPage(PrinterProfile printer) =>
      _send(() => ReceiptTicketBuilder.testPage(printer), printer);

  Future<Result<void>> _send(
    Future<List<int>> Function() buildTicket,
    PrinterProfile printer,
  ) async {
    if (kIsWeb) {
      return Result.failure(
        UnexpectedFailure('settings_printer_web_not_supported'.tr),
      );
    }
    if (!printer.isConfigured) {
      return Result.failure(
        ValidationFailure('settings_printer_not_configured'.tr),
      );
    }
    try {
      final bytes = await buildTicket();
      await transport
          .sendBytes(printer.ipAddress, printer.port, bytes)
          .timeout(const Duration(seconds: 8));
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        NetworkFailure(
          'settings_printer_print_failed'.trParams({'error': e.toString()}),
        ),
      );
    }
  }
}
