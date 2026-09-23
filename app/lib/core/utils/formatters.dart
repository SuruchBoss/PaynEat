import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../localization/locale_service.dart';
import 'app_clock.dart';

/// จัดรูปแบบจำนวนเงินและวันที่ให้ตรงกับที่คนไทยอ่านแล้วเข้าใจทันที
class Formatters {
  const Formatters._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compact = NumberFormat('#,##0', 'en_US');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  /// รูปแบบวันที่ต่อภาษา
  ///
  /// ไทยกับอังกฤษใช้ `d MMM yyyy` เหมือนเดิมทุกประการ — จงใจไม่แตะ เพราะรูปแบบนี้
  /// ไปโผล่บนใบเสร็จที่พิมพ์ออกเครื่องจริงและบนภาพ golden ทุกใบ การเปลี่ยนเป็น
  /// เรื่องที่เจ้าของร้านควรตัดสินใจเอง ไม่ใช่ผลพลอยได้ของงานเพิ่มภาษา
  ///
  /// เกาหลีเขียน "2026년 9월 11일" ไม่ใช่ "11 Sep 2026" — ใบเสร็จเกาหลีที่ขึ้นเดือน
  /// เป็นตัวย่อภาษาอังกฤษอ่านแล้วรู้ทันทีว่าเป็นระบบที่แปลมาไม่สุด
  /// (ใช้ตัวอักษรเกาหลีในตัว pattern เลย จึงไม่ต้องโหลด locale data ของ intl)
  static final Map<String, (DateFormat date, DateFormat dateTime)> _formats = {
    'ko': (DateFormat('yyyy년 M월 d일'), DateFormat('yyyy년 M월 d일 HH:mm')),
  };

  static final (DateFormat, DateFormat) _default = (
    DateFormat('d MMM yyyy'),
    DateFormat('d MMM yyyy HH:mm'),
  );

  static (DateFormat, DateFormat) get _current =>
      _formats[LocaleService.languageCode] ?? _default;

  static DateFormat get _date => _current.$1;
  static DateFormat get _dateTime => _current.$2;

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
    final diff = AppClock.now().difference(date);
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
    return AppClock.now().difference(date).inMinutes;
  }
}
