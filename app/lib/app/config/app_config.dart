import 'package:flutter/foundation.dart';

/// ค่าคอนฟิกระดับแอป — เปลี่ยนได้ตอน build ด้วย
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
class AppConfig {
  const AppConfig._();

  static const String appName = 'PaynEat POS';
  static const String apiVersion = '/api/v1';

  static const String _baseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

  /// URL ของ backend
  /// - Web / iOS simulator / desktop : localhost
  /// - Android emulator              : 10.0.2.2 (loopback ของเครื่อง host)
  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) return _baseUrlFromEnv;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get apiBaseUrl => '$baseUrl$apiVersion';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// เปิด log ของ HTTP request เฉพาะตอน debug
  static bool get enableApiLog => kDebugMode;
}
