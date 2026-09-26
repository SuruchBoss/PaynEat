// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_assistant_answer.dart';
import '../../domain/usecases/ask_ai_assistant_usecase.dart';

/// หนึ่งรอบถาม-ตอบในเซสชันนี้ — เก็บในหน่วยความจำเท่านั้น backend เก็บ log ไว้แค่สำหรับนับโควตา/
/// ตรวจสอบย้อนหลัง ไม่มี endpoint ให้ดึงประวัติเก่ามาโชว์ (ดู docs/tickets/15-ai-ask-your-data.md)
class AiAssistantExchange {
  AiAssistantExchange({required this.question});

  final String question;
  bool isLoading = true;
  AiAssistantAnswer? answer;
  String? errorMessage;
  String? errorCode;
}

class AiAssistantController extends GetxController {
  AiAssistantController({required AskAiAssistantUseCase askAiAssistant})
    : _askAiAssistant = askAiAssistant;

  final AskAiAssistantUseCase _askAiAssistant;

  static const int maxQuestionLength = 500;

  final TextEditingController questionInput = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<AiAssistantExchange> exchanges = <AiAssistantExchange>[].obs;
  final RxBool isSending = false.obs;

  /// จำนวนคำถามที่เหลือได้ในวันนี้ — อัปเดตจากคำตอบล่าสุด (backend เป็นผู้นับจริง) null จนกว่า
  /// จะถามครั้งแรกสำเร็จ
  final RxnInt remainingToday = RxnInt();

  Future<void> ask(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || question.length > maxQuestionLength) return;
    if (isSending.value) return;

    final exchange = AiAssistantExchange(question: question);
    exchanges.add(exchange);
    questionInput.clear();
    isSending.value = true;
    _scrollToBottomSoon();

    final result = await _askAiAssistant(question);

    exchange.isLoading = false;
    result.fold(
      onSuccess: (answer) {
        exchange.answer = answer;
        remainingToday.value = answer.remainingToday;
      },
      onFailure: (failure) {
        exchange.errorMessage = failure.message;
        if (failure is ServerFailure) exchange.errorCode = failure.code;
      },
    );
    exchanges.refresh();
    isSending.value = false;
    _scrollToBottomSoon();
  }

  /// เลื่อนไปแถวล่างสุดหลังเพิ่มข้อความใหม่ — รอเฟรมถัดไปก่อนเพราะ ListView ยังไม่รู้ความสูงใหม่
  /// จนกว่า build รอบนี้จะเสร็จ
  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onClose() {
    questionInput.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
