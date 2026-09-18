import '../../domain/entities/ai_assistant_answer.dart';

class AiAssistantAnswerModel extends AiAssistantAnswer {
  const AiAssistantAnswerModel({
    required super.answerText,
    required super.sources,
    required super.remainingToday,
    super.chart,
  });

  factory AiAssistantAnswerModel.fromJson(Map<String, dynamic> json) {
    final chartJson = json['chart'] as Map<String, dynamic>?;
    final sourcesJson = json['sources'] as List? ?? const [];

    return AiAssistantAnswerModel(
      answerText: json['answerText'] as String? ?? '',
      remainingToday: (json['remainingToday'] as num?)?.toInt() ?? 0,
      sources: sourcesJson
          .whereType<Map<String, dynamic>>()
          .map((item) => AiAssistantSource(tool: item['tool'] as String? ?? ''))
          .toList(growable: false),
      chart: chartJson == null
          ? null
          : AiAssistantChart(
              title: chartJson['title'] as String? ?? '',
              points: (chartJson['points'] as List? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (item) => AiAssistantChartPoint(
                      label: item['label'] as String? ?? '',
                      value: (item['value'] as num?)?.toDouble() ?? 0,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}
