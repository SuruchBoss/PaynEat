// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:payneat_pos/core/errors/failures.dart';
import 'package:payneat_pos/core/usecases/result.dart';
import 'package:payneat_pos/features/ai_assistant/domain/entities/ai_assistant_answer.dart';
import 'package:payneat_pos/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:payneat_pos/features/ai_assistant/domain/usecases/ask_ai_assistant_usecase.dart';
import 'package:payneat_pos/features/ai_assistant/presentation/controllers/ai_assistant_controller.dart';

class _FakeAiAssistantRepository implements AiAssistantRepository {
  Result<AiAssistantAnswer> nextResult = const Result.success(
    AiAssistantAnswer(answerText: 'คำตอบทดสอบ', sources: [], remainingToday: 5),
  );
  Completer<Result<AiAssistantAnswer>>? pending;
  String? lastQuestion;

  @override
  Future<Result<AiAssistantAnswer>> ask(String question) {
    lastQuestion = question;
    if (pending != null) return pending!.future;
    return Future.value(nextResult);
  }
}

void main() {
  // ask() เรียก WidgetsBinding.instance.addPostFrameCallback เพื่อเลื่อนแชทลงล่างสุด —
  // ต้องมี binding ก่อนแม้จะเป็น unit test ล้วนๆ ไม่ได้ pump widget เลยก็ตาม
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAiAssistantRepository repository;
  late AiAssistantController controller;

  setUp(() {
    repository = _FakeAiAssistantRepository();
    controller = AiAssistantController(
      askAiAssistant: AskAiAssistantUseCase(repository),
    );
  });

  tearDown(() => controller.onClose());

  group('AiAssistantController', () {
    test('ask ส่งคำถามที่ trim แล้ว เพิ่ม exchange และเก็บคำตอบ', () async {
      await controller.ask('  ยอดขายวันนี้เท่าไร  ');

      expect(repository.lastQuestion, 'ยอดขายวันนี้เท่าไร');
      expect(controller.exchanges.length, 1);
      expect(controller.exchanges.first.question, 'ยอดขายวันนี้เท่าไร');
      expect(controller.exchanges.first.answer?.answerText, 'คำตอบทดสอบ');
      expect(controller.exchanges.first.isLoading, isFalse);
      expect(controller.remainingToday.value, 5);
      expect(controller.isSending.value, isFalse);
    });

    test('ask ล้าง questionInput หลังเริ่มส่งคำถาม', () async {
      controller.questionInput.text = 'คำถามในกล่อง';

      await controller.ask('คำถามในกล่อง');

      expect(controller.questionInput.text, isEmpty);
    });

    test('ask ไม่ทำอะไรถ้าคำถามว่างหรือมีแต่ช่องว่าง', () async {
      await controller.ask('   ');

      expect(controller.exchanges, isEmpty);
      expect(repository.lastQuestion, isNull);
    });

    test('ask ไม่ทำอะไรถ้าคำถามยาวเกิน maxQuestionLength', () async {
      final tooLong = 'ก' * (AiAssistantController.maxQuestionLength + 1);

      await controller.ask(tooLong);

      expect(controller.exchanges, isEmpty);
    });

    test('ask ไม่ยอมให้ส่งซ้อนกันขณะกำลังรอคำตอบเดิมอยู่', () async {
      repository.pending = Completer<Result<AiAssistantAnswer>>();

      final firstCall = controller.ask('คำถามแรก');
      expect(controller.isSending.value, isTrue);

      await controller.ask('คำถามที่สอง (ต้องถูกเพิกเฉย)');
      expect(
        controller.exchanges.length,
        1,
        reason: 'ต้องมีแค่ exchange เดียวระหว่างที่ยังส่งอยู่',
      );

      repository.pending!.complete(
        const Result.success(
          AiAssistantAnswer(
            answerText: 'ตอบแล้ว',
            sources: [],
            remainingToday: 10,
          ),
        ),
      );
      await firstCall;

      expect(controller.isSending.value, isFalse);
      expect(controller.exchanges.length, 1);
      expect(controller.exchanges.first.question, 'คำถามแรก');
    });

    test(
      'ask ล้มเหลวด้วย ServerFailure → เก็บ errorMessage และ errorCode',
      () async {
        repository.nextResult = const Result.failure(
          ServerFailure(
            'ผู้ช่วย AI ยังไม่ได้เปิดใช้งาน',
            statusCode: 503,
            code: 'AI_ASSISTANT_DISABLED',
          ),
        );

        await controller.ask('คำถามที่ตอบไม่ได้');

        final exchange = controller.exchanges.single;
        expect(exchange.answer, isNull);
        expect(exchange.errorMessage, 'ผู้ช่วย AI ยังไม่ได้เปิดใช้งาน');
        expect(exchange.errorCode, 'AI_ASSISTANT_DISABLED');
        expect(controller.remainingToday.value, isNull);
      },
    );

    test(
      'ask ล้มเหลวด้วย NetworkFailure → เก็บ errorMessage โดยไม่มี errorCode',
      () async {
        repository.nextResult = Result.failure(
          NetworkFailure('ต่อเซิร์ฟเวอร์ไม่ได้'),
        );

        await controller.ask('ยอดขายเดือนนี้');

        final exchange = controller.exchanges.single;
        expect(exchange.errorMessage, 'ต่อเซิร์ฟเวอร์ไม่ได้');
        expect(exchange.errorCode, isNull);
      },
    );
  });
}
