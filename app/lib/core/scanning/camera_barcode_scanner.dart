// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme/app_colors.dart';

/// สแกนบาร์โค้ด/ฉลากตาชั่งด้วยกล้อง (ดู docs/tickets/22-live-scale-camera-scan.md)
///
/// เป็น abstract ให้หน้าจอเรียกผ่าน DI — เทสต์วิดเจ็ตใส่ตัวปลอมที่คืนรหัสทันทีแทนการเปิดกล้องจริง
/// รหัสที่ได้ส่งต่อให้ BarcodeResolver ตัวเดียวกับเครื่องสแกนแบบคีย์บอร์ด (ticket 19) กติกาจึงเหมือนกัน
/// ทุกอย่าง (check digit ผิด = ไม่เดาน้ำหนัก ฯลฯ)
abstract class CameraBarcodeScanner {
  /// อุปกรณ์นี้ใช้กล้องสแกนได้ไหม — ไม่ได้ = ซ่อนปุ่มกล้อง (Windows/Linux เดสก์ท็อป)
  bool get isSupported;

  /// เปิดกล้องแล้วคืนรหัสแรกที่อ่านได้ (null = ผู้ใช้ปิดเอง/ใช้กล้องไม่ได้)
  Future<String?> scan();
}

class MobileCameraBarcodeScanner implements CameraBarcodeScanner {
  const MobileCameraBarcodeScanner();

  @override
  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Future<String?> scan() async => await Get.to<String>(
    () => const CameraScanPage(),
    fullscreenDialog: true,
  );
}

/// หน้ากล้องเต็มจอ — อ่านได้รหัสแรกแล้วปิดทันที (สแกนชิ้นต่อไปกดปุ่มกล้องอีกครั้ง)
class CameraScanPage extends StatefulWidget {
  const CameraScanPage({super.key});

  /// รูปแบบที่ใช้จริงหน้าร้าน — จำกัดไว้ให้กล้องหาเร็วขึ้นและไม่อ่านโค้ดอื่นที่ไม่เกี่ยวติดมา
  static const List<BarcodeFormat> formats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.qrCode,
  ];

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: CameraScanPage.formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;
      _done = true;
      HapticFeedback.mediumImpact();
      Get.back(result: code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('scan_camera_title'.tr),
        actions: [
          IconButton(
            tooltip: 'scan_camera_torch'.tr,
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'scan_camera_hint'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'scan_camera_denied'.tr
        : 'scan_camera_unavailable'.tr;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
