import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/status_chip.dart';
import '../controllers/ai_assistant_controller.dart';
import '../widgets/ai_assistant_chart_card.dart';

/// หน้าผู้ช่วย AI ถามตอบข้อมูลร้าน — admin/manager เท่านั้น (ดู
/// docs/tickets/15-ai-ask-your-data.md) ทุกคำตอบมาจาก tool-calling กับข้อมูลจริงเท่านั้น
/// เห็นได้จาก chip "แหล่งข้อมูล" ท้ายคำตอบทุกครั้งว่าใช้เครื่องมือไหนตอบ
class AiAssistantPage extends GetView<AiAssistantController> {
  const AiAssistantPage({super.key});

  static const List<String> exampleQuestionKeys = [
    'ai_assistant_example_sales_today',
    'ai_assistant_example_top_items_week',
    'ai_assistant_example_top_customer',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.exchanges.isEmpty) {
                return _EmptyState(onExampleTap: controller.ask);
              }
              return ListView.separated(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.exchanges.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _ExchangeCard(exchange: controller.exchanges[index]),
              );
            }),
          ),
          _InputBar(controller: controller),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExampleTap});

  final void Function(String question) onExampleTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 32,
                color: AppColors.inkOf(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ai_assistant_empty_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'ai_assistant_empty_subtitle'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: AiAssistantPage.exampleQuestionKeys
                  .map((key) {
                    final question = key.tr;
                    return ActionChip(
                      label: Text(
                        question,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      onPressed: () => onExampleTap(question),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller});

  final AiAssistantController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final remaining = controller.remainingToday.value;
              if (remaining == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'ai_assistant_remaining_today'.trParams({
                    'count': remaining.toString(),
                  }),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.questionInput,
                    maxLength: AiAssistantController.maxQuestionLength,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'ai_assistant_input_hint'.tr,
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onSubmitted: controller.ask,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => controller.isSending.value
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton.filled(
                          tooltip: 'ai_assistant_send_button'.tr,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          onPressed: () =>
                              controller.ask(controller.questionInput.text),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({required this.exchange});

  final AiAssistantExchange exchange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                exchange.question,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: _AnswerBubble(exchange: exchange),
          ),
        ),
      ],
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.exchange});

  final AiAssistantExchange exchange;

  @override
  Widget build(BuildContext context) {
    if (exchange.isLoading) {
      return _bubble(
        color: AppColors.surfaceAlt,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'ai_assistant_thinking'.tr,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (exchange.errorCode == 'AI_ASSISTANT_DISABLED') {
      return _bubble(
        color: AppColors.info.withValues(alpha: 0.12),
        borderColor: AppColors.info.withValues(alpha: 0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.inkOf(AppColors.info),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ai_assistant_error_disabled'.tr,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (exchange.errorMessage != null) {
      return _bubble(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderColor: AppColors.danger.withValues(alpha: 0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppColors.dangerInk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exchange.errorMessage!,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final answer = exchange.answer!;
    return _bubble(
      color: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer.answerText, style: const TextStyle(fontSize: 13.5)),
          if (answer.chart != null) ...[
            const SizedBox(height: 10),
            AiAssistantChartCard(chart: answer.chart!),
          ],
          if (answer.sources.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'ai_assistant_sources_label'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                for (final source in answer.sources)
                  StatusChip(
                    label: source.translationKey.tr,
                    color: AppColors.secondary,
                    dense: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bubble({
    required Color color,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        border: borderColor == null ? null : Border.all(color: borderColor),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: child,
    );
  }
}
