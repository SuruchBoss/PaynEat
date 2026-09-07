import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../order/presentation/widgets/bill_summary.dart';
import '../controllers/checkout_controller.dart';

/// หน้าชำระเงิน
class CheckoutPage extends GetView<CheckoutController> {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เก็บเงิน / ปิดบิล')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingView();
        }
        final error = controller.errorMessage.value;
        if (error != null) {
          return ErrorView(message: error, onRetry: controller.load);
        }
        final order = controller.order.value;
        if (order == null) return const EmptyView(message: 'ไม่พบออเดอร์');

        final billCard = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    order.displayTarget,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.code,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BillSummary(order: order, dense: true),
              const SizedBox(height: 12),
              const _PaidHistory(),
            ],
          ),
        );

        return Responsive.isWide(context)
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: billCard,
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: const _PaymentForm(),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  billCard,
                  const SizedBox(height: 12),
                  const _PaymentForm(),
                ],
              );
      }),
    );
  }
}

class _PaidHistory extends GetView<CheckoutController> {
  const _PaidHistory();

  @override
  Widget build(BuildContext context) {
    final summary = controller.summary.value;
    if (summary == null || summary.payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 4),
        const Text(
          'ชำระมาแล้ว',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        for (final payment in summary.payments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  payment.methodLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.money(payment.amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Text(
                'คงเหลือต้องชำระ',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                Formatters.baht(summary.remaining),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentForm extends GetView<CheckoutController> {
  const _PaymentForm();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ช่องทางชำระเงิน',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.all
                  .map((method) {
                    final selected = controller.method.value == method;
                    return ChoiceChip(
                      avatar: Icon(
                        _iconFor(method),
                        size: 16,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      label: Text(PaymentMethod.label(method)),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => controller.selectMethod(method),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceAlt,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: controller.onAmountChanged,
            decoration: const InputDecoration(
              labelText: 'ยอดที่รับชำระรอบนี้',
              suffixText: 'บาท',
            ),
          ),
          Obx(
            () => controller.isCash
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      TextField(
                        controller: controller.receivedController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: controller.onReceivedChanged,
                        decoration: const InputDecoration(
                          labelText: 'รับเงินมา',
                          suffixText: 'บาท',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('พอดี'),
                            onPressed: () =>
                                controller.setReceived(controller.amount.value),
                          ),
                          if (controller.roundedUpSuggestion >
                              controller.remaining)
                            ActionChip(
                              label: Text(
                                Formatters.compact(
                                  controller.roundedUpSuggestion,
                                ),
                              ),
                              onPressed: () => controller.setReceived(
                                controller.roundedUpSuggestion,
                              ),
                            ),
                          ...CheckoutController.quickCashOptions
                              .where((value) => value > controller.amount.value)
                              .map(
                                (value) => ActionChip(
                                  label: Text(Formatters.compact(value)),
                                  onPressed: () =>
                                      controller.setReceived(value),
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'เงินทอน',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Formatters.baht(controller.change),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: controller.referenceController,
                      decoration: const InputDecoration(
                        labelText: 'เลขอ้างอิง (ถ้ามี)',
                        hintText: 'เช่น เลขที่สลิป / 4 ตัวท้ายบัตร',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(0, 52),
              ),
              onPressed: controller.canPay && !controller.isPaying.value
                  ? controller.submit
                  : null,
              icon: controller.isPaying.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                'รับชำระ ${Formatters.baht(controller.amount.value)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String method) => switch (method) {
    PaymentMethod.cash => Icons.payments_rounded,
    PaymentMethod.qr => Icons.qr_code_2_rounded,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.transfer => Icons.account_balance_rounded,
    _ => Icons.payment_rounded,
  };
}
