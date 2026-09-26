// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/features/home/presentation/bindings/home_binding.dart';

/// เมนูที่แต่ละบทบาทเห็น เป็นกฎด้านสิทธิ์ที่ต้องไม่หลุด จึงต้องมีเทสต์คุม
void main() {
  group('เมนูนำทางตามบทบาท', () {
    // d.label เก็บ "คีย์คำแปล" ดิบไว้ (ไม่ใช่ข้อความไทย) เพราะ HomeDestination
    // เป็น const — เรียก .tr ตอนสร้าง object ไม่ได้ ต้อง resolve ตอนแสดงผลจริง
    test('ครัวเห็นเฉพาะจอครัวกับบัญชีของตัวเอง', () {
      final destinations = HomeBinding.destinationsForRole(UserRole.kitchen);

      expect(destinations.map((d) => d.label), [
        'home_nav_kitchen',
        'home_nav_profile',
      ]);
    });

    test('พนักงานเสิร์ฟไม่เห็นเมนูจัดการร้าน', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.waiter,
      ).map((d) => d.label).toList();

      expect(labels, contains('home_nav_tables'));
      expect(labels, contains('home_nav_orders'));
      expect(labels, isNot(contains('home_nav_staff')));
      expect(labels, isNot(contains('home_nav_reports')));
      expect(labels, isNot(contains('home_nav_settings')));
    });

    // waiter เห็น "ครัว" ด้วยตั้งใจ (mirror สิทธิ์ backend ที่ authorize('kitchen', 'waiter')
    // ให้แก้สถานะอาหารได้ทั้งคู่ ดู order.routes.js) — ต้องมีเทสต์ยืนยันไว้ชัดๆ ไม่ให้หลุดมาจาก
    // wildcard case เงียบๆ เหมือนก่อนหน้านี้
    test('พนักงานเสิร์ฟเห็นจอครัวด้วย', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.waiter,
      ).map((d) => d.label).toList();

      expect(labels, contains('home_nav_kitchen'));
    });

    test(
      'role ที่ไม่รู้จักเห็นแค่บัญชีตัวเอง (fail-safe ไปทางจำกัดสิทธิ์)',
      () {
        final labels = HomeBinding.destinationsForRole(
          'ไม่มี role นี้จริง',
        ).map((d) => d.label).toList();

        expect(labels, ['home_nav_profile']);
      },
    );

    test('แคชเชียร์เห็นรายงานแต่ไม่เห็นการจัดการเมนู', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.cashier,
      ).map((d) => d.label).toList();

      expect(labels, contains('home_nav_reports'));
      expect(labels, isNot(contains('home_nav_menu')));
    });

    test('แอดมินเห็นทุกเมนู', () {
      final labels = HomeBinding.destinationsForRole(
        UserRole.admin,
      ).map((d) => d.label).toList();

      expect(
        labels,
        containsAll([
          'home_nav_dashboard',
          'home_nav_menu',
          'home_nav_staff',
          'home_nav_reports',
          'home_nav_settings',
        ]),
      );
    });

    // เมนูลูกค้า/แต้มสะสม (ดู docs/tickets/09-customer-loyalty.md) — เห็นได้ทั้ง admin
    // และ manager (ต่างจาก audit log ที่จำกัดแค่ admin) เพราะไม่ใช่ข้อมูลอ่อนไหวระดับเดียวกัน
    test(
      'แอดมินและผู้จัดการเห็นเมนูลูกค้า/แต้มสะสม แต่พนักงานเสิร์ฟไม่เห็น',
      () {
        expect(
          HomeBinding.destinationsForRole(UserRole.admin).map((d) => d.label),
          contains('home_nav_customers'),
        );
        expect(
          HomeBinding.destinationsForRole(UserRole.manager).map((d) => d.label),
          contains('home_nav_customers'),
        );
        expect(
          HomeBinding.destinationsForRole(UserRole.waiter).map((d) => d.label),
          isNot(contains('home_nav_customers')),
        );
      },
    );

    // ลูกหนี้/ขายเชื่อ (ดู docs/tickets/20-b2b-credit.md) — mirror ของ receivable.routes.js
    // ที่ให้ admin/manager/cashier รับชำระหนี้ได้ ส่วนพนักงานเสิร์ฟและครัวไม่เกี่ยวกับเงินเชื่อ
    test('เมนูลูกหนี้เห็นเฉพาะ admin/manager/cashier', () {
      for (final role in [UserRole.admin, UserRole.manager, UserRole.cashier]) {
        expect(
          HomeBinding.destinationsForRole(role).map((d) => d.label),
          contains('home_nav_receivables'),
          reason: role,
        );
      }
      for (final role in [UserRole.waiter, UserRole.kitchen]) {
        expect(
          HomeBinding.destinationsForRole(role).map((d) => d.label),
          isNot(contains('home_nav_receivables')),
          reason: role,
        );
      }
    });
  });
}
