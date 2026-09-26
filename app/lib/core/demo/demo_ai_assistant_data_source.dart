// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

part of 'demo_data_sources.dart';

/// โหมดเดโม (static hosting ไม่มี backend/ANTHROPIC_API_KEY จริง) — ตั้งใจไม่ปลอมคำตอบ AI ขึ้นมาเอง
/// เพราะจุดขายของทิกเก็ตนี้คือ "ถามได้จริง ตอบจากข้อมูลร้านจริงผ่าน tool-calling" การปลอมคำตอบไว้ล่วงหน้า
/// จะขัดกับสิ่งที่ฟีเจอร์นี้ตั้งใจพิสูจน์โดยตรง (ดู docs/tickets/15-ai-ask-your-data.md,
/// docs/DECISIONS.md #33) จึงคืน error แบบเดียวกับตอน backend จริงไม่ได้ตั้งค่า ANTHROPIC_API_KEY
/// (statusCode 503, code เดียวกัน) เพื่อให้ชั้น UI จัดการ state นี้ทางเดียวกันทั้งสองกรณี
class DemoAiAssistantDataSource implements AiAssistantRemoteDataSource {
  const DemoAiAssistantDataSource();

  @override
  Future<AiAssistantAnswerModel> ask(String question) => _delayed(() {
    throw ApiException(
      message: 'ai_assistant_error_disabled'.tr,
      statusCode: 503,
      code: 'AI_ASSISTANT_DISABLED',
    );
  });
}
