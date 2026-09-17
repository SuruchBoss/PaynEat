import '../../../../core/usecases/result.dart';
import '../entities/ai_assistant_answer.dart';

abstract class AiAssistantRepository {
  Future<Result<AiAssistantAnswer>> ask(String question);
}
