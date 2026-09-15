import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:get/get.dart';

import '../../features/order/domain/entities/order.dart';
import '../../features/payment/domain/entities/payment.dart';
import '../../features/settings/domain/entities/printer_profile.dart';
import '../utils/formatters.dart';
import 'cp874_codec.dart';

/// แปลงข้อมูลออเดอร์/ใบเสร็จ (ก้อนเดียวกับที่ [ReceiptPage] ใช้แสดงบนจอ) เป็นชุดคำสั่ง
/// ESC/POS สำหรับส่งให้เครื่องพิมพ์ความร้อนจริง — เทมเพลตพิมพ์แยกจาก widget บนจอ แต่ดึง
/// ตัวเลขจาก entity เดียวกันเสมอ ไม่คำนวณซ้ำ
class ReceiptTicketBuilder {
  const ReceiptTicketBuilder._();

  static const String _codeTable = 'CP874';

  static Future<List<int>> forReceipt({
    required Order order,
    required Receipt receipt,
    required PrinterProfile printer,
  }) async {
    final generator = await _buildGenerator(printer);
    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        receipt.storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'printing_receipt_subtitle'.tr,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr(linesAfter: 1));

    bytes.addAll(
      generator.text(
        'printing_receipt_no_label'.trParams({'code': order.code}),
      ),
    );
    bytes.addAll(
      generator.text(
        'printing_receipt_date_label'.trParams({
          'datetime': Formatters.dateTime(order.closedAt),
        }),
      ),
    );
    bytes.addAll(
      generator.text(
        'printing_receipt_target_label'.trParams({
          'target': order.displayTarget,
        }),
      ),
    );
    if (order.waiterName != null) {
      bytes.addAll(
        generator.text(
          'printing_receipt_waiter_label'.trParams({'name': order.waiterName!}),
        ),
      );
    }
    bytes.addAll(
      generator.text(
        'printing_receipt_guest_count_label'.trParams({
          'count': order.guestCount.toString(),
        }),
      ),
    );
    bytes.addAll(generator.hr(linesAfter: 1));

    for (final item in order.activeItems) {
      bytes.addAll(
        generator.row([
          PosColumn(text: '${item.quantity}x', width: 2),
          PosColumn(text: item.name, width: 7),
          PosColumn(
            text: Formatters.money(item.lineTotal),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      if (item.options.isNotEmpty) {
        bytes.addAll(generator.text('   ${item.optionsSummary}'));
      }
    }
    bytes.addAll(generator.hr(linesAfter: 1));

    bytes.addAll(
      _line(
        generator,
        'payment_receipt_subtotal_label'.tr,
        Formatters.money(order.subtotal),
      ),
    );
    if (order.hasDiscount) {
      bytes.addAll(
        _line(
          generator,
          'payment_discount_label'.tr,
          '-${Formatters.money(order.discountAmount)}',
        ),
      );
    }
    if (order.hasPromotion) {
      bytes.addAll(
        _line(
          generator,
          'promotion_summary_label'.trParams({
            'name': order.promotionName ?? '',
          }),
          '-${Formatters.money(order.promotionDiscountAmount)}',
        ),
      );
    }
    bytes.addAll(
      _line(
        generator,
        'payment_service_charge_rate_label'.trParams({
          'rate': (receipt.serviceChargeRate * 100).toStringAsFixed(0),
        }),
        Formatters.money(order.serviceCharge),
      ),
    );
    bytes.addAll(
      _line(
        generator,
        'payment_vat_rate_label'.trParams({
          'rate': (receipt.vatRate * 100).toStringAsFixed(0),
        }),
        Formatters.money(order.vat),
      ),
    );
    bytes.addAll(generator.hr(linesAfter: 1));

    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'payment_grand_total_label'.tr,
          width: 6,
          styles: const PosStyles(bold: true, height: PosTextSize.size2),
        ),
        PosColumn(
          text: Formatters.baht(order.total),
          width: 6,
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            align: PosAlign.right,
          ),
        ),
      ]),
    );
    bytes.addAll(generator.hr(linesAfter: 1));

    for (final payment in receipt.payments) {
      bytes.addAll(
        _line(
          generator,
          payment.methodLabel,
          Formatters.money(payment.tendered),
        ),
      );
    }
    if (receipt.changeTotal > 0) {
      bytes.addAll(
        _line(
          generator,
          'payment_change_due_label'.tr,
          Formatters.money(receipt.changeTotal),
        ),
      );
    }

    if (receipt.isRefunded) {
      bytes.addAll(generator.hr(linesAfter: 1));
      bytes.addAll(
        generator.text(
          'printing_refund_section_title'.tr,
          styles: const PosStyles(bold: true),
        ),
      );
      for (final refund in receipt.refunds) {
        bytes.addAll(
          _line(
            generator,
            refund.reason,
            '-${Formatters.money(refund.amount)}',
          ),
        );
      }
      bytes.addAll(
        _line(
          generator,
          'payment_net_total_after_refund_label'.tr,
          Formatters.money(order.total - receipt.refundedTotal),
        ),
      );
    }

    bytes.addAll(generator.feed(1));
    bytes.addAll(
      generator.text(
        'printing_thank_you'.tr,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'Powered by PaynEat POS',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.cut());
    return bytes;
  }

  static Future<List<int>> testPage(PrinterProfile printer) async {
    final generator = await _buildGenerator(printer);
    final bytes = <int>[];
    bytes.addAll(
      generator.text(
        'printing_test_page_title'.tr,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'printing_test_page_success_message'.tr,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'printing_test_thai_charset'.tr,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.cut());
    return bytes;
  }

  static List<int> _line(Generator generator, String label, String value) =>
      generator.row([
        PosColumn(text: label, width: 8),
        PosColumn(
          text: value,
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

  static Future<Generator> _buildGenerator(PrinterProfile printer) async {
    final profile = await CapabilityProfile.load();
    final paperSize = printer.paperWidthMm <= 58
        ? PaperSize.mm58
        : PaperSize.mm80;
    final generator = Generator(paperSize, profile, codec: const Cp874Codec());
    generator.reset();
    generator.setGlobalCodeTable(_codeTable);
    return generator;
  }
}
