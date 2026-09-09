import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/payment.dart';
import '../controllers/receipt_controller.dart';
import '../widgets/refund_dialog.dart';

/// ใบเสร็จ — จัดวางแบบสลิปจริงเพื่อให้พิมพ์ออกเครื่องพิมพ์ความร้อนได้เลย
class ReceiptPage extends GetView<ReceiptController> {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จรับเงิน'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.isPrinting.value
                  ? null
                  : controller.printReceipt,
              icon: controller.isPrinting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_rounded),
              tooltip: 'พิมพ์ใบเสร็จ',
            ),
          ),
          IconButton(
            onPressed: () => Get.until((route) => route.isFirst),
            icon: const Icon(Icons.home_rounded),
            tooltip: 'กลับหน้าหลัก',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();

        final error = controller.errorMessage.value;
        if (error != null) {
          return ErrorView(message: error, onRetry: controller.load);
        }

        final order = controller.order.value;
        final receipt = controller.receipt.value;
        if (order == null || receipt == null) {
          return const EmptyView(message: 'ไม่พบข้อมูลใบเสร็จ');
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 30,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            receipt.storeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ใบเสร็จรับเงิน / ใบกำกับภาษีอย่างย่อ',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _DashedDivider(),
                    _KeyValue(label: 'เลขที่', value: order.code),
                    _KeyValue(
                      label: 'วันที่',
                      value: Formatters.dateTime(order.closedAt),
                    ),
                    _KeyValue(
                      label: 'โต๊ะ / ประเภท',
                      value: order.displayTarget,
                    ),
                    if (order.waiterName != null)
                      _KeyValue(label: 'พนักงาน', value: order.waiterName!),
                    _KeyValue(
                      label: 'จำนวนลูกค้า',
                      value: '${order.guestCount} ท่าน',
                    ),
                    const _DashedDivider(),
                    for (final item in order.activeItems) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 26,
                              child: Text(
                                '${item.quantity}x',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  if (item.options.isNotEmpty)
                                    Text(
                                      item.optionsSummary,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.money(item.lineTotal),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const _DashedDivider(),
                    _KeyValue(
                      label: 'ยอดรวมอาหาร',
                      value: Formatters.money(order.subtotal),
                    ),
                    if (order.hasDiscount)
                      _KeyValue(
                        label: 'ส่วนลด',
                        value: '-${Formatters.money(order.discountAmount)}',
                      ),
                    _KeyValue(
                      label:
                          'Service Charge ${(receipt.serviceChargeRate * 100).toStringAsFixed(0)}%',
                      value: Formatters.money(order.serviceCharge),
                    ),
                    _KeyValue(
                      label:
                          'VAT ${(receipt.vatRate * 100).toStringAsFixed(0)}%',
                      value: Formatters.money(order.vat),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'รวมทั้งสิ้น',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.baht(order.total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _DashedDivider(),
                    for (final payment in receipt.payments)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              payment.methodLabel,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Formatters.money(payment.amount),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (controller.canRefund &&
                                controller.refundableAmount(payment) > 0) ...[
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showRefundDialog(
                                  context,
                                  controller,
                                  payment,
                                ),
                                child: const Icon(
                                  Icons.assignment_return_outlined,
                                  size: 16,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (receipt.changeTotal > 0)
                      _KeyValue(
                        label: 'เงินทอน',
                        value: Formatters.money(receipt.changeTotal),
                      ),
                    if (receipt.isRefunded) ...[
                      const _DashedDivider(),
                      const Text(
                        'รายการคืนเงิน',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final refund in receipt.refunds)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  refund.reason,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '-${Formatters.money(refund.amount)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      _KeyValue(
                        label: 'ยอดสุทธิหลังคืนเงิน',
                        value: Formatters.money(
                          order.total - receipt.refundedTotal,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'ขอบคุณที่ใช้บริการ 🙏',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Powered by PaynEat POS',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    ReceiptController controller,
    Payment payment,
  ) async {
    final maxAmount = controller.refundableAmount(payment);
    final result = await RefundDialog.show(maxAmount: maxAmount);
    if (result == null) return;
    await controller.submitRefund(
      paymentId: payment.id,
      amount: result.amount,
      reason: result.reason,
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// เส้นประแบบใบเสร็จ
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => const SizedBox(
                width: 4,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.border),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
