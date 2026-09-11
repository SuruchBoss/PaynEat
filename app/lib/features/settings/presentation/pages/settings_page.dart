import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/locale_service.dart';
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
                  SectionHeader(
                    title: 'settings_store_info_title'.tr,
                    subtitle: 'settings_store_info_subtitle'.tr,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.storeNameController,
                    decoration: InputDecoration(
                      labelText: 'settings_store_name_label'.tr,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'settings_bill_calc_title'.tr,
                    subtitle: 'settings_bill_calc_subtitle'.tr,
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
                          decoration: InputDecoration(
                            labelText: 'settings_vat_label'.tr,
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
                          decoration: InputDecoration(
                            labelText: 'settings_service_charge_label'.tr,
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
                      title: Text('settings_vat_included_title'.tr),
                      subtitle: Text('settings_vat_included_subtitle'.tr),
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
                                color: AppColors.surface,
                              ),
                            )
                          : Text('settings_save_button'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const _LanguageCard(),
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
                  SectionHeader(title: 'settings_about_title'.tr),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'settings_about_app_label'.tr,
                    value: AppConfig.appName,
                  ),
                  _InfoRow(
                    label: 'settings_about_version_label'.tr,
                    value: '1.0.0',
                  ),
                  _InfoRow(
                    label: 'settings_about_server_label'.tr,
                    value: AppConfig.baseUrl,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// สลับภาษาไทย/อังกฤษของทั้งแอป
class _LanguageCard extends StatefulWidget {
  const _LanguageCard();

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  @override
  Widget build(BuildContext context) {
    final isEnglish = LocaleService.isEnglish;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'settings_language_title'.tr,
            subtitle: 'settings_language_subtitle'.tr,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text('settings_language_th'.tr),
              ),
              ButtonSegment(
                value: true,
                label: Text('settings_language_en'.tr),
              ),
            ],
            selected: {isEnglish},
            onSelectionChanged: (selection) async {
              final wantsEnglish = selection.first;
              await LocaleService.change(
                wantsEnglish
                    ? const Locale('en', 'US')
                    : const Locale('th', 'TH'),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
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
          SectionHeader(
            title: 'settings_printer_title'.tr,
            subtitle: 'settings_printer_subtitle'.tr,
          ),
          const SizedBox(height: 16),
          Obx(
            () => SwitchListTile(
              value: controller.enabled.value,
              onChanged: (value) => controller.enabled.value = value,
              title: Text('settings_printer_enable_title'.tr),
              subtitle: Text('settings_printer_enable_subtitle'.tr),
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
                  decoration: InputDecoration(
                    labelText: 'settings_printer_ip_label'.tr,
                    hintText: 'settings_printer_ip_hint'.tr,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller.portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'settings_printer_port_label'.tr,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 58,
                  label: Text('settings_printer_paper_58mm'.tr),
                ),
                ButtonSegment(
                  value: 80,
                  label: Text('settings_printer_paper_80mm'.tr),
                ),
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
                        : Text('settings_printer_test_button'.tr),
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
                              color: AppColors.surface,
                            ),
                          )
                        : Text('common_save'.tr),
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
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
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
