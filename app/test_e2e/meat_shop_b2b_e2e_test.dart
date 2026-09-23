@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/features/customer/domain/entities/customer.dart';
import 'package:payneat_pos/features/ingredient/domain/entities/ingredient.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/order/domain/entities/cart_line.dart';
import 'package:payneat_pos/features/order/domain/entities/order.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item_payload.dart';
import 'package:payneat_pos/features/order/domain/services/barcode_resolver.dart';
import 'package:payneat_pos/features/order/domain/usecases/order_usecases.dart';
import 'package:payneat_pos/features/order/presentation/widgets/weight_entry_dialog.dart';
import 'package:payneat_pos/features/receivable/domain/entities/receivable.dart';
import 'package:payneat_pos/features/receivable/domain/repositories/receivable_repository.dart';
import 'package:payneat_pos/features/settings/domain/entities/store_settings.dart';
import 'package:payneat_pos/features/shift/domain/entities/shift.dart';

import 'support/backend_process.dart';
import 'support/pos_device.dart';
import 'support/scenario.dart';

/// หน้าร้านเนื้อที่ขายส่งด้วย — ขายตามน้ำหนัก, สแกนฉลากตาชั่ง/บาร์โค้ด, ขายเชื่อลูกค้าเครดิต,
/// วางบิล, รับชำระหนี้เงินสดเข้าลิ้นชัก แล้วปิดกะให้เงินตรง (ดู docs/tickets/18–20)
///
/// ทุกขั้นยิงผ่านโค้ดชั้น data/domain ตัวจริงของแอปไปหา backend ตัวจริง — จุดที่เทสต์อื่นจับไม่ได้:
/// - ราคาสินค้าชั่งน้ำหนักที่แอปโชว์ (`CartLine.lineTotal`) ตรงกับที่ backend คิดทุกสตางค์
/// - ฉลากตาชั่งที่แอปอ่านเอง (`BarcodeResolver`) ใช้รูปแบบเดียวกับที่ backend เก็บในตั้งค่า
/// - JSON ของบิลขายเชื่อ/ใบวางบิล/ใบเสร็จรับชำระ parse เข้า entity ฝั่งแอปได้ครบ
/// - เงินสดที่รับชำระหนี้ถูกนับเข้าลิ้นชักของกะ (ไม่งั้นปิดกะแล้วเงินเกินทุกครั้ง)
void main() {
  late BackendProcess backend;
  late PosDevice manager;
  late PosDevice cashier;
  late PosDevice waiter;

  final shop = Scenario();

  late StoreSettings settings;
  late Customer b2b;
  late List<MenuItem> menu;
  late MenuItem ribeye;
  late MenuItem porkBelly;
  late MenuItem sauce;
  late Shift shift;
  late List<CartLine> cart;
  late Order firstSale;
  late Order secondSale;
  late Map<int, double> stockBefore;
  late BillingNote note;
  late ArReceipt receipt;
  const openingCash = 500.0;

  setUpAll(() async {
    backend = await BackendProcess.start();
    manager = PosDevice(backend.apiBaseUrl);
    cashier = PosDevice(backend.apiBaseUrl);
    waiter = PosDevice(backend.apiBaseUrl);
  });

  tearDownAll(() async {
    // ignore: avoid_print
    if (shop.hasFailed) print('──── backend log ────\n${backend.log}');
    await backend.stop();
  });

  /// ฉลาก EAN-13 ที่ตาชั่งพิมพ์ออกมา — คำนวณ check digit เองในเทสต์ ไม่เรียกโค้ดที่กำลังทดสอบ
  String scaleLabel(String plu, int grams) {
    final digits12 =
        settings.scaleLabelPrefix +
        plu.padLeft(settings.scaleLabelPluDigits, '0') +
        '$grams'.padLeft(
          12 - settings.scaleLabelPrefix.length - settings.scaleLabelPluDigits,
          '0',
        );
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.parse(digits12[i]);
      sum += i.isOdd ? digit * 3 : digit;
    }
    return '$digits12${(10 - sum % 10) % 10}';
  }

  ScaleLabelFormat format() => ScaleLabelFormat(
    prefix: settings.scaleLabelPrefix,
    pluDigits: settings.scaleLabelPluDigits,
  );

  Future<Map<int, double>> stock() async => {
    for (final Ingredient row in expectOk(
      await manager.ingredients.getIngredients(),
      'สต๊อกวัตถุดิบ',
    ))
      row.id: row.currentStock,
  };

  Future<Order> sellOnCredit(List<CartLine> lines, String step) async {
    final order = expectOk(
      await cashier.orders.createOrder(
        type: 'takeaway',
        customerId: b2b.id,
        guestCount: 1,
        items: cartToPayload(lines),
      ),
      '$step: เปิดบิล',
    );
    final paid = expectOk(
      await cashier.payments.pay(
        orderId: order.id,
        method: 'credit',
        amount: order.total,
      ),
      '$step: ขายเชื่อ',
    );
    expect(paid.result.isFullyPaid, isTrue);
    expect(paid.result.payment.isCredit, isTrue);
    return paid.order;
  }

  shop.step('เปิดร้าน: ล็อกอิน เปิดกะ และหาลูกค้าเครดิตที่ seed ไว้', () async {
    await manager.signIn('manager', 'manager123');
    await cashier.signIn('cashier', 'cashier123');
    await waiter.signIn('waiter1', 'waiter123');

    settings = expectOk(await cashier.settings.get(), 'ตั้งค่าร้าน');
    expect(settings.scaleLabelPrefix, '20');
    expect(settings.scaleLabelPluDigits, 5);

    final leftover = expectOk(await cashier.shifts.getCurrent(), 'กะค้าง');
    if (leftover != null) {
      expectOk(
        await cashier.shifts.close(
          leftover.id,
          countedCash: leftover.openingCash,
        ),
        'ปิดกะค้าง',
      );
    }
    shift = expectOk(await cashier.shifts.open(openingCash), 'เปิดกะ');

    final found = expectOk(
      await manager.customers.search(search: '021234567'),
      'ค้นหาลูกค้าเครดิต',
    );
    b2b = found.customers.single;
    expect(b2b.hasCreditAccount, isTrue);
    expect(b2b.creditLimit, baht(50000));
    expect(b2b.creditTermDays, 30);
    expect(b2b.taxId, '0105561234567');
  });

  shop.step(
    'เมนูจาก backend มีสินค้าขายตามน้ำหนัก (PLU) และสินค้ามีบาร์โค้ด',
    () async {
      menu = expectOk(
        await cashier.menu.getMenuItems(availableOnly: true),
        'เมนู',
      );
      ribeye = menu.singleWhere((m) => m.scalePlu == '102');
      porkBelly = menu.singleWhere((m) => m.scalePlu == '101');
      sauce = menu.singleWhere((m) => m.barcode == '8850999320014');

      expect(ribeye.soldByWeight, isTrue);
      expect(ribeye.price, baht(1200), reason: 'ราคาต่อกิโลกรัม');
      expect(porkBelly.soldByWeight, isTrue);
      expect(sauce.soldByWeight, isFalse);
    },
  );

  shop.step(
    'สแกนฉลากตาชั่ง + บาร์โค้ดขวดซอส → ตะกร้าคิดราคาตรงกับ backend ทุกสตางค์',
    () async {
      final weighed = BarcodeResolver.resolve(
        scaleLabel('102', 485),
        menu,
        format: format(),
      );
      expect(weighed, isA<ScannedWeighedItem>());
      final label = weighed as ScannedWeighedItem;
      expect(label.item.id, ribeye.id);
      expect(label.weightGrams, 485);

      final bottle = BarcodeResolver.resolve('8850999320014', menu);
      expect(bottle, isA<ScannedUnitItem>());

      final torn = scaleLabel('102', 485);
      expect(
        BarcodeResolver.resolve(
          '${torn.substring(0, 12)}${(int.parse(torn[12]) + 1) % 10}',
          menu,
          format: format(),
        ),
        isA<ScanBadCheckDigit>(),
      );

      cart = [
        CartLine(menuItem: label.item, weightGrams: label.weightGrams),
        CartLine(menuItem: (bottle as ScannedUnitItem).item, quantity: 2),
      ];
      expect(cart.first.lineTotal, 582, reason: '1,200 × 0.485');

      stockBefore = await stock();
      final order = expectOk(
        await cashier.orders.createOrder(
          type: 'takeaway',
          customerId: b2b.id,
          guestCount: 1,
          items: cartToPayload(cart),
        ),
        'เปิดบิลขายส่ง',
      );
      final meat = order.items.singleWhere((i) => i.menuItemId == ribeye.id);
      expect(meat.weightGrams, 485);
      expect(meat.isWeighed, isTrue);
      expect(meat.quantity, 1);
      expect(meat.lineTotal, baht(cart.first.lineTotal));
      final bottles = order.items.singleWhere((i) => i.menuItemId == sauce.id);
      expect(bottles.lineTotal, baht(cart.last.lineTotal));
      expect(order.subtotal, baht(cart.first.lineTotal + cart.last.lineTotal));
      firstSale = order;
    },
  );

  shop.step('backend ไม่ยอมรับสินค้าชั่งน้ำหนักที่ไม่มีน้ำหนัก', () async {
    final refused = expectFailure(
      await cashier.orders.createOrder(
        type: 'takeaway',
        guestCount: 1,
        items: [OrderItemPayload(menuItemId: ribeye.id, quantity: 1)],
      ),
      'สินค้าชั่งน้ำหนักไม่มีน้ำหนัก',
    );
    expect(
      refused,
      isA<ServerFailure>()
          .having((f) => f.statusCode, 'status', 400)
          .having((f) => f.message, 'message', contains('น้ำหนัก')),
    );
  });

  shop.step(
    'ขายเชื่อเกินวงเงินถูกปฏิเสธ และพนักงานเสิร์ฟขายเชื่อไม่ได้',
    () async {
      expectOk(
        await manager.customers.updateCredit(
          b2b.id,
          CustomerCreditTerms(
            creditLimit: 100,
            creditTermDays: 30,
            taxId: b2b.taxId ?? '',
            address: b2b.address ?? '',
          ),
        ),
        'ลดวงเงินชั่วคราว',
      );
      final overLimit = expectFailure(
        await cashier.payments.pay(
          orderId: firstSale.id,
          method: 'credit',
          amount: firstSale.total,
        ),
        'ขายเชื่อเกินวงเงิน',
      );
      expect(
        overLimit,
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 409),
      );

      expectOk(
        await manager.customers.updateCredit(
          b2b.id,
          CustomerCreditTerms(
            creditLimit: 50000,
            creditTermDays: 30,
            taxId: b2b.taxId ?? '',
            address: b2b.address ?? '',
          ),
        ),
        'คืนวงเงิน',
      );
      final byWaiter = expectFailure(
        await waiter.payments.pay(
          orderId: firstSale.id,
          method: 'credit',
          amount: firstSale.total,
        ),
        'พนักงานเสิร์ฟขายเชื่อ',
      );
      expect(byWaiter, isA<ForbiddenFailure>());
    },
  );

  shop.step(
    'ขายเชื่อปิดบิลได้ ครบกำหนด +30 วัน และตัดสต๊อกเนื้อตามน้ำหนักจริงแม้ไม่ได้ส่งครัว',
    () async {
      final paid = expectOk(
        await cashier.payments.pay(
          orderId: firstSale.id,
          method: 'credit',
          amount: firstSale.total,
        ),
        'ขายเชื่อ',
      );
      expect(paid.result.isFullyPaid, isTrue);
      expect(paid.order.status, 'paid');
      final payment = paid.result.payment;
      expect(payment.isCredit, isTrue);
      final due = DateTime.now().toUtc().add(const Duration(days: 30));
      expect(payment.dueDate, due.toIso8601String().substring(0, 10));

      final ribeyeDetail = expectOk(
        await manager.menu.getMenuItem(ribeye.id),
        'สูตรริบอาย',
      );
      expect(
        ribeyeDetail.ingredients,
        isNotEmpty,
        reason: 'seed ต้องผูกริบอายกับวัตถุดิบ ไม่งั้นขั้นนี้ไม่ได้ตรวจอะไร',
      );
      final after = await stock();
      for (final usage in ribeyeDetail.ingredients) {
        expect(
          after[usage.ingredientId],
          closeTo(
            stockBefore[usage.ingredientId]! - usage.qtyPerUnit * 0.485,
            1e-6,
          ),
          reason: 'ตัดสต๊อก ${usage.ingredientName} เป็นกิโลกรัม',
        );
      }

      final account = expectOk(
        await manager.customers.getById(b2b.id),
        'บัญชีลูกค้า',
      );
      expect(account.creditOutstanding, baht(firstSale.total));
      expect(account.creditAvailable, baht(50000 - firstSale.total));
    },
  );

  shop.step('ชั่งมือ 1.25 กก. แล้วขายเชื่ออีกบิล', () async {
    final grams = WeightEntryDialog.parseGrams('1.25')!;
    secondSale = await sellOnCredit([
      CartLine(menuItem: porkBelly, weightGrams: grams),
    ], 'บิลที่สอง');
    final line = secondSale.items.single;
    expect(line.weightGrams, 1250);
    expect(line.lineTotal, baht(350), reason: '280 × 1.25');
  });

  shop.step(
    'ผู้จัดการออกใบวางบิลรวบสองบิล — ออกซ้ำไม่ได้ และเอกสารมีเลขผู้เสียภาษีของทั้งสองฝ่าย',
    () async {
      final statement = expectOk(
        await manager.receivables.statement(b2b.id),
        'รายการเดินบัญชี',
      );
      expect(statement.openInvoices, hasLength(2));
      expect(statement.unbilledInvoices, hasLength(2));
      expect(
        statement.summary.outstanding,
        baht(firstSale.total + secondSale.total),
      );

      note = expectOk(
        await manager.receivables.createBillingNote(
          CreateBillingNoteParams(customerId: b2b.id),
        ),
        'ออกใบวางบิล',
      );
      expect(note.noteNo, startsWith('BN'));
      expect(note.items.map((line) => line.orderCode).toSet(), {
        firstSale.code,
        secondSale.code,
      });
      expect(note.total, baht(firstSale.total + secondSale.total));
      expect(note.status, BillingNoteStatus.open);
      expect(note.store?.taxId, isNotEmpty);
      expect(note.customer?.taxId, '0105561234567');

      final again = expectFailure(
        await manager.receivables.createBillingNote(
          CreateBillingNoteParams(customerId: b2b.id),
        ),
        'วางบิลซ้ำ',
      );
      expect(
        again,
        isA<ServerFailure>().having((f) => f.statusCode, 'status', 409),
      );
    },
  );

  shop.step(
    'ลูกค้าเอาเงินสดมาจ่ายตามใบวางบิลบางส่วน → ตัดบิลเก่าสุดก่อน',
    () async {
      receipt = expectOk(
        await cashier.receivables.createReceipt(
          CreateReceiptParams(
            customerId: b2b.id,
            amount: firstSale.total,
            method: 'cash',
            billingNoteId: note.id,
          ),
        ),
        'รับชำระหนี้',
      );
      expect(receipt.receiptNo, startsWith('RC'));
      expect(receipt.allocations.single.orderCode, firstSale.code);
      expect(receipt.allocations.single.amount, baht(firstSale.total));

      final doc = expectOk(
        await cashier.receivables.getReceipt(receipt.id),
        'ใบเสร็จรับชำระ',
      );
      expect(doc.customer?.taxId, '0105561234567');
      expect(doc.shiftId, shift.id);

      final after = expectOk(
        await cashier.receivables.getBillingNote(note.id),
        'ใบวางบิลหลังรับเงิน',
      );
      expect(after.remaining, baht(secondSale.total));
      expect(after.total, baht(note.total), reason: 'ยอดบนใบวางบิลคงเดิม');
      expect(after.status, BillingNoteStatus.open);
    },
  );

  shop.step('พนักงานเสิร์ฟดูบัญชีลูกหนี้ไม่ได้', () async {
    expect(
      expectFailure(await waiter.receivables.listCustomers(), 'ลูกหนี้'),
      isA<ForbiddenFailure>(),
    );
  });

  shop.step(
    'ปิดกะ: เงินสดรับชำระหนี้อยู่ในลิ้นชัก — นับตรงแล้วส่วนต่างเป็นศูนย์ และ Z-report แยกให้เห็น',
    () async {
      final inDrawer = openingCash + receipt.amount;
      final closed = expectOk(
        await cashier.shifts.close(shift.id, countedCash: inDrawer),
        'ปิดกะ',
      );
      expect(closed.expectedCash, baht(inDrawer));
      expect(closed.variance, baht(0));

      final z = expectOk(
        await manager.reports.getZReportByShift(shift.id),
        'Z-report',
      );
      final credit = z.paymentMethods.singleWhere((m) => m.method == 'credit');
      expect(credit.amount, baht(firstSale.total + secondSale.total));
      expect(credit.count, 2);
      final collected = z.receivableReceipts.singleWhere(
        (m) => m.method == 'cash',
      );
      expect(collected.amount, baht(receipt.amount));
    },
  );

  shop.step('รายงานสินค้าขายดีบอกน้ำหนักรวมที่ขายได้เป็นกิโลกรัม', () async {
    final top = expectOk(
      await manager.reports.getTopItems(limit: 50),
      'สินค้าขายดี',
    );
    final meat = top.singleWhere((row) => row.menuItemId == ribeye.id);
    expect(meat.weightKg, closeTo(0.485, 1e-9));
    final pork = top.singleWhere((row) => row.menuItemId == porkBelly.id);
    expect(pork.weightKg, closeTo(1.25, 1e-9));
    final bottles = top.singleWhere((row) => row.menuItemId == sauce.id);
    expect(bottles.weightKg, isNull);
    expect(bottles.quantity, 2);
  });
}
