// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_service.dart';

/// ปุ่มสลับภาษาขนาดเล็ก (ลูกโลก + ภาษาปัจจุบัน) สำหรับหน้าที่ยังไม่ได้ล็อกอิน
///
/// เดิมสลับภาษาได้แค่ในหน้าบัญชี/ตั้งค่าหลังล็อกอิน พนักงานเกาหลีจึงต้องอ่านหน้าเข้าสู่ระบบภาษาไทย
/// ก่อน และลูกค้าที่สแกน QR ไม่มีทางเปลี่ยนภาษาเมนูได้เลย (เจอตอนตรวจก่อน UAT แบบไม่มีคนสอน
/// — docs/DECISIONS.md #62) ชื่อภาษาในรายการเขียนด้วยภาษานั้นเอง คนที่อ่านภาษาปัจจุบันไม่ออก
/// ก็ยังหาภาษาของตัวเองเจอ
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, this.foreground});

  /// สีตัวหนังสือ/ไอคอน — ไม่ส่ง = ตามธีม
  final Color? foreground;

  static const _labels = {'th': 'ไทย', 'en': 'English', 'ko': '한국어'};

  @override
  Widget build(BuildContext context) {
    final current = LocaleService.languageCode;
    return PopupMenuButton<String>(
      key: const ValueKey('language-menu'),
      tooltip: 'settings_language_title'.tr,
      initialValue: current,
      onSelected: (code) => LocaleService.change(LocaleService.localeOf(code)),
      itemBuilder: (context) => [
        for (final entry in _labels.entries)
          PopupMenuItem(
            value: entry.key,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: entry.key == current
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(entry.value),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 20, color: foreground),
            const SizedBox(width: 6),
            Text(
              _labels[current] ?? current,
              style: TextStyle(fontWeight: FontWeight.w700, color: foreground),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: foreground),
          ],
        ),
      ),
    );
  }
}
