import 'package:get/get.dart';

import '../../features/auth/domain/entities/user.dart';
import '../network/socket_client.dart';
import 'storage_service.dart';

/// เก็บสถานะ "ใครกำลังใช้งานอยู่" ให้ทั้งแอปเข้าถึงได้
///
/// เป็น GetxService เพราะต้องอยู่ตลอดอายุแอป (ไม่ถูกลบทิ้งตอนเปลี่ยนหน้า)
/// และเป็นตัวกลางเดียวที่รู้ทั้ง token, ผู้ใช้ปัจจุบัน และการต่อ socket
class SessionService extends GetxService {
  SessionService({required StorageService storage, required SocketClient socket})
      : _storage = storage,
        _socket = socket;

  final StorageService _storage;
  final SocketClient _socket;

  final Rxn<User> _currentUser = Rxn<User>();

  User? get currentUser => _currentUser.value;
  Rxn<User> get currentUserRx => _currentUser;
  String? get token => _storage.token;
  bool get isLoggedIn => token != null && _currentUser.value != null;
  SocketClient get socket => _socket;

  /// เรียกหลัง login สำเร็จ หรือตอนเปิดแอปแล้วพบเซสชันเดิม
  void start({required User user, required String token}) {
    _currentUser.value = user;
    _socket.connect(token);
  }

  void updateUser(User user) => _currentUser.value = user;

  Future<void> end() async {
    _socket.disconnect();
    _currentUser.value = null;
    await _storage.clear();
  }
}
