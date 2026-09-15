import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/utils/app_clock.dart';

void main() {
  // AppClock เก็บสถานะไว้แบบ static (ใช้ร่วมกันทั้ง process) ถ้าเทสต์ไหนตรึงเวลา
  // ไว้แล้วไม่คืน เวลาที่ตรึงจะรั่วไปถึงเทสต์ตัวถัดไปแบบหาสาเหตุยากมาก
  tearDown(AppClock.unfreeze);

  group('AppClock', () {
    test('ค่าเริ่มต้นใช้นาฬิกาจริงของเครื่อง', () {
      final before = DateTime.now();
      final now = AppClock.now();
      final after = DateTime.now();

      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
    });

    test('freeze ตรึงเวลาไว้ที่จุดเดียว เรียกกี่ครั้งก็ได้ค่าเดิม', () {
      final at = DateTime(2026, 9, 11, 19, 42);
      AppClock.freeze(at);

      expect(AppClock.now(), at);
      expect(AppClock.now(), at);
    });

    test('unfreeze คืนนาฬิกาจริง — เวลาต้องเดินต่อ', () async {
      AppClock.freeze(DateTime(2026, 9, 11, 19, 42));
      AppClock.unfreeze();

      final first = AppClock.now();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(AppClock.now().isAfter(first), isTrue);
    });
  });
}
