import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/shift.dart';
import '../controllers/shift_controller.dart';

/// หน้าจอเปิด/ปิดกะ — ใช้กระทบยอดเงินสดของแคชเชียร์ก่อน/หลังให้บริการ
class ShiftPage extends GetView<ShiftController> {
  const ShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เปิด / ปิดกะ')),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        final error = controller.errorMessage.value;
        if (error != null) {
          return ErrorView(message: error, onRetry: controller.load);
        }

        final shift = controller.current.value;
        final closed = controller.lastClosed.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (shift != null)
              _OpenShiftCard(shift: shift)
            else if (closed != null)
              _ClosedShiftSummary(shift: closed)
            else
              const _OpenShiftForm(),
            const SizedBox(height: 16),
            _ShiftHistory(),
          ],
        );
      }),
    );
  }
}

class _OpenShiftForm extends GetView<ShiftController> {
  const _OpenShiftForm();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'เปิดกะใหม่',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'กรอกเงินสดตั้งต้นในลิ้นชักก่อนเริ่มรับชำระเงิน',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.openingCashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'เงินตั้งต้น',
              suffixText: 'บาท',
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submitOpen,
              icon: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_open_rounded),
              label: const Text('เปิดกะ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenShiftCard extends GetView<ShiftController> {
  const _OpenShiftCard({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'กะกำลังเปิดอยู่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'เปิดโดย', value: shift.openedByName ?? '-'),
          _InfoRow(
            label: 'เวลาเปิดกะ',
            value: Formatters.dateTime(shift.openedAt),
          ),
          _InfoRow(
            label: 'เงินตั้งต้น',
            value: Formatters.baht(shift.openingCash),
          ),
          const Divider(height: 28),
          const Text(
            'ปิดกะ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'นับเงินสดในลิ้นชักจริงแล้วกรอกยอด ระบบจะคำนวณส่วนต่างให้อัตโนมัติ',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.countedCashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'ยอดเงินสดที่นับได้จริง',
              suffixText: 'บาท',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.noteController,
            decoration: const InputDecoration(labelText: 'หมายเหตุ (ถ้ามี)'),
          ),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size(0, 52),
              ),
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.submitClose,
              icon: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: const Text('ปิดกะ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedShiftSummary extends GetView<ShiftController> {
  const _ClosedShiftSummary({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final variance = shift.variance ?? 0;
    final varianceColor = variance == 0
        ? AppColors.success
        : (variance < 0 ? AppColors.danger : AppColors.warning);
    final varianceLabel = variance == 0
        ? 'ยอดตรงพอดี'
        : (variance < 0 ? 'เงินขาด' : 'เงินเกิน');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'สรุปผลปิดกะ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'เงินตั้งต้น',
            value: Formatters.baht(shift.openingCash),
          ),
          _InfoRow(
            label: 'ยอดที่ระบบคาดไว้',
            value: Formatters.baht(shift.expectedCash ?? 0),
          ),
          _InfoRow(
            label: 'ยอดที่นับได้จริง',
            value: Formatters.baht(shift.countedCash ?? 0),
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: varianceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  varianceLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: varianceColor,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.baht(variance.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: varianceColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: controller.startNewShift,
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('เปิดกะใหม่'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ShiftHistory extends GetView<ShiftController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final history = controller.history;
      if (history.isEmpty) return const SizedBox.shrink();

      return AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'ประวัติกะย้อนหลัง',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final shift in history) _HistoryTile(shift: shift),
            const SizedBox(height: 6),
          ],
        ),
      );
    });
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    final isOpen = shift.isOpen;
    return ListTile(
      leading: Icon(
        isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
        color: isOpen ? AppColors.success : AppColors.textSecondary,
      ),
      title: Text(Formatters.dateTime(shift.openedAt)),
      subtitle: Text(
        isOpen
            ? 'เปิดอยู่ · ${shift.openedByName ?? '-'}'
            : 'ปิดแล้ว · ส่วนต่าง ${Formatters.baht((shift.variance ?? 0).abs())}',
      ),
      trailing: Text(
        Formatters.baht(shift.openingCash),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
