import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/constants/app_constants.dart';
import 'package:payneat_pos/core/network/socket_client.dart';
import 'package:payneat_pos/core/services/session_service.dart';
import 'package:payneat_pos/core/services/storage_service.dart';
import 'package:payneat_pos/features/auth/domain/entities/user.dart';
import 'package:payneat_pos/features/home/presentation/controllers/home_controller.dart';

User _user({String role = UserRole.waiter}) =>
    User(id: 1, name: 'ทดสอบ', username: 'test', role: role, isActive: true);

List<HomeDestination> _destinationsFor(String role) => [
  HomeDestination(
    label: 'หน้าแรก ($role)',
    icon: Icons.home,
    selectedIcon: Icons.home,
    page: const SizedBox.shrink(),
  ),
  HomeDestination(
    label: 'ตั้งค่า',
    icon: Icons.settings,
    selectedIcon: Icons.settings,
    page: const SizedBox.shrink(),
  ),
];

void main() {
  late SessionService session;
  late HomeController controller;

  setUp(() {
    session = SessionService(
      storage: StorageService.memory(),
      socket: SocketClient(),
    );
    controller = HomeController(
      session: session,
      destinationsBuilder: _destinationsFor,
    );
  });

  tearDown(() => controller.onClose());

  group('HomeController', () {
    test('onInit สร้างเมนูตามบทบาทของผู้ใช้ปัจจุบัน', () {
      session.start(
        user: _user(role: UserRole.kitchen),
        token: 't',
      );

      controller.onInit();

      expect(controller.destinations.length, 2);
      expect(controller.destinations.first.label, 'หน้าแรก (kitchen)');
    });

    test('onInit เมื่อยังไม่ล็อกอิน → ใช้บทบาท waiter เป็นค่าเริ่มต้น', () {
      controller.onInit();

      expect(controller.destinations.first.label, 'หน้าแรก (waiter)');
    });

    test('currentTitle คืนป้ายของแท็บที่กำลังเลือกอยู่', () {
      controller.onInit();

      expect(controller.currentTitle, 'หน้าแรก (waiter)');
      controller.changeTab(1);
      expect(controller.currentTitle, 'ตั้งค่า');
    });

    test('changeTab นอกช่วงที่มี → ไม่เปลี่ยนแท็บปัจจุบัน', () {
      controller.onInit();

      controller.changeTab(-1);
      expect(controller.currentIndex.value, 0);

      controller.changeTab(99);
      expect(controller.currentIndex.value, 0);

      controller.changeTab(1);
      expect(controller.currentIndex.value, 1);
    });

    test('greeting คืนคำทักทายที่ไม่ว่างเปล่าเสมอ', () {
      expect(controller.greeting, isNotEmpty);
    });
  });
}
