import 'dart:io';

/// เปิด TCP socket ไปยังเครื่องพิมพ์ความร้อนบนวง LAN/WiFi แล้วส่งคำสั่ง ESC/POS ดิบ
/// (พอร์ต 9100 เป็นค่ามาตรฐานของเครื่องพิมพ์ความร้อนเกือบทุกยี่ห้อ)
Future<void> sendBytes(String ipAddress, int port, List<int> bytes) async {
  final socket = await Socket.connect(
    ipAddress,
    port,
    timeout: const Duration(seconds: 5),
  );
  try {
    socket.add(bytes);
    await socket.flush();
  } finally {
    await socket.close();
  }
}
