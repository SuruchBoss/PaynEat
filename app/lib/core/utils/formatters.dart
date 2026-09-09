import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// จัดรูปแบบจำนวนเงินและวันที่ให้ตรงกับที่คนไทยอ่านแล้วเข้าใจทันที
class Formatters {
  const Formatters._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compact = NumberFormat('#,##0', 'en_US');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy HH:mm');
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String money(num value) => _money.format(value);

  static String baht(num value) => '฿${_money.format(value)}';

  static String compact(num value) => _compact.format(value);

  /// backend เก็บเวลาเป็น UTC → แปลงเป็นเวลาเครื่องก่อนแสดง
  static DateTime? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.contains('T')
        ? value
        : value.replaceFirst(' ', 'T');
    final withZone = normalized.endsWith('Z') ? normalized : '${normalized}Z';
    return DateTime.tryParse(withZone)?.toLocal();
  }

  static String time(String? value) {
    final date = parse(value);
    return date == null ? '-' : _time.format(date);
  }

  static String dateTime(String? value) {
    final date = parse(value);
    return date == null ? '-' : _dateTime.format(date);
  }

  static String date(DateTime value) => _date.format(value);

  static String isoDate(DateTime value) => _isoDate.format(value);

  /// เวลาที่ผ่านไปแบบอ่านง่าย เช่น "5 นาทีที่แล้ว" — ใช้ในจอครัวเพื่อดูว่าออเดอร์รอนานแค่ไหน
  static String elapsed(String? value) {
    final date = parse(value);
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'common_time_just_now'.tr;
    if (diff.inMinutes < 60) {
      return 'common_time_minutes'.trParams({
        'minutes': diff.inMinutes.toString(),
      });
    }
    if (diff.inHours < 24) {
      return 'common_time_hours_minutes'.trParams({
        'hours': diff.inHours.toString(),
        'minutes': (diff.inMinutes % 60).toString(),
      });
    }
    return 'common_time_days'.trParams({'days': diff.inDays.toString()});
  }

  static int elapsedMinutes(String? value) {
    final date = parse(value);
    if (date == null) return 0;
    return DateTime.now().difference(date).inMinutes;
  }
}
