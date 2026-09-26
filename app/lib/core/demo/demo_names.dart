// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

/// เลือกชื่อตามภาษาให้ข้อมูลสาธิต
///
/// ข้อมูลสาธิตเป็นของเราเอง ไม่ใช่ข้อมูลที่ร้านจริงกรอก จึงแปลได้ทั้งสามภาษา
/// (ฟิลด์ `nameEn` มีมาตั้งแต่แรกด้วยเหตุผลเดียวกัน `nameKo` แค่ทำต่อให้ครบ)
///
/// แยกไฟล์ไว้เพราะ `DemoStore` ต้องใช้ตอน "ประทับชื่อ" ลงรายการอาหารในออเดอร์
/// ซึ่งเป็นชั้นข้อมูล เรียก `Get.locale` ตรง ๆ ไม่ได้ (จะลาก package:get
/// เข้ามาใน core/demo ผิด CODING_STANDARDS §4.1) — ตัวแอปจึงตั้ง [language]
/// ให้แทนเวลาเปลี่ยนภาษา
class DemoNames {
  const DemoNames._();

  /// ภาษาที่ใช้ประทับชื่อลงออเดอร์ใหม่ — ตั้งจาก `LocaleService` ตอนสลับภาษา
  ///
  /// ชื่อที่ประทับไปแล้วไม่ย้อนกลับมาเปลี่ยนตาม เพราะรายการในบิลคือหลักฐาน
  /// ทางการเงิน ต้องคงค่าที่คนกดเห็นตอนสั่ง
  static String language = 'th';

  /// ชื่อของ [row] ในภาษา [lang] (ค่าเริ่มต้นคือภาษาที่ตั้งไว้ใน [language])
  ///
  /// ถอยกลับเป็นไทยเสมอถ้าไม่มีคำแปล — ข้อมูลที่ร้านจริงกรอกเองจะไม่มี
  /// `nameKo`/`nameEn` อยู่แล้ว จึงต้องไม่คืนค่าว่าง
  static String of(
    Map<String, dynamic> row, {
    String? lang,
    String key = 'name',
  }) {
    final code = lang ?? language;
    final translated = switch (code) {
      'ko' => row['${key}Ko'] as String?,
      'en' => row['${key}En'] as String?,
      _ => null,
    };
    if (translated != null && translated.isNotEmpty) return translated;
    // ผู้ใช้ที่อ่านไทยไม่ออกควรได้อักษรละตินมากกว่าอักษรไทยที่อ่านไม่ออกเลย
    if (code != 'th') {
      final latin = row['${key}En'] as String?;
      if (latin != null && latin.isNotEmpty) return latin;
    }
    return row[key] as String? ?? '';
  }
}
