// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../domain/entities/customer.dart';

/// ตั้งวงเงินเครดิต/เครดิตเทอม และข้อมูลออกเอกสาร (เลขผู้เสียภาษี/ที่อยู่) ของลูกค้าขายส่ง
/// (ดู docs/tickets/20-b2b-credit.md) — วงเงิน 0 = ปิดการขายเชื่อ แต่หนี้เดิมยังเก็บต่อได้ตามปกติ
class CustomerCreditDialog extends StatefulWidget {
  const CustomerCreditDialog({super.key, required this.customer});

  final Customer customer;

  static Future<CustomerCreditTerms?> show(Customer customer) =>
      Get.dialog<CustomerCreditTerms>(CustomerCreditDialog(customer: customer));

  @override
  State<CustomerCreditDialog> createState() => _CustomerCreditDialogState();
}

class _CustomerCreditDialogState extends State<CustomerCreditDialog> {
  late final TextEditingController _limit = TextEditingController(
    text: widget.customer.creditLimit == 0
        ? ''
        : widget.customer.creditLimit.toStringAsFixed(0),
  );
  late final TextEditingController _term = TextEditingController(
    text: '${widget.customer.creditTermDays}',
  );
  late final TextEditingController _taxId = TextEditingController(
    text: widget.customer.taxId ?? '',
  );
  late final TextEditingController _address = TextEditingController(
    text: widget.customer.address ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.customer.email ?? '',
  );

  @override
  void dispose() {
    _limit.dispose();
    _term.dispose();
    _taxId.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  double? get _limitValue {
    final text = _limit.text.trim();
    if (text.isEmpty) return 0;
    final value = double.tryParse(text);
    return value != null && value >= 0 && value <= 100000000 ? value : null;
  }

  int? get _termValue {
    final value = int.tryParse(_term.text.trim());
    return value != null && value >= 0 && value <= 365 ? value : null;
  }

  bool get _isTaxIdValid {
    final text = _taxId.text.trim();
    return text.isEmpty || RegExp(r'^\d{13}$').hasMatch(text);
  }

  bool get _isEmailValid {
    final text = _email.text.trim();
    return text.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
  }

  bool get _isValid =>
      _limitValue != null &&
      _termValue != null &&
      _isTaxIdValid &&
      _isEmailValid;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('customer_credit_dialog_title'.tr),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('customer-credit-limit'),
                controller: _limit,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'customer_credit_limit_label'.tr,
                  helperText: 'customer_credit_limit_help'.tr,
                  suffixText: 'common_baht'.tr,
                  errorText: _limitValue == null
                      ? 'customer_credit_limit_invalid'.tr
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('customer-credit-term'),
                controller: _term,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'customer_credit_term_label'.tr,
                  suffixText: 'customer_credit_days_suffix'.tr,
                  errorText: _termValue == null
                      ? 'customer_credit_term_invalid'.tr
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taxId,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                ],
                decoration: InputDecoration(
                  labelText: 'customer_credit_tax_id_label'.tr,
                  errorText: _isTaxIdValid
                      ? null
                      : 'customer_credit_tax_id_invalid'.tr,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _address,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'customer_credit_address_label'.tr,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('customer-credit-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'customer_credit_email_label'.tr,
                  helperText: 'customer_credit_email_help'.tr,
                  errorText: _isEmailValid
                      ? null
                      : 'customer_credit_email_invalid'.tr,
                ),
                onChanged: (_) => setState(() {}),
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
          key: const ValueKey('customer-credit-save'),
          onPressed: _isValid
              ? () => Get.back(
                  result: CustomerCreditTerms(
                    creditLimit: _limitValue!,
                    creditTermDays: _termValue!,
                    taxId: _taxId.text.trim(),
                    address: _address.text.trim(),
                    email: _email.text.trim(),
                  ),
                )
              : null,
          child: Text('common_save'.tr),
        ),
      ],
    );
  }
}
