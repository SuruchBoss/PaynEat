// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { getDb } from '../../db/index.js';

export const aiAssistantRepository = {
  /** จำนวนคำถามที่ user นี้ถามไปแล้ววันนี้ (ตามเวลาเซิร์ฟเวอร์) — ใช้คุม rate limit */
  countToday(actorUserId) {
    return getDb()
      .prepare(
        `
        SELECT COUNT(*) AS c
          FROM ai_assistant_queries
         WHERE actor_user_id = ?
           AND date(created_at) = date('now')
      `,
      )
      .get(actorUserId).c;
  },

  log({
    actorUser,
    question,
    answer,
    toolCalls,
    inputTokens = 0,
    outputTokens = 0,
    isError = false,
    errorMessage,
  }) {
    getDb()
      .prepare(
        `
        INSERT INTO ai_assistant_queries
          (actor_user_id, actor_name, question, answer, tool_calls_json,
           input_tokens, output_tokens, is_error, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      )
      .run(
        actorUser?.id,
        actorUser?.name ?? 'ระบบ',
        question,
        answer ?? null,
        JSON.stringify(toolCalls ?? []),
        inputTokens,
        outputTokens,
        isError ? 1 : 0,
        errorMessage ?? null,
      );
  },
};

export default aiAssistantRepository;
