import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/printing/receipt_printer_service.dart';
import '../../../core/services/printer_settings_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';

/// service พื้นฐานที่ใช้ร่วมกันทุกโดเมน (network client, session, printer) — ผูกก่อน data
/// source/repository/use case ของทุกโดเมนเสมอ เพราะหลายจุดพึ่ง `ApiClient`/`SessionService`
void bindCoreServices(StorageService storage) {
  Get.put<SocketClient>(SocketClient(), permanent: true);
  Get.put<ApiClient>(
    ApiClient(
      tokenProvider: () => storage.token,
      onUnauthorized: () {
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().handleSessionExpired();
        }
      },
    ),
    permanent: true,
  );
  Get.put<SessionService>(
    SessionService(storage: storage, socket: Get.find<SocketClient>()),
    permanent: true,
  );
  Get.put<PrinterSettingsService>(
    PrinterSettingsService(storage: storage),
    permanent: true,
  );
  Get.lazyPut<ReceiptPrinterService>(
    () => ReceiptPrinterService(),
    fenix: true,
  );
}
