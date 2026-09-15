import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// รูปเมนู 1 ชิ้น — ใช้ร่วมกันทั้งการ์ดสั่งอาหารและแถวจัดการเมนู
///
/// [imageUrl] รับได้ทั้ง data URL (จากตัวเลือกรูปในฟอร์มเมนู) และ URL ปกติ (http/https)
/// ถ้าไม่มีรูป หรือถอดรหัส/โหลดไม่สำเร็จ จะ fallback ไปที่ [placeholder] ที่ผู้เรียกกำหนดไว้
class MenuItemThumbnail extends StatelessWidget {
  const MenuItemThumbnail({
    super.key,
    required this.imageUrl,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final Widget placeholder;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return placeholder;

    if (url.startsWith('data:')) {
      final bytes = _decodeDataUrl(url);
      if (bytes == null) return placeholder;
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return Image.network(url, fit: fit, errorBuilder: (_, _, _) => placeholder);
  }

  static Uint8List? _decodeDataUrl(String url) {
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      return base64Decode(url.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
