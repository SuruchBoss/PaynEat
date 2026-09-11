import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
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
      appBar: AppBar(title: Text('payment_checkout_title'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const LoadingView();
        }
        final error = controller.errorMessage.value;
        if (error != null) {
          return ErrorView(message: error, onRetry: controller.load);
        }
        final order = controller.order.value;
        if (order == null) {
          return EmptyView(message: 'payment_order_not_found'.tr);
        }

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

        final shiftBanner = controller.hasOpenShift.value
            ? const <Widget>[]
            : const <Widget>[_NoShiftBanner(), SizedBox(height: 12)];

        return Responsive.isWide(context)
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [...shiftBanner, billCard],
                      ),
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
                  ...shiftBanner,
                  billCard,
                  const SizedBox(height: 12),
                  const _PaymentForm(),
                ],
              );
      }),
    );
  }
}

class _NoShiftBanner extends GetView<CheckoutController> {
  const _NoShiftBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'payment_no_shift_banner'.tr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Get.toNamed<void>(AppRoutes.shift);
              controller.load();
            },
            child: Text('payment_go_open_shift'.tr),
          ),
        ],
      ),
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
        Text(
          'payment_already_paid_section_title'.tr,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
              Text(
                'payment_remaining_due_label'.tr,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.baht(summary.remaining),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.warningInk,
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
          Text(
            'payment_method_section_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.w800),
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
            decoration: InputDecoration(
              labelText: 'payment_amount_this_round_label'.tr,
              helperText: 'payment_amount_this_round_helper'.tr,
              suffixText: 'common_baht'.tr,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          labelText: 'payment_received_label'.tr,
                          helperText: 'payment_received_helper'.tr,
                          suffixText: 'common_baht'.tr,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: Text('payment_exact_amount_label'.tr),
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
                            Text(
                              'payment_change_due_label'.tr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Formatters.baht(controller.change),
                              style: AppTheme.moneyLarge.copyWith(
                                color: AppColors.secondaryInk,
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
                      decoration: InputDecoration(
                        labelText: 'payment_reference_label'.tr,
                        hintText: 'payment_reference_hint'.tr,
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
                        color: AppColors.surface,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                'payment_submit_button'.trParams({
                  'amount': Formatters.baht(controller.amount.value),
                }),
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
