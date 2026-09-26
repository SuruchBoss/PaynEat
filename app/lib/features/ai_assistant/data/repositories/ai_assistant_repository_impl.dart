// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/usecases/result.dart';
import '../../domain/entities/ai_assistant_answer.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ai_assistant_remote_data_source.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  const AiAssistantRepositoryImpl(this._remote);

  final AiAssistantRemoteDataSource _remote;

  @override
  Future<Result<AiAssistantAnswer>> ask(String question) =>
      guard(() => _remote.ask(question));
}
