import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/menu_item_model.dart';
import '../../domain/entities/menu_item.dart';
import '../../domain/entities/menu_option.dart';
import '../controllers/menu_management_controller.dart';

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

  final MenuManagementController _controller = Get.find<MenuManagementController>();

  MenuItem? _editing;
  int? _categoryId;
  bool _isAvailable = true;
  bool _isRecommended = false;
  final List<MenuOptionGroup> _optionGroups = [];

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
    } else if (_controller.categories.isNotEmpty) {
      _categoryId = _controller.categories.first.id;
    }
  }

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
    if (!(_formKey.currentState?.validate() ?? false) || _categoryId == null) return;

    await _controller.save(
      id: _editing?.id,
      payload: MenuItemPayload(
        name: _nameController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _categoryId!,
        price: double.parse(_priceController.text.trim()),
        prepMinutes: int.tryParse(_prepController.text.trim()) ?? 10,
        isAvailable: _isAvailable,
        isRecommended: _isRecommended,
        optionGroups: _optionGroups,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing == null ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: 'ข้อมูลเมนู'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'ชื่อเมนู *'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'กรุณากรอกชื่อเมนู' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameEnController,
                    decoration: const InputDecoration(labelText: 'ชื่อภาษาอังกฤษ'),
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => DropdownButtonFormField<int>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'หมวดหมู่ *'),
                      items: _controller.categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text('${category.icon ?? ''} ${category.name}'.trim()),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _categoryId = value),
                      validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'ราคา *',
                            suffixText: 'บาท',
                          ),
                          validator: (value) {
                            final price = double.tryParse(value?.trim() ?? '');
                            if (price == null || price < 0) return 'กรุณากรอกราคาให้ถูกต้อง';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _prepController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'เวลาทำ',
                            suffixText: 'นาที',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    value: _isAvailable,
                    onChanged: (value) => setState(() => _isAvailable = value),
                    title: const Text('เปิดขาย'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _isRecommended,
                    onChanged: (value) => setState(() => _isRecommended = value),
                    title: const Text('เมนูแนะนำ'),
                    subtitle: const Text('จะมีป้ายดาวบนจอสั่งอาหาร'),
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
                    title: 'กลุ่มตัวเลือก',
                    subtitle: 'เช่น ระดับความเผ็ด, เพิ่มไข่ดาว',
                    trailing: TextButton.icon(
                      onPressed: _addGroup,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('เพิ่มกลุ่ม'),
                    ),
                  ),
                  if (_optionGroups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'ยังไม่มีกลุ่มตัวเลือก',
                          style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    for (final entry in _optionGroups.asMap().entries)
                      _OptionGroupRow(
                        group: entry.value,
                        onRemove: () => setState(() => _optionGroups.removeAt(entry.key)),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_editing == null ? 'เพิ่มเมนู' : 'บันทึกการแก้ไข'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addGroup() async {
    final result = await Get.dialog<MenuOptionGroup>(const _OptionGroupDialog());
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                group.isRequired ? 'ต้องเลือก' : 'เลือกได้ ${group.maxSelect}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
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
          id: -(_options.length + 1), // id ชั่วคราวฝั่ง client — backend จะออก id จริงให้
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
      title: const Text('เพิ่มกลุ่มตัวเลือก'),
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
                decoration: const InputDecoration(
                  labelText: 'ชื่อกลุ่ม',
                  hintText: 'เช่น ระดับความเผ็ด',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      value: _isRequired,
                      onChanged: (value) => setState(() => _isRequired = value ?? false),
                      title: const Text('ต้องเลือก', style: TextStyle(fontSize: 13.5)),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxSelect,
                      decoration: const InputDecoration(labelText: 'เลือกได้', isDense: true),
                      items: [1, 2, 3, 4, 5]
                          .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _maxSelect = value ?? 1),
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
                      decoration: const InputDecoration(
                        labelText: 'ตัวเลือก',
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
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: const InputDecoration(labelText: '+บาท', isDense: true),
                    ),
                  ),
                  IconButton(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
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
                        onDeleted: () => setState(() => _options.remove(option)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: const Text('ยกเลิก')),
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
          child: const Text('เพิ่มกลุ่ม'),
        ),
      ],
    );
  }
}
