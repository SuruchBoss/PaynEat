import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../controllers/printer_settings_controller.dart';
import '../controllers/settings_controller.dart';

/// ตั้งค่าร้าน (admin/manager)
class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const LoadingView();

      final error = controller.errorMessage.value;
      if (error != null) {
        return ErrorView(message: error, onRetry: controller.load);
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(
                    title: 'ข้อมูลร้าน',
                    subtitle: 'ชื่อร้านจะแสดงบนใบเสร็จ',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.storeNameController,
                    decoration: const InputDecoration(labelText: 'ชื่อร้าน'),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'การคำนวณบิล',
                    subtitle: 'มีผลกับทุกออเดอร์ที่เปิดใหม่หลังจากนี้',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.vatController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'VAT',
                            suffixText: '%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller.serviceChargeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Service Charge',
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Obx(
                    () => SwitchListTile(
                      value: controller.vatIncluded.value,
                      onChanged: (value) =>
                          controller.vatIncluded.value = value,
                      title: const Text('ราคาเมนูรวม VAT แล้ว'),
                      subtitle: const Text(
                        'ถ้าเปิด ระบบจะถอด VAT ออกมาแสดงแทนการบวกเพิ่ม',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => FilledButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.save,
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('บันทึกการตั้งค่า'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const _PrinterSettingsCard(),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'เกี่ยวกับระบบ'),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'แอปพลิเคชัน', value: AppConfig.appName),
                  _InfoRow(label: 'เวอร์ชัน', value: '1.0.0'),
                  _InfoRow(label: 'เซิร์ฟเวอร์', value: AppConfig.baseUrl),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// ตั้งค่าเครื่องพิมพ์ใบเสร็จของเครื่องนี้ (ไม่ผูกกับร้าน — เก็บในเครื่องเท่านั้น)
class _PrinterSettingsCard extends GetView<PrinterSettingsController> {
  const _PrinterSettingsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'เครื่องพิมพ์ใบเสร็จ',
            subtitle:
                'พิมพ์ผ่านเครื่องพิมพ์ความร้อนบนวง LAN/WiFi เดียวกัน (ยังไม่รองรับบนเว็บ)',
          ),
          const SizedBox(height: 16),
          Obx(
            () => SwitchListTile(
              value: controller.enabled.value,
              onChanged: (value) => controller.enabled.value = value,
              title: const Text('เปิดใช้เครื่องพิมพ์นี้'),
              subtitle: const Text('ปิดไว้ = ใช้ใบเสร็จบนจอเหมือนเดิม'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller.ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP เครื่องพิมพ์',
                    hintText: 'เช่น 192.168.1.50',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller.portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'พอร์ต'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 58, label: Text('58 มม.')),
                ButtonSegment(value: 80, label: Text('80 มม.')),
              ],
              selected: {controller.paperWidthMm.value},
              onSelectionChanged: (selection) =>
                  controller.paperWidthMm.value = selection.first,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => OutlinedButton(
                    onPressed: controller.isTesting.value
                        ? null
                        : controller.testPrint,
                    child: controller.isTesting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ทดสอบพิมพ์'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => FilledButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : controller.save,
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('บันทึก'),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
