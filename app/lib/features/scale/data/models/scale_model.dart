import '../../domain/entities/scale_status.dart';

/// แปลง JSON จาก GET /scale และ socket event `scale:reading` (รูปเดียวกัน)
class ScaleModel {
  const ScaleModel._();

  static ScaleStatus fromJson(Map<String, dynamic> json) {
    final reading = json['reading'];
    return ScaleStatus(
      enabled: json['enabled'] as bool? ?? false,
      driver: json['driver'] as String? ?? 'off',
      connected: json['connected'] as bool? ?? false,
      error: json['error'] as String?,
      reading: reading is Map
          ? ScaleReading(
              grams: (reading['grams'] as num?)?.toInt() ?? 0,
              stable: reading['stable'] as bool? ?? false,
              overload: reading['overload'] as bool? ?? false,
              at: DateTime.tryParse(reading['at'] as String? ?? ''),
            )
          : null,
    );
  }
}
