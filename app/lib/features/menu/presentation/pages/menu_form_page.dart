import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/menu_item_payload.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_option.dart';
import '../controllers/menu_management_controller.dart';
import '../widgets/menu_image_picker_stub.dart'
    if (dart.library.html) '../widgets/menu_image_picker_web.dart'
    as image_picker;
import '../widgets/menu_item_thumbnail.dart';

/// ฟอร์มเพิ่ม/แก้ไขเมนู พร้อมตัวจัดการกลุ่มตัวเลือก
class MenuFormPage extends StatefulWidget {
  const MenuFormPage({super.key});

  @override
  State<MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends State<MenuFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepController = TextEditingController(text: '10');

  final MenuManagementController _controller =
      Get.find<MenuManagementController>();

  MenuItem? _editing;
  int? _categoryId;
  bool _isAvailable = true;
  bool _isRecommended = false;
  final List<MenuOptionGroup> _optionGroups = [];

  /// เก็บเป็น data URL (base64) ตอนเลือกรูปใหม่ หรือ URL เดิมจากเซิร์ฟเวอร์
  /// ค่าเป็น `''` หมายถึง "ผู้ใช้ตั้งใจลบรูป" (ต้องส่งค่านี้จริงไปให้ backend เพราะ
  /// `MenuItemPayload.toJson` จะไม่ส่ง key นี้เลยถ้าเป็น null — ดู menu_item_payload.dart)
  String? _imageUrl;

  bool get _hasImage => _imageUrl != null && _imageUrl!.isNotEmpty;

  static const _maxImageBytes = 1600 * 1024;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _editing = args is Map ? args['item'] as MenuItem? : null;

    final item = _editing;
    if (item != null) {
      _nameController.text = item.name;
      _nameEnController.text = item.nameEn ?? '';
      _descriptionController.text = item.description ?? '';
      _priceController.text = item.price.toStringAsFixed(0);
      _prepController.text = '${item.prepMinutes}';
      _categoryId = item.categoryId;
      _isAvailable = item.isAvailable;
      _isRecommended = item.isRecommended;
      _optionGroups.addAll(item.optionGroups);
      _imageUrl = (item.imageUrl?.isNotEmpty ?? false) ? item.imageUrl : null;
    } else if (_controller.categories.isNotEmpty) {
      _categoryId = _controller.categories.first.id;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await image_picker.pickMenuImage();
      if (picked == null) return;
      if (picked.sizeBytes > _maxImageBytes) {
        AppDialogs.error('menu_form_photo_too_large'.tr);
        return;
      }
      setState(() => _imageUrl = picked.dataUrl);
    } catch (_) {
      AppDialogs.error('menu_form_photo_pick_failed'.tr);
    }
  }

  void _removeImage() => setState(() => _imageUrl = '');

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _categoryId == null) {
      return;
    }

    await _controller.save(
      id: _editing?.id,
      payload: MenuItemPayload(
        name: _nameController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _categoryId!,
        price: double.parse(_priceController.text.trim()),
        prepMinutes: int.tryParse(_prepController.text.trim()) ?? 10,
        imageUrl: _imageUrl,
        isAvailable: _isAvailable,
        isRecommended: _isRecommended,
        optionGroups: _optionGroups,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing == null
              ? 'menu_form_add_title'.tr
              : 'menu_form_edit_title'.tr,
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
                  SectionHeader(title: 'menu_form_info_section'.tr),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: MenuItemThumbnail(
                            imageUrl: _imageUrl,
                            placeholder: Container(
                              color: AppColors.surfaceAlt,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.textDisabled,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'menu_form_photo_label'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (kIsWeb) ...[
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(
                                      Icons.upload_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      _hasImage
                                          ? 'menu_form_photo_change'.tr
                                          : 'menu_form_photo_pick'.tr,
                                    ),
                                  ),
                                  if (_hasImage)
                                    TextButton(
                                      onPressed: _removeImage,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                      ),
                                      child: Text('menu_form_photo_remove'.tr),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'menu_form_photo_hint'.tr,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            ] else
                              Text(
                                'menu_form_photo_web_only'.tr,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textDisabled,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'menu_form_name_label'.tr,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'menu_form_name_required'.tr
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameEnController,
                    decoration: InputDecoration(
                      labelText: 'menu_form_name_en_label'.tr,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: InputDecoration(
                        labelText: 'menu_form_category_label'.tr,
                      ),
                      items: _controller.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(
                                '${category.icon ?? ''} ${category.name}'
                                    .trim(),
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _categoryId = value),
                      validator: (value) => value == null
                          ? 'menu_form_category_required'.tr
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'menu_form_price_label'.tr,
                            suffixText: 'common_baht'.tr,
                          ),
                          validator: (value) {
                            final price = double.tryParse(value?.trim() ?? '');
                            if (price == null || price < 0) {
                              return 'menu_form_price_invalid'.tr;
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _prepController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'menu_form_prep_time_label'.tr,
                            suffixText: 'menu_form_minutes_suffix'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'menu_form_description_label'.tr,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    value: _isAvailable,
                    onChanged: (value) => setState(() => _isAvailable = value),
                    title: Text('menu_form_available_label'.tr),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _isRecommended,
                    onChanged: (value) =>
                        setState(() => _isRecommended = value),
                    title: Text('menu_form_recommended_label'.tr),
                    subtitle: Text('menu_form_recommended_subtitle'.tr),
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
                    title: 'menu_form_option_groups_section'.tr,
                    subtitle: 'menu_form_option_groups_hint'.tr,
                    trailing: TextButton.icon(
                      onPressed: _addGroup,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('menu_form_add_group_button'.tr),
                    ),
                  ),
                  if (_optionGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'menu_form_no_option_groups'.tr,
                          style: const TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final entry in _optionGroups.asMap().entries)
                      _OptionGroupRow(
                        group: entry.value,
                        onRemove: () =>
                            setState(() => _optionGroups.removeAt(entry.key)),
                      ),
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
                            ? 'menu_add_item_button'.tr
                            : 'menu_form_submit_edit'.tr,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGroup() async {
    final result = await Get.dialog<MenuOptionGroup>(
      const _OptionGroupDialog(),
    );
    if (result != null) setState(() => _optionGroups.add(result));
  }
}

class _OptionGroupRow extends StatelessWidget {
  const _OptionGroupRow({required this.group, required this.onRemove});

  final MenuOptionGroup group;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                group.isRequired
                    ? 'menu_option_required_badge'.tr
                    : 'menu_option_max_select_badge'.trParams({
                        'count': '${group.maxSelect}',
                      }),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 17),
                visualDensity: VisualDensity.compact,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: group.options
                .map(
                  (option) => Chip(
                    label: Text(
                      option.priceDelta > 0
                          ? '${option.name} +${option.priceDelta.toStringAsFixed(0)}'
                          : option.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

/// กล่องสร้างกลุ่มตัวเลือกใหม่ พร้อมใส่ตัวเลือกย่อยได้หลายอัน
class _OptionGroupDialog extends StatefulWidget {
  const _OptionGroupDialog();

  @override
  State<_OptionGroupDialog> createState() => _OptionGroupDialogState();
}

class _OptionGroupDialogState extends State<_OptionGroupDialog> {
  final _nameController = TextEditingController();
  final _optionNameController = TextEditingController();
  final _optionPriceController = TextEditingController();
  final List<MenuOption> _options = [];
  bool _isRequired = false;
  int _maxSelect = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _optionNameController.dispose();
    _optionPriceController.dispose();
    super.dispose();
  }

  void _addOption() {
    final name = _optionNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _options.add(
        MenuOption(
          id:
              -(_options.length +
                  1), // id ชั่วคราวฝั่ง client — backend จะออก id จริงให้
          name: name,
          priceDelta: double.tryParse(_optionPriceController.text.trim()) ?? 0,
        ),
      );
      _optionNameController.clear();
      _optionPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('menu_option_group_dialog_title'.tr),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                // rebuild เพื่อให้ปุ่ม "เพิ่มกลุ่ม" เปิด-ปิดตามความถูกต้องของฟอร์มทันที
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'menu_option_group_name_label'.tr,
                  hintText: 'menu_option_group_name_hint'.tr,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: _isRequired,
                      onChanged: (value) =>
                          setState(() => _isRequired = value ?? false),
                      title: Text(
                        'menu_option_required_badge'.tr,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxSelect,
                      decoration: InputDecoration(
                        labelText: 'menu_option_max_select_label'.tr,
                        isDense: true,
                      ),
                      items: [1, 2, 3, 4, 5]
                          .map(
                            (n) =>
                                DropdownMenuItem(value: n, child: Text('$n')),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setState(() => _maxSelect = value ?? 1),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _optionNameController,
                      decoration: InputDecoration(
                        labelText: 'menu_option_name_label'.tr,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _optionPriceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'menu_option_price_delta_label'.tr,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addOption,
                    icon: const Icon(
                      Icons.add_circle_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _options
                    .map(
                      (option) => Chip(
                        label: Text(
                          option.priceDelta > 0
                              ? '${option.name} +${option.priceDelta.toStringAsFixed(0)}'
                              : option.name,
                        ),
                        onDeleted: () =>
                            setState(() => _options.remove(option)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_cancel'.tr),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty || _options.isEmpty
              ? null
              : () => Get.back(
                  result: MenuOptionGroup(
                    id: -1,
                    name: _nameController.text.trim(),
                    minSelect: _isRequired ? 1 : 0,
                    maxSelect: _maxSelect,
                    isRequired: _isRequired,
                    options: _options,
                  ),
                ),
          child: Text('menu_form_add_group_button'.tr),
        ),
      ],
    );
  }
}
