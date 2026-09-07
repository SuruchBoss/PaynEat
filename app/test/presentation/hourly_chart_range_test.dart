import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/features/report/domain/entities/report.dart';
import 'package:payneat_pos/features/report/presentation/widgets/hourly_bar_chart.dart';

/// ช่วงเวลาบนกราฟต้องมาจากยอดขายจริง ไม่ใช่ช่วงที่ตรึงไว้ตายตัว
/// ไม่งั้นร้านที่เปิดเช้ากว่าหรือปิดดึกกว่าค่าเริ่มต้นจะมองไม่เห็นยอดของตัวเอง
void main() {
  HourlySales sale(int hour, double total) =>
      HourlySales(hour: hour, orderCount: 1, total: total);

  group('ช่วงเวลาที่แสดงบนกราฟรายชั่วโมง', () {
    test('ไม่มียอดขายเลย ใช้ช่วงเริ่มต้น 9-22', () {
      final range = HourlyBarChart.visibleRange(const []);

      expect(range.start, 9);
      expect(range.end, 22);
    });

    test('ร้านเปิดดึก (ยอดตอนตี 1-3) ต้องเห็นยอดของตัวเอง', () {
      final range = HourlyBarChart.visibleRange([sale(1, 500), sale(3, 800)]);

      expect(range.start, lessThanOrEqualTo(1));
      expect(range.end, greaterThanOrEqualTo(3));
    });

    test('ร้านเปิดเช้า (ยอดตอน 6 โมง) ต้องเห็นยอดของตัวเอง', () {
      final range = HourlyBarChart.visibleRange([sale(6, 300)]);

      expect(range.start, lessThanOrEqualTo(6));
      expect(range.end, greaterThanOrEqualTo(6));
    });

    test('มียอดชั่วโมงเดียว ยังขยายให้กว้างพออ่านได้', () {
      final range = HourlyBarChart.visibleRange([sale(12, 1000)]);

      expect(
        range.end - range.start,
        greaterThanOrEqualTo(HourlyBarChart.minimumSpan),
      );
    });

    test('ชั่วโมงที่ยอดเป็นศูนย์ไม่ถูกนับเป็นขอบของช่วง', () {
      final range = HourlyBarChart.visibleRange([
        sale(2, 0),
        sale(12, 900),
        sale(23, 0),
      ]);

      expect(range.start, greaterThan(2));
      expect(range.end, lessThan(23));
    });
  });
}
