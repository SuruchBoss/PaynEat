import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// ผลลัพธ์จากกล่องขอใบกำกับภาษี — ไม่มี orderId เพราะผูกกับออเดอร์ปัจจุบันอยู่แล้ว
class TaxInvoiceRequestResult {
  const TaxInvoiceRequestResult({
    required this.invoiceType,
    this.customerName,
    this.customerAddress,
    this.customerTaxId,
  });

  final String invoiceType;
  final String? customerName;
  final String? customerAddress;
  final String? customerTaxId;
}

/// กล่องขอใบกำกับภาษี — เลือกอย่างย่อ/เต็มรูป เต็มรูปต้องกรอกชื่อ+ที่อยู่ลูกค้า
/// (เลขผู้เสียภาษีลูกค้าไม่บังคับ ดู docs/tickets/07-tax-invoice.md)
class TaxInvoiceRequestDialog extends StatefulWidget {
  const TaxInvoiceRequestDialog({super.key});

  static Future<TaxInvoiceRequestResult?> show() {
    return Get.dialog<TaxInvoiceRequestResult>(const TaxInvoiceRequestDialog());
  }

  @override
  State<TaxInvoiceRequestDialog> createState() =>
      _TaxInvoiceRequestDialogState();
}

class _TaxInvoiceRequestDialogState extends State<TaxInvoiceRequestDialog> {
  String _type = TaxInvoiceType.abbreviated;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _submit() {
    final isFull = _type == TaxInvoiceType.full;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    if (isFull && (name.isEmpty || address.isEmpty)) {
      setState(() => _error = 'tax_invoice_full_requires_customer_error'.tr);
      return;
    }

    Get.back(
      result: TaxInvoiceRequestResult(
        invoiceType: _type,
        customerName: isFull ? name : null,
        customerAddress: isFull ? address : null,
        customerTaxId: isFull && _taxIdController.text.trim().isNotEmpty
            ? _taxIdController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFull = _type == TaxInvoiceType.full;
    return AlertDialog(
      title: Text('tax_invoice_request_title'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: TaxInvoiceType.abbreviated,
                  label: Text('tax_invoice_type_abbreviated'.tr),
                ),
                ButtonSegment(
                  value: TaxInvoiceType.full,
                  label: Text('tax_invoice_type_full'.tr),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (values) =>
                  setState(() => _type = values.first),
            ),
            if (isFull) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'tax_invoice_customer_name_label'.tr,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'tax_invoice_customer_address_label'.tr,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _taxIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'tax_invoice_customer_tax_id_label'.tr,
                  hintText: 'tax_invoice_customer_tax_id_hint'.tr,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_cancel'.tr),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text('tax_invoice_request_submit_button'.tr),
        ),
      ],
    );
  }
}
