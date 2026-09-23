import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:payneat_pos/core/localization/locale_service.dart';
import 'package:payneat_pos/core/utils/formatters.dart';

/// วันครบกำหนดชำระบนหน้าลูกหนี้ (ticket 20) เคยโชว์ "2026-10-11" ตรง ๆ ทุกภาษา
void main() {
  tearDown(() => Get.locale = LocaleService.thai);

  test('แปลงวันที่ล้วนเป็นรูปแบบวันที่ของภาษาปัจจุบัน', () {
    Get.locale = LocaleService.english;
    expect(Formatters.dueDate('2026-10-11'), '11 Oct 2026');

    Get.locale = LocaleService.korean;
    expect(Formatters.dueDate('2026-10-11'), '2026년 10월 11일');
  });

  test('ไม่เลื่อนวันตามโซนเวลาเครื่อง — วันครบกำหนดไม่มีเวลา', () {
    Get.locale = LocaleService.english;
    // ถ้าส่งผ่าน Formatters.parse จะกลายเป็นเที่ยงคืน UTC แล้วแปลงเป็นเวลาเครื่อง
    // เครื่องที่อยู่ฝั่งตะวันตกของ UTC จะได้วันที่ 10 แทน 11
    expect(Formatters.dueDate('2026-10-11'), contains('11'));
    expect(Formatters.dueDate('2026-10-11T00:00:00.000Z'), '11 Oct 2026');
  });

  test('ไม่มีค่า → "-" / อ่านไม่ออก → คืนค่าเดิม ไม่โยน exception', () {
    expect(Formatters.dueDate(null), '-');
    expect(Formatters.dueDate('ไม่ทราบ'), 'ไม่ทราบ');
  });
}
