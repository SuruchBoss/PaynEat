import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ai_assistant_answer_model.dart';

abstract class AiAssistantRemoteDataSource {
  Future<AiAssistantAnswerModel> ask(String question);
}

class AiAssistantRemoteDataSourceImpl implements AiAssistantRemoteDataSource {
  const AiAssistantRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<AiAssistantAnswerModel> ask(String question) async {
    final result = await _client.post(
      ApiEndpoints.aiAssistantAsk,
      body: {'question': question},
    );
    return AiAssistantAnswerModel.fromJson(result.asMap);
  }
}
