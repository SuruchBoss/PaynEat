import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/scale_status.dart';
import '../../domain/usecases/scale_usecases.dart';

/// น้ำหนักสดจากตาชั่งต่อสาย (ดู docs/tickets/22-live-scale-camera-scan.md) — วางอยู่บนกล่องชั่ง
/// น้ำหนัก ร้านที่ไม่ได้ต่อตาชั่ง (SCALE_DRIVER=off) ไม่เห็นอะไรเลย กรอกเองได้เหมือนเดิม
///
/// ปุ่ม "ใช้น้ำหนักนี้" กดได้เฉพาะตอนตาชั่งบอกว่านิ่งแล้ว — ระหว่างของยังแกว่ง/เกินพิกัด/หลุดการเชื่อมต่อ
/// ห้ามใช้ ไม่งั้นคิดเงินจากตัวเลขที่ยังไม่จริง
class LiveScalePanel extends StatefulWidget {
  const LiveScalePanel({
    super.key,
    required this.onUse,
    required this.pricePreview,
    this.onAvailable,
    this.getStatus,
    this.watch,
  });

  final ValueChanged<int> onUse;

  /// ราคาของน้ำหนักนี้ (คิดด้วยสูตรเดียวกับตะกร้า) เช่น "฿582.00"
  final String Function(int grams) pricePreview;

  /// เรียกครั้งเดียวเมื่อรู้ว่าร้านต่อตาชั่งไว้ — กล่องใช้ปิดคีย์บอร์ดที่เด้งบังตัวเลข
  final VoidCallback? onAvailable;

  /// ฉีดในเทสต์ได้ ไม่ส่งมา = ใช้ตัวที่ผูกไว้ใน DI (ไม่มีทั้งคู่ = ไม่แสดง)
  final GetScaleStatusUseCase? getStatus;
  final WatchScaleUseCase? watch;

  @override
  State<LiveScalePanel> createState() => _LiveScalePanelState();
}

class _LiveScalePanelState extends State<LiveScalePanel> {
  ScaleStatus _status = ScaleStatus.off;
  StreamSubscription<ScaleStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final getStatus =
        widget.getStatus ??
        (Get.isRegistered<GetScaleStatusUseCase>()
            ? Get.find<GetScaleStatusUseCase>()
            : null);
    final watch =
        widget.watch ??
        (Get.isRegistered<WatchScaleUseCase>()
            ? Get.find<WatchScaleUseCase>()
            : null);
    if (getStatus == null || watch == null) return;

    final status = (await getStatus()).dataOrNull;
    if (!mounted || status == null || !status.enabled) return;
    setState(() => _status = status);
    widget.onAvailable?.call();
    _subscription = watch().listen((next) {
      if (mounted) setState(() => _status = next);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_status.enabled) return const SizedBox.shrink();
    final reading = _status.reading;
    final usable = _status.connected && (reading?.usable ?? false);

    final (String message, Color color) = switch (reading) {
      _ when !_status.connected => (
        'scale_live_disconnected'.tr,
        AppColors.dangerInk,
      ),
      null => ('scale_live_waiting'.tr, AppColors.textSecondary),
      ScaleReading(overload: true) => (
        'scale_live_overload'.tr,
        AppColors.dangerInk,
      ),
      ScaleReading(stable: false) => (
        'scale_live_unstable'.tr,
        AppColors.warningInk,
      ),
      ScaleReading(:final grams) when grams <= 0 => (
        'scale_live_empty'.tr,
        AppColors.textSecondary,
      ),
      ScaleReading(:final grams) => (
        'scale_live_stable'.trParams({'price': widget.pricePreview(grams)}),
        AppColors.successInk,
      ),
    };

    return Container(
      key: const ValueKey('live-scale-panel'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: usable ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.scale_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _status.isSimulator
                      ? 'scale_live_title_demo'.tr
                      : 'scale_live_title'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            reading == null || !_status.connected
                ? '—'
                : Formatters.weight(reading.grams < 0 ? 0 : reading.grams),
            key: const ValueKey('live-scale-weight'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          Text(message, style: TextStyle(fontSize: 12.5, color: color)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('live-scale-use'),
              onPressed: usable ? () => widget.onUse(reading!.grams) : null,
              icon: const Icon(Icons.check_rounded),
              label: Text('scale_live_use'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
