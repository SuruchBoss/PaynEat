import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/scanning/camera_barcode_scanner.dart';
import '../../../../core/utils/responsive.dart';

/// ช่องรับรหัสจากเครื่องสแกนบาร์โค้ด — เครื่องสแกน USB/บลูทูธทำตัวเป็นคีย์บอร์ด พิมพ์รหัสแล้วกด
/// Enter เอง จึงใช้ TextField ธรรมดาได้ (ไม่ต้องมีไดรเวอร์) เคลียร์และโฟกัสคืนทุกครั้งหลังสแกน
/// ให้สแกนชิ้นต่อไปได้ทันทีโดยไม่ต้องแตะจอ — จอกว้าง (เคาน์เตอร์) โฟกัสช่องนี้ตั้งแต่เปิดหน้า
/// ส่วนมือถือไม่ออโต้โฟกัส ไม่งั้นคีย์บอร์ดเด้งบังเมนูทุกครั้งที่เข้าหน้า — มือถือ/แท็บเล็ตที่ไม่มีเครื่อง
/// สแกนกดปุ่มกล้องท้ายช่องแทนได้
class BarcodeScanField extends StatefulWidget {
  const BarcodeScanField({
    super.key,
    required this.onScanned,
    this.compact = false,
  });

  final Future<void> Function(String code) onScanned;

  /// จอแคบ — คำใบ้สั้น ("สแกน") ไอคอนเครื่องสแกนบอกความหมายที่เหลือเอง
  final bool compact;

  @override
  State<BarcodeScanField> createState() => _BarcodeScanFieldState();
}

class _BarcodeScanFieldState extends State<BarcodeScanField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    _controller.clear();
    if (value.trim().isEmpty) return;
    await widget.onScanned(value);
    if (mounted) _focusNode.requestFocus();
  }

  /// สแกนด้วยกล้องมือถือ (ticket 22) — รหัสที่ได้เข้าเส้นทางเดียวกับเครื่องสแกนแบบคีย์บอร์ด
  Future<void> _scanWithCamera(CameraBarcodeScanner scanner) async {
    final code = await scanner.scan();
    if (code == null || code.trim().isEmpty) return;
    await widget.onScanned(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scanner = Get.isRegistered<CameraBarcodeScanner>()
        ? Get.find<CameraBarcodeScanner>()
        : null;
    return TextField(
      key: const ValueKey('order-scan-field'),
      controller: _controller,
      focusNode: _focusNode,
      autofocus: Responsive.isWide(context),
      textInputAction: TextInputAction.done,
      onSubmitted: _submit,
      decoration: InputDecoration(
        hintText:
            (widget.compact ? 'order_scan_hint_short' : 'order_scan_hint').tr,
        prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
        suffixIcon: scanner != null && scanner.isSupported
            ? IconButton(
                key: const ValueKey('order-scan-camera'),
                tooltip: 'order_scan_camera_tooltip'.tr,
                icon: const Icon(Icons.photo_camera_outlined),
                onPressed: () => _scanWithCamera(scanner),
              )
            : null,
        isDense: true,
      ),
    );
  }
}
