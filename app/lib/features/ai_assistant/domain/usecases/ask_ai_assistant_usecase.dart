import '../../../../core/usecases/result.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ai_assistant_answer.dart';
import '../repositories/ai_assistant_repository.dart';

class AskAiAssistantUseCase implements UseCase<AiAssistantAnswer, String> {
  const AskAiAssistantUseCase(this._repository);

  final AiAssistantRepository _repository;

  @override
  Future<Result<AiAssistantAnswer>> call(String question) =>
      _repository.ask(question);
}
