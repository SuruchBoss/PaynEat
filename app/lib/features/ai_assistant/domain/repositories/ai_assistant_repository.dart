// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/usecases/result.dart';
import '../entities/ai_assistant_answer.dart';

abstract class AiAssistantRepository {
  Future<Result<AiAssistantAnswer>> ask(String question);
}
