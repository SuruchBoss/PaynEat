// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/app/theme/app_colors.dart';
import 'package:payneat_pos/core/widgets/quantity_stepper.dart';
import 'package:payneat_pos/core/widgets/state_views.dart';
import 'package:payneat_pos/core/widgets/status_chip.dart';
import 'package:payneat_pos/features/kitchen/presentation/widgets/kitchen_ticket_card.dart';
import 'package:payneat_pos/features/menu/domain/entities/menu_item.dart';
import 'package:payneat_pos/features/menu/presentation/widgets/menu_item_card.dart';
import 'package:payneat_pos/features/order/domain/entities/order_item.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('QuantityStepper', () {
    testWidgets('กดปุ่มบวก/ลบแล้วส่งค่าใหม่ออกมา', (tester) async {
      var value = 2;

      await tester.pumpWidget(
        wrap(
          StatefulBuilder(
            builder: (context, setState) => QuantityStepper(
              value: value,
              onChanged: (updated) => setState(() => value = updated),
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(value, 3);

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(value, 2);
    });

    testWidgets('ปุ่มลบถูกปิดเมื่อถึงค่าต่ำสุด', (tester) async {
      var changed = false;

      await tester.pumpWidget(
        wrap(QuantityStepper(value: 1, onChanged: (_) => changed = true)),
      );

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      expect(changed, isFalse, reason: 'ค่าต่ำสุดคือ 1 จึงกดลบไม่ได้');
    });
  });

  group('MenuItemCard', () {
    const available = MenuItem(
      id: 1,
      categoryId: 1,
      name: 'ผัดกะเพรา',
      price: 75,
    );
    const soldOut = MenuItem(
      id: 2,
      categoryId: 1,
      name: 'ต้มยำกุ้ง',
      price: 220,
      isAvailable: false,
    );

    testWidgets('แสดงชื่อและราคาของเมนู', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 180,
            height: 220,
            child: MenuItemCard(item: available, onTap: () {}),
          ),
        ),
      );

      expect(find.text('ผัดกะเพรา'), findsOneWidget);
      expect(find.text('฿75.00'), findsOneWidget);
    });

    testWidgets('เมนูที่ปิดขายกดไม่ได้และขึ้นป้ายของหมด', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 180,
            height: 220,
            child: MenuItemCard(
              item: soldOut,
              showAvailabilityBadge: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('ของหมด'), findsOneWidget);

      await tester.tap(find.text('ต้มยำกุ้ง'));
      await tester.pump();
      expect(tapped, isFalse);
    });
  });

  group('สถานะและจอว่าง', () {
    testWidgets('StatusChip แสดงข้อความที่ส่งเข้ามา', (tester) async {
      await tester.pumpWidget(
        wrap(const StatusChip(label: 'กำลังทำ', color: AppColors.primary)),
      );

      expect(find.text('กำลังทำ'), findsOneWidget);
    });

    testWidgets('ErrorView มีปุ่มลองใหม่เมื่อส่ง onRetry เข้ามา', (
      tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        wrap(
          ErrorView(message: 'เชื่อมต่อไม่ได้', onRetry: () => retried = true),
        ),
      );

      expect(find.text('เชื่อมต่อไม่ได้'), findsOneWidget);

      await tester.tap(find.text('ลองใหม่อีกครั้ง'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('EmptyView แสดงข้อความว่าง', (tester) async {
      await tester.pumpWidget(
        wrap(const EmptyView(message: 'ยังไม่มีออเดอร์')),
      );

      expect(find.text('ยังไม่มีออเดอร์'), findsOneWidget);
    });
  });

  group('KitchenTicketCard — แยกป้าย/ไอคอนตามประเภทออเดอร์ (ticket 10)', () {
    OrderItem itemOf({String? tableName, String? orderType}) => OrderItem(
      id: 1,
      orderId: 1,
      name: 'ผัดกะเพรา',
      unitPrice: 60,
      quantity: 1,
      lineTotal: 60,
      status: 'pending',
      tableName: tableName,
      orderType: orderType,
    );

    testWidgets('ออเดอร์ทานที่ร้าน — ขึ้นชื่อโต๊ะและไอคอนโต๊ะ', (tester) async {
      await tester.pumpWidget(
        wrap(
          KitchenTicketCard(
            item: itemOf(tableName: 'A1', orderType: 'dine_in'),
            isLate: false,
            onAdvance: () {},
          ),
        ),
      );

      expect(find.text('โต๊ะ A1'), findsOneWidget);
      expect(find.byIcon(Icons.table_restaurant_rounded), findsOneWidget);
      expect(find.byIcon(Icons.takeout_dining_rounded), findsNothing);
      expect(find.byIcon(Icons.moped_rounded), findsNothing);
    });

    testWidgets(
      'ออเดอร์กลับบ้าน — ขึ้นป้าย "กลับบ้าน" และไอคอนถุง ไม่ใช่ไอคอนโต๊ะ',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            KitchenTicketCard(
              item: itemOf(orderType: 'takeaway'),
              isLate: false,
              onAdvance: () {},
            ),
          ),
        );

        expect(find.text('กลับบ้าน'), findsOneWidget);
        expect(find.byIcon(Icons.takeout_dining_rounded), findsOneWidget);
        expect(find.byIcon(Icons.table_restaurant_rounded), findsNothing);
      },
    );

    testWidgets(
      'ออเดอร์เดลิเวอรี — ขึ้นป้าย "เดลิเวอรี" และไอคอนมอเตอร์ไซค์ แยกจากกลับบ้าน',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            KitchenTicketCard(
              item: itemOf(orderType: 'delivery'),
              isLate: false,
              onAdvance: () {},
            ),
          ),
        );

        expect(find.text('เดลิเวอรี'), findsOneWidget);
        expect(find.byIcon(Icons.moped_rounded), findsOneWidget);
        expect(find.byIcon(Icons.takeout_dining_rounded), findsNothing);
        expect(find.byIcon(Icons.table_restaurant_rounded), findsNothing);
      },
    );
  });
}
