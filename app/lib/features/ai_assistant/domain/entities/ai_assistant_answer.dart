/// จุดข้อมูลหนึ่งจุดในกราฟที่ผู้ช่วย AI แนบมาประกอบคำตอบ (ดู
/// docs/tickets/15-ai-ask-your-data.md — "ตอบได้ทั้งแบบข้อความล้วนและแบบมีกราฟประกอบ")
class AiAssistantChartPoint {
  const AiAssistantChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class AiAssistantChart {
  const AiAssistantChart({required this.title, required this.points});

  final String title;
  final List<AiAssistantChartPoint> points;
}

/// เครื่องมือหนึ่งตัวที่ AI เรียกจริงเพื่อรวบรวมข้อมูลก่อนตอบ — แสดงเป็น "แหล่งข้อมูล" ให้ผู้ใช้
/// ตรวจสอบย้อนกลับได้ว่าคำตอบมาจากไหน ไม่ใช่ AI เดาเอง (acceptance criteria ข้อ 1 ของทิกเก็ต)
class AiAssistantSource {
  const AiAssistantSource({required this.tool});

  final String tool;

  /// mirror ชื่อ tool ฝั่ง backend (ai-assistant.tools.js) — ใช้แปลเป็นป้ายภาษาคนอ่านบนหน้าจอ
  static const Map<String, String> _translationKeys = {
    'get_sales_summary': 'ai_assistant_source_sales_summary',
    'get_top_selling_items': 'ai_assistant_source_top_items',
    'get_sales_by_day': 'ai_assistant_source_sales_by_day',
    'list_recent_orders': 'ai_assistant_source_recent_orders',
    'get_top_customers': 'ai_assistant_source_top_customers',
    'list_audit_log_entries': 'ai_assistant_source_audit_log',
  };

  String get translationKey => _translationKeys[tool] ?? tool;
}

class AiAssistantAnswer {
  const AiAssistantAnswer({
    required this.answerText,
    required this.sources,
    required this.remainingToday,
    this.chart,
  });

  final String answerText;
  final AiAssistantChart? chart;
  final List<AiAssistantSource> sources;
  final int remainingToday;
}
