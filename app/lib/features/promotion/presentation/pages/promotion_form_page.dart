import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../menu/domain/entities/category.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/domain/usecases/menu_usecases.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/usecases/promotion_usecases.dart';
import '../controllers/promotions_controller.dart';
import '../../../../core/utils/app_clock.dart';

const List<String> _dayLabels = [
  'promotion_day_sun',
  'promotion_day_mon',
  'promotion_day_tue',
  'promotion_day_wed',
  'promotion_day_thu',
  'promotion_day_fri',
  'promotion_day_sat',
];

/// ฟอร์มเพิ่ม/แก้ไขโปรโมชัน พร้อมตั้งเงื่อนไข (วัน/เวลา/เมนู/หมวดหมู่/ยอดขั้นต่ำ)
class PromotionFormPage extends StatefulWidget {
  const PromotionFormPage({super.key});

  @override
  State<PromotionFormPage> createState() => _PromotionFormPageState();
}

class _PromotionFormPageState extends State<PromotionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _codeController = TextEditingController();
  final _minSubtotalController = TextEditingController();

  final PromotionsController _controller = Get.find<PromotionsController>();

  Promotion? _editing;
  String _type = PromotionType.percent;
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validTo;
  final Set<int> _daysOfWeek = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<int> _categoryIds = {};
  final Set<int> _menuItemIds = {};

  bool _loadingOptions = true;
  List<Category> _categories = [];
  List<MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _editing = args is Map ? args['promotion'] as Promotion? : null;

    final promotion = _editing;
    if (promotion != null) {
      _nameController.text = promotion.name;
      _type = promotion.type;
      _valueController.text = promotion.value == promotion.value.roundToDouble()
          ? promotion.value.toStringAsFixed(0)
          : promotion.value.toString();
      _codeController.text = promotion.code ?? '';
      _isActive = promotion.isActive;
      _validFrom = _parseDate(promotion.validFrom);
      _validTo = _parseDate(promotion.validTo);
      _daysOfWeek.addAll(promotion.conditions.daysOfWeek);
      _startTime = _parseTime(promotion.conditions.startTime);
      _endTime = _parseTime(promotion.conditions.endTime);
      _categoryIds.addAll(promotion.conditions.categoryIds);
      _menuItemIds.addAll(promotion.conditions.menuItemIds);
      if (promotion.conditions.minSubtotal > 0) {
        _minSubtotalController.text = promotion.conditions.minSubtotal
            .toStringAsFixed(0);
      }
    }

    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final results = await Future.wait([
      Get.find<GetCategoriesUseCase>()(false),
      Get.find<GetMenuItemsUseCase>()(const MenuFilter()),
    ]);
    setState(() {
      _categories = results[0].dataOrNull as List<Category>? ?? const [];
      _menuItems = results[1].dataOrNull as List<MenuItem>? ?? const [];
      _loadingOptions = false;
    });
  }

  DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value);

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _codeController.dispose();
    _minSubtotalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await _controller.save(
      id: _editing?.id,
      data: PromotionFormData(
        name: _nameController.text.trim(),
        type: _type,
        value: _type == PromotionType.bogo
            ? 0
            : double.tryParse(_valueController.text.trim()) ?? 0,
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim(),
        isActive: _isActive,
        validFrom: _validFrom == null ? null : _formatDate(_validFrom!),
        validTo: _validTo == null ? null : _formatDate(_validTo!),
        conditions: PromotionConditions(
          daysOfWeek: _daysOfWeek.toList(growable: false)..sort(),
          startTime: _startTime == null ? null : _formatTime(_startTime!),
          endTime: _endTime == null ? null : _formatTime(_endTime!),
          categoryIds: _categoryIds.toList(growable: false),
          menuItemIds: _menuItemIds.toList(growable: false),
          minSubtotal: double.tryParse(_minSubtotalController.text.trim()) ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing == null
              ? 'promotion_form_add_title'.tr
              : 'promotion_form_edit_title'.tr,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(title: 'promotion_form_info_section'.tr),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'promotion_form_name_label'.tr,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'promotion_form_name_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<String>(
                    segments: PromotionType.all
                        .map(
                          (type) => ButtonSegment(
                            value: type,
                            label: Text(PromotionType.label(type)),
                          ),
                        )
                        .toList(growable: false),
                    selected: {_type},
                    onSelectionChanged: (values) =>
                        setState(() => _type = values.first),
                  ),
                  if (_type != PromotionType.bogo) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: _type == PromotionType.percent
                            ? 'promotion_form_value_percent_label'.tr
                            : 'promotion_form_value_amount_label'.tr,
                        suffixText: _type == PromotionType.percent
                            ? '%'
                            : 'common_baht'.tr,
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'promotion_form_value_invalid'.tr;
                        }
                        if (_type == PromotionType.percent && parsed > 100) {
                          return 'promotion_form_value_percent_max'.tr;
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'promotion_form_code_label'.tr,
                      hintText: 'promotion_form_code_hint'.tr,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    title: Text('promotion_form_active_label'.tr),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'promotion_form_conditions_section'.tr,
                    subtitle: 'promotion_form_conditions_hint'.tr,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'promotion_form_days_label'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (day) {
                      return FilterChip(
                        label: Text(_dayLabels[day].tr),
                        selected: _daysOfWeek.contains(day),
                        onSelected: (selected) => setState(() {
                          selected
                              ? _daysOfWeek.add(day)
                              : _daysOfWeek.remove(day);
                        }),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TimePickerField(
                          label: 'promotion_form_start_time_label'.tr,
                          value: _startTime,
                          onChanged: (value) =>
                              setState(() => _startTime = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimePickerField(
                          label: 'promotion_form_end_time_label'.tr,
                          value: _endTime,
                          onChanged: (value) =>
                              setState(() => _endTime = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'promotion_form_valid_from_label'.tr,
                          value: _validFrom,
                          onChanged: (value) =>
                              setState(() => _validFrom = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerField(
                          label: 'promotion_form_valid_to_label'.tr,
                          value: _validTo,
                          onChanged: (value) =>
                              setState(() => _validTo = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minSubtotalController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'promotion_form_min_subtotal_label'.tr,
                      suffixText: 'common_baht'.tr,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'promotion_form_categories_label'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'promotion_form_eligibility_hint'.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingOptions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _categories
                          .map(
                            (category) => FilterChip(
                              label: Text(category.displayName),
                              selected: _categoryIds.contains(category.id),
                              onSelected: (selected) => setState(() {
                                selected
                                    ? _categoryIds.add(category.id)
                                    : _categoryIds.remove(category.id);
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'promotion_form_menu_items_label'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _menuItems
                          .map(
                            (item) => FilterChip(
                              label: Text(item.displayName),
                              selected: _menuItemIds.contains(item.id),
                              onSelected: (selected) => setState(() {
                                selected
                                    ? _menuItemIds.add(item.id)
                                    : _menuItemIds.remove(item.id);
                              }),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => FilledButton(
                onPressed: _controller.isSaving.value ? null : _submit,
                child: _controller.isSaving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _editing == null
                            ? 'promotion_add_button'.tr
                            : 'promotion_form_submit_edit'.tr,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.schedule_rounded, size: 18)
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(value == null ? '--:--' : value!.format(context)),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? AppClock.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_rounded, size: 16)
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null
              ? '--'
              : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
