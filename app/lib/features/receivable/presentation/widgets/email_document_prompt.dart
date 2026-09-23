import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// ค่าที่กรอกตอนส่งเอกสารทางอีเมล
class EmailDocumentInput {
  const EmailDocumentInput({required this.to, this.message});

  final String to;
  final String? message;
}

/// ถามอีเมลผู้รับ (ค่าเริ่มต้น = อีเมลของลูกค้าในบัญชีเครดิต) และข้อความเพิ่มเติมก่อนส่งเอกสารเป็น PDF
/// (ดู docs/tickets/23-document-pdf-email.md) — คืน null ถ้ากดยกเลิก
class EmailDocumentPrompt extends StatefulWidget {
  const EmailDocumentPrompt({
    super.key,
    required this.documentNo,
    this.initialTo,
  });

  final String documentNo;
  final String? initialTo;

  static Future<EmailDocumentInput?> show({
    required String documentNo,
    String? initialTo,
  }) => Get.dialog<EmailDocumentInput>(
    EmailDocumentPrompt(documentNo: documentNo, initialTo: initialTo),
  );

  @override
  State<EmailDocumentPrompt> createState() => _EmailDocumentPromptState();
}

class _EmailDocumentPromptState extends State<EmailDocumentPrompt> {
  late final TextEditingController _to = TextEditingController(
    text: widget.initialTo ?? '',
  );
  final TextEditingController _message = TextEditingController();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _to.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _isValid => _emailPattern.hasMatch(_to.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('receivable_email_title'.trParams({'no': widget.documentNo})),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('email-document-to'),
              controller: _to,
              keyboardType: TextInputType.emailAddress,
              autofocus: widget.initialTo == null,
              decoration: InputDecoration(
                labelText: 'receivable_email_to_label'.tr,
                helperText: widget.initialTo == null
                    ? 'receivable_email_to_help'.tr
                    : null,
                errorText: _to.text.isNotEmpty && !_isValid
                    ? 'customer_credit_email_invalid'.tr
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: 'receivable_email_message_label'.tr,
                hintText: 'receivable_email_message_hint'.tr,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('common_cancel'.tr),
        ),
        FilledButton.icon(
          key: const ValueKey('email-document-send'),
          onPressed: _isValid
              ? () => Get.back(
                  result: EmailDocumentInput(
                    to: _to.text.trim(),
                    message: _message.text.trim(),
                  ),
                )
              : null,
          icon: const Icon(Icons.send_rounded),
          label: Text('receivable_send_email'.tr),
        ),
      ],
    );
  }
}
