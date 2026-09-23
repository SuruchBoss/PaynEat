@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/features/customer/domain/entities/customer.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/receivable/domain/entities/receivable.dart';
import 'package:payneat_pos/features/receivable/domain/repositories/receivable_repository.dart';
import 'package:payneat_pos/features/scale/domain/entities/scale_status.dart';

import 'support/backend_process.dart';
import 'support/pos_device.dart';
import 'support/scenario.dart';

/// ตาชั่งต่อสาย + ดอกเบี้ยผิดนัด + ใบลดหนี้ + PDF/อีเมลเอกสาร (ดู docs/tickets/21–23)
///
/// เทสต์เปิด "ตาชั่ง" เป็น TCP server ของตัวเอง แล้วให้ backend ตัวจริงต่อเข้ามาเหมือนต่อกล่องแปลง
/// Serial→LAN ของร้าน — น้ำหนักวิ่งเส้นทางเดียวกับหน้าร้านจริงทุกช่วง: ตาชั่ง → backend (parser) →
/// socket.io → `ScaleRemoteDataSourceImpl` ของแอป → ตะกร้า → ราคาที่ backend คิด
/// ส่วนอีเมลใช้ MAIL_TRANSPORT=json: nodemailer สร้างอีเมล+PDF แนบครบแต่ไม่ส่งออกไปจริง
void main() {
  late BackendProcess backend;
  late ServerSocket scaleServer;
  final scaleConnections = <Socket>[];
  late PosDevice manager;
  late PosDevice cashier;

  final shop = Scenario();

  late Customer b2b;
  late MenuItem ribeye;
  late Order sale;
  late CreditInvoice invoice;
  late LateFeeCharge charge;
  late CreditNote creditNote;

  setUpAll(() async {
    scaleServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    scaleServer.listen(scaleConnections.add);
    backend = await BackendProcess.start(
      environment: {
        'SCALE_DRIVER': 'tcp',
        'SCALE_TCP_HOST': '127.0.0.1',
        'SCALE_TCP_PORT': '${scaleServer.port}',
        'MAIL_TRANSPORT': 'json',
      },
    );
    manager = PosDevice(backend.apiBaseUrl);
    cashier = PosDevice(backend.apiBaseUrl);
  });

  tearDownAll(() async {
    // ignore: avoid_print
    if (shop.hasFailed) print('──── backend log ────\n${backend.log}');
    cashier.socket.disconnect();
    await backend.stop();
    for (final socket in scaleConnections) {
      socket.destroy();
    }
    await scaleServer.close();
  });

  /// ตาชั่งส่งน้ำหนักหนึ่งบรรทัด (รูปแบบ A&D ที่ตาชั่งจีน/ญี่ปุ่นส่วนใหญ่ใช้)
  void scaleSays(String line) {
    for (final socket in scaleConnections) {
      socket.add(latin1.encode('$line\r\n'));
    }
  }

  Future<ScaleStatus> waitForReading(
    Stream<ScaleStatus> stream,
    bool Function(ScaleReading reading) matches,
  ) => stream
      .firstWhere(
        (status) => status.reading != null && matches(status.reading!),
      )
      .timeout(const Duration(seconds: 10));

  shop.step('ล็อกอิน เปิดกะ และตาชั่งต่อเข้า backend แล้ว', () async {
    await manager.signIn('manager', 'manager123');
    await cashier.signIn('cashier', 'cashier123');
    final leftover = expectOk(await cashier.shifts.getCurrent(), 'กะค้าง');
    if (leftover == null) {
      expectOk(await cashier.shifts.open(500), 'เปิดกะ');
    }

    final deadline = Stopwatch()..start();
    while (scaleConnections.isEmpty) {
      if (deadline.elapsed > const Duration(seconds: 10)) {
        fail('backend ไม่ต่อเข้าตาชั่ง (SCALE_DRIVER=tcp)');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    final found = expectOk(
      await manager.customers.search(search: '021234567'),
      'ลูกค้าเครดิต',
    );
    b2b = found.customers.single;
    final menu = expectOk(
      await cashier.menu.getMenuItems(availableOnly: true),
      'เมนู',
    );
    ribeye = menu.singleWhere((item) => item.scalePlu == '102');
  });

  shop.step(
    'น้ำหนักสดจากตาชั่งวิ่งถึงแอปผ่าน socket.io — ตัวเลขแกว่งใช้ไม่ได้ นิ่งแล้วใช้ได้',
    () async {
      await cashier.connectRealtime(backend.socketUrl);
      final live = cashier.scale.watch().asBroadcastStream();

      scaleSays('US,GS,+0000.470kg');
      final wobbling = await waitForReading(live, (r) => r.grams == 470);
      expect(wobbling.enabled, isTrue);
      expect(wobbling.driver, 'tcp');
      expect(wobbling.reading!.usable, isFalse, reason: 'ยังแกว่งอยู่');

      scaleSays('ST,GS,+0001.250kg');
      final stable = await waitForReading(live, (r) => r.grams == 1250);
      expect(stable.reading!.usable, isTrue);

      // GET /scale ให้ค่าเดียวกัน (แอปเรียกตอนเปิดกล่องชั่งน้ำหนักครั้งแรก)
      final polled = expectOk(await cashier.scale.status(), 'GET /scale');
      expect(polled.connected, isTrue);
      expect(polled.reading?.grams, 1250);

      // ใช้น้ำหนักจากตาชั่งขายเชื่อ — ราคาในตะกร้าตรงกับ backend ทุกสตางค์
      final line = CartLine(
        menuItem: ribeye,
        weightGrams: stable.reading!.grams,
      );
      expect(line.lineTotal, 1500, reason: '1,200 × 1.250');
      final order = expectOk(
        await cashier.orders.createOrder(
          type: 'takeaway',
          customerId: b2b.id,
          guestCount: 1,
          items: cartToPayload([line]),
        ),
        'เปิดบิลจากน้ำหนักตาชั่ง',
      );
      expect(order.items.single.weightGrams, 1250);
      expect(order.items.single.lineTotal, baht(line.lineTotal));
      sale = expectOk(
        await cashier.payments.pay(
          orderId: order.id,
          method: 'credit',
          amount: order.total,
        ),
        'ขายเชื่อ',
      ).order;
    },
  );

  shop.step(
    'ดอกเบี้ยผิดนัด: ตั้ง 12% ผ่อนผัน 5 วัน บิลเลยกำหนด 20 วัน → คิด 15 วัน',
    () async {
      final saved = expectOk(
        await manager.settings.update(
          lateFeeAnnualRatePercent: 12,
          lateFeeGraceDays: 5,
        ),
        'ตั้งอัตราดอกเบี้ย',
      );
      expect(saved.lateFeeAnnualRatePercent, 12);
      expect(saved.emailEnabled, isTrue, reason: 'MAIL_TRANSPORT=json');

      await backend.execSql(
        "UPDATE payments SET due_date = date('now', '-20 days') "
        "WHERE method = 'credit' AND order_id = ${sale.id}",
      );
      final statement = expectOk(
        await cashier.receivables.statement(b2b.id),
        'บัญชีลูกหนี้',
      );
      invoice = statement.invoices.singleWhere((row) => row.orderId == sale.id);
      expect(invoice.isOverdue, isTrue);

      final preview = expectOk(
        await manager.receivables.previewLateFee(b2b.id),
        'ดูดอกเบี้ยก่อนออก',
      );
      final line = preview.items.singleWhere(
        (row) => row.paymentId == invoice.paymentId,
      );
      expect(line.days, 15);
      final expected = (invoice.amount * 100 * 12 * 15 / 36500).round() / 100;
      expect(line.amount, baht(expected));

      final refused = expectFailure(
        await cashier.receivables.createLateFee(b2b.id),
        'แคชเชียร์คิดดอกเบี้ย',
      );
      expect(refused, isA<ForbiddenFailure>());

      charge = expectOk(
        await manager.receivables.createLateFee(b2b.id, note: 'ตามสัญญา'),
        'ออกใบแจ้งดอกเบี้ย',
      );
      expect(charge.chargeNo, startsWith('LF'));
      expect(charge.store?.name, isNotEmpty);
      final after = expectOk(
        await cashier.receivables.statement(b2b.id),
        'บัญชีหลังคิดดอกเบี้ย',
      );
      final charged = after.invoices.singleWhere(
        (row) => row.paymentId == invoice.paymentId,
      );
      expect(charged.interest, baht(charge.total));
      expect(after.lateFees.single.chargeNo, charge.chargeNo);
    },
  );

  shop.step(
    'ลดหนี้บิลขายเชื่อได้ใบลดหนี้ พร้อม VAT ของผลต่าง และยอดค้างลดลง',
    () async {
      final before = expectOk(
        await cashier.receivables.statement(b2b.id),
        'ก่อนลดหนี้',
      ).summary.outstanding;
      creditNote = expectOk(
        await manager.receivables.createCreditNote(
          CreateCreditNoteParams(
            paymentId: invoice.paymentId,
            amount: 107,
            reason: 'เนื้อติดมันเกินสเปก',
          ),
        ),
        'ออกใบลดหนี้',
      );
      expect(creditNote.noteNo, startsWith('CN'));
      expect(creditNote.originalAmount, baht(invoice.amount));
      expect(creditNote.correctAmount, baht(invoice.amount - 107));
      expect(creditNote.vatAmount + creditNote.baseAmount, baht(107));
      final after = expectOk(
        await cashier.receivables.statement(b2b.id),
        'หลังลดหนี้',
      );
      expect(after.summary.outstanding, baht(before - 107));
      expect(after.creditNotes.single.noteNo, creditNote.noteNo);
    },
  );

  shop.step('ดาวน์โหลด PDF เอกสารทุกชนิดได้ไฟล์ PDF จริง', () async {
    final note = expectOk(
      await cashier.receivables.createBillingNote(
        CreateBillingNoteParams(customerId: b2b.id),
      ),
      'ออกใบวางบิล',
    );
    for (final (kind, id) in [
      (ReceivableDocumentKind.billingNote, note.id),
      (ReceivableDocumentKind.creditNote, creditNote.id),
      (ReceivableDocumentKind.lateFee, charge.id),
    ]) {
      final bytes = expectOk(
        await cashier.receivables.downloadPdf(kind, id),
        'PDF ${kind.path}',
      );
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-', reason: kind.path);
    }
  });

  shop.step('ส่งใบวางบิลทางอีเมล: บันทึกประวัติผู้รับ', () async {
    final note = expectOk(
      await cashier.receivables.statement(b2b.id),
      'บัญชีลูกหนี้',
    ).billingNotes.first;
    final refused = expectFailure(
      await cashier.receivables.emailDocument(
        EmailDocumentParams(
          kind: ReceivableDocumentKind.billingNote,
          id: note.id,
        ),
      ),
      'ลูกค้ายังไม่มีอีเมล',
    );
    expect(
      refused,
      isA<ServerFailure>().having((f) => f.statusCode, 'status', 400),
    );

    final emails = expectOk(
      await cashier.receivables.emailDocument(
        EmailDocumentParams(
          kind: ReceivableDocumentKind.billingNote,
          id: note.id,
          to: 'ap@soulbbq.example',
          message: 'รบกวนชำระภายในสิ้นเดือน',
        ),
      ),
      'ส่งอีเมล',
    );
    expect(emails.single.to, 'ap@soulbbq.example');
    expect(emails.single.subject, contains(note.noteNo));
  });
}
