import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/customer_usecases.dart';

/// ผลลัพธ์จากกล่องเลือกลูกค้า — เลือกลูกค้า หรือเอาลูกค้าที่ผูกไว้ออก
class CustomerPickerResult {
  const CustomerPickerResult.select(this.customer) : isClear = false;

  const CustomerPickerResult.clear() : customer = null, isClear = true;

  final Customer? customer;
  final bool isClear;
}

/// กล่องค้นหา/เพิ่มลูกค้าใหม่ — ใช้ตอนรับออเดอร์เพื่อผูกลูกค้ากับบิล (optional)
///
/// เรียก usecase ตรง ๆ ผ่าน [Get.find] แทนที่จะมี controller+binding แยก เพราะเป็นแค่
/// การดึงข้อมูลสนับสนุนแบบอ่านอย่างเดียว — รูปแบบเดียวกับที่ menu_form_page.dart และ
/// order_detail_page.dart ใช้กับ ingredient/table usecase
class CustomerPickerDialog extends StatefulWidget {
  const CustomerPickerDialog({super.key, this.currentCustomer});

  final Customer? currentCustomer;

  static Future<CustomerPickerResult?> show({Customer? currentCustomer}) {
    return Get.dialog<CustomerPickerResult>(
      CustomerPickerDialog(currentCustomer: currentCustomer),
    );
  }

  @override
  State<CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<CustomerPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  List<Customer> _results = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _showCreateForm = false;
  String? _errorMessage;

  Timer? _debounce;

  /// ลำดับของคำค้นล่าสุดที่ยิงออกไป — ใช้ทิ้งคำตอบที่มาช้ากว่าคำค้นถัดไป
  /// ไม่งั้นรายชื่อที่เห็นอาจเป็นผลของคำค้นเก่าที่เพิ่งกลับมาทีหลัง
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// ดีบาวซ์ก่อนยิงค้นหาจริง กันยิง API ทุกตัวอักษรที่พิมพ์
  /// ใช้ค่าเดียวกับ CustomersController เพื่อให้ช่องค้นหาลูกค้าสองที่ทำงานเหมือนกัน
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    final seq = ++_searchSeq;
    setState(() {
      _isLoading = true;
      // ต้องล้างทุกครั้งที่เริ่มค้นใหม่ ไม่งั้นพอเน็ตสะดุดครั้งเดียว
      // กล่องจะค้างอยู่ที่หน้า error ตลอด แม้ค้นหารอบถัดไปจะสำเร็จแล้วก็ตาม
      _errorMessage = null;
    });

    final result = await Get.find<SearchCustomersUseCase>()(
      SearchCustomersParams(search: query.trim().isEmpty ? null : query.trim()),
    );

    // คำตอบของคำค้นที่ถูกแทนที่ไปแล้ว ทิ้งทิ้งไปเลย
    if (!mounted || seq != _searchSeq) return;
    result.fold(
      onSuccess: (data) => setState(() {
        _results = data.customers;
        _isLoading = false;
      }),
      onFailure: (failure) => setState(() {
        _errorMessage = failure.message;
        _isLoading = false;
      }),
    );
  }

  Future<void> _createCustomer() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _errorMessage = 'customer_picker_name_phone_required'.tr);
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final result = await Get.find<CreateCustomerUseCase>()(
      CreateCustomerParams(
        name: name,
        phone: phone,
        email: email.isEmpty ? null : email,
      ),
    );

    if (!mounted) return;
    result.fold(
      onSuccess: (customer) =>
          Get.back(result: CustomerPickerResult.select(customer)),
      onFailure: (failure) => setState(() {
        _isCreating = false;
        _errorMessage = failure.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('customer_picker_title'.tr),
      content: SizedBox(
        width: 400,
        child: _showCreateForm ? _buildCreateForm() : _buildSearchView(),
      ),
      actions: [
        if (widget.currentCustomer != null && !_showCreateForm)
          TextButton(
            onPressed: () =>
                Get.back(result: const CustomerPickerResult.clear()),
            child: Text(
              'customer_picker_clear_button'.tr,
              style: TextStyle(color: AppColors.dangerInk),
            ),
          ),
        TextButton(
          onPressed: _showCreateForm
              ? () => setState(() {
                  _showCreateForm = false;
                  _errorMessage = null;
                })
              : () => Get.back<void>(),
          child: Text(_showCreateForm ? 'common_back'.tr : 'common_close'.tr),
        ),
        if (_showCreateForm)
          FilledButton(
            onPressed: _isCreating ? null : _createCustomer,
            child: _isCreating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('customer_picker_create_button'.tr),
          ),
      ],
    );
  }

  Widget _buildSearchView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'customer_picker_search_hint'.tr,
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.dangerInk,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _search(_searchController.text),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('common_retry'.tr),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
              ? Center(
                  child: Text(
                    'customer_picker_empty'.tr,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      trailing: Text(
                        'customer_picker_points_badge'.trParams({
                          'points': '${customer.pointsBalance}',
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => Get.back(
                        result: CustomerPickerResult.select(customer),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () {
            _nameController.text = _searchController.text.trim();
            setState(() {
              _showCreateForm = true;
              _errorMessage = null;
            });
          },
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: Text('customer_picker_add_new_button'.tr),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'customer_picker_name_label'.tr,
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'customer_picker_phone_label'.tr,
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'customer_picker_email_label'.tr,
            isDense: true,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.dangerInk, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
