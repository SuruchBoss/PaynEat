import 'locale_service.dart';

/// เลือกชื่อที่จะแสดงจากชุดชื่อหลายภาษาของข้อมูลชิ้นเดียวกัน
///
/// รวมไว้ที่เดียวเพราะเมนู หมวดหมู่ และโซนโต๊ะใช้กติกาเดียวกันเป๊ะ
/// ตอนมีสองภาษาแต่ละ entity เขียนเงื่อนไขของตัวเองซ้ำ ๆ พอเพิ่มภาษาที่ 3
/// ต้องไล่แก้ทุกที่ และจุดที่ลืมจะเงียบ ไม่มีอะไรฟ้อง
class LocalizedName {
  const LocalizedName._();

  /// ลำดับการถอย: ชื่อในภาษาปัจจุบัน → ชื่ออังกฤษ → ชื่อไทย
  ///
  /// ข้อมูลที่ร้านจริงกรอกเองมักมีแค่ [name] (ภาษาที่ร้านพิมพ์) จึงต้องคืน
  /// ค่านั้นเสมอเป็นทางสุดท้าย ห้ามคืนค่าว่างเด็ดขาด
  ///
  /// ชั้นกลาง "ถอยไปอังกฤษ" มีไว้ให้ผู้ใช้ที่อ่านอักษรไทยไม่ออก ได้อักษรละติน
  /// ซึ่งยังพอเดาได้ ดีกว่าได้อักษรไทยที่อ่านไม่ออกเลย
  static String pick({required String name, String? nameEn, String? nameKo}) {
    final own = switch (LocaleService.languageCode) {
      'ko' => nameKo,
      'en' => nameEn,
      _ => null,
    };
    if (own != null && own.isNotEmpty) return own;
    if (LocaleService.prefersLatinNames &&
        nameEn != null &&
        nameEn.isNotEmpty) {
      return nameEn;
    }
    return name;
  }
}
