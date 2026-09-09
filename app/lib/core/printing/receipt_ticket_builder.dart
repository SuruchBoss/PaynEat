import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

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
        'ใบเสร็จรับเงิน / ใบกำกับภาษีอย่างย่อ',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr(linesAfter: 1));

    bytes.addAll(generator.text('เลขที่: ${order.code}'));
    bytes.addAll(
      generator.text('วันที่: ${Formatters.dateTime(order.closedAt)}'),
    );
    bytes.addAll(generator.text('โต๊ะ/ประเภท: ${order.displayTarget}'));
    if (order.waiterName != null) {
      bytes.addAll(generator.text('พนักงาน: ${order.waiterName}'));
    }
    bytes.addAll(generator.text('จำนวนลูกค้า: ${order.guestCount} ท่าน'));
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
      _line(generator, 'ยอดรวมอาหาร', Formatters.money(order.subtotal)),
    );
    if (order.hasDiscount) {
      bytes.addAll(
        _line(
          generator,
          'ส่วนลด',
          '-${Formatters.money(order.discountAmount)}',
        ),
      );
    }
    bytes.addAll(
      _line(
        generator,
        'Service Charge ${(receipt.serviceChargeRate * 100).toStringAsFixed(0)}%',
        Formatters.money(order.serviceCharge),
      ),
    );
    bytes.addAll(
      _line(
        generator,
        'VAT ${(receipt.vatRate * 100).toStringAsFixed(0)}%',
        Formatters.money(order.vat),
      ),
    );
    bytes.addAll(generator.hr(linesAfter: 1));

    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'รวมทั้งสิ้น',
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
        _line(generator, payment.methodLabel, Formatters.money(payment.amount)),
      );
    }
    if (receipt.changeTotal > 0) {
      bytes.addAll(
        _line(generator, 'เงินทอน', Formatters.money(receipt.changeTotal)),
      );
    }

    if (receipt.isRefunded) {
      bytes.addAll(generator.hr(linesAfter: 1));
      bytes.addAll(
        generator.text('รายการคืนเงิน', styles: const PosStyles(bold: true)),
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
          'ยอดสุทธิหลังคืนเงิน',
          Formatters.money(order.total - receipt.refundedTotal),
        ),
      );
    }

    bytes.addAll(generator.feed(1));
    bytes.addAll(
      generator.text(
        'ขอบคุณที่ใช้บริการ',
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
        'ทดสอบเครื่องพิมพ์ PaynEat POS',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'พิมพ์ได้ถูกต้อง แปลว่าตั้งค่าสำเร็จ',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'ทดสอบอักษรไทย: ก-ฮ ๐-๙ ฿100.00',
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
