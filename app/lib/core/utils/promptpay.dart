/// สร้าง payload สำหรับ QR พร้อมเพย์ (PromptPay) ตามมาตรฐาน EMV QRCPS Merchant Presented
/// Mode — mirror ของ `backend/src/core/promptpay.js` ตัวต่อตัว (ต้องแก้คู่กันเสมอถ้าจะแก้
/// อัลกอริทึม ดู docs/DECISIONS.md #2 เรื่องโค้ดคำนวณที่ซ้ำกัน Dart/JS)
///
/// ใช้ตัวนี้เฉพาะตอนอยู่ใน Demo Mode (ไม่มี backend จริงให้เรียก) ส่วนโหมดใช้งานจริงเรียก
/// endpoint `GET /payments/promptpay-qr` แทน เพื่อให้มี source of truth เดียวสำหรับร้านจริง
library;

const _guidPromptPay = 'A000000677010111';

String _tlv(String id, String value) =>
    '$id${value.length.toString().padLeft(2, '0')}$value';

String _sanitizeDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

String _formatTarget(String digits) {
  if (digits.length >= 13) return digits;
  final withCountryCode = digits.replaceFirst(RegExp(r'^0'), '66');
  return ('0000000000000$withCountryCode').substring(
    ('0000000000000$withCountryCode').length - 13,
  );
}

String _targetTagFor(String digits) {
  if (digits.length >= 15) return '03';
  if (digits.length >= 13) return '02';
  return '01';
}

/// CRC-16/CCITT-FALSE (polynomial 0x1021, initial value 0xFFFF, ไม่ reflect, xorout 0)
/// — ทดสอบแล้วตรงกับ test vector มาตรฐานคือ "123456789" → 0x29B1
int crc16Ccitt(String value) {
  var crc = 0xffff;
  for (final codeUnit in value.codeUnits) {
    crc ^= codeUnit << 8;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 0x8000) != 0
          ? ((crc << 1) ^ 0x1021) & 0xffff
          : (crc << 1) & 0xffff;
    }
  }
  return crc;
}

/// สร้าง payload ข้อความสำหรับ QR พร้อมเพย์ — เอาไปเรนเดอร์เป็นภาพ QR ได้เลย (ผ่าน qr_flutter)
/// [amount] ไม่ระบุได้ (static QR ให้ลูกค้ากรอกยอดเอง)
String buildPromptPayPayload({required String promptPayId, double? amount}) {
  final digits = _sanitizeDigits(promptPayId);
  if (digits.isEmpty) {
    throw ArgumentError(
      'promptPayId ต้องเป็นเบอร์โทร/เลขบัตรประชาชน/เลขผู้เสียภาษีของร้าน',
    );
  }
  final targetTag = _targetTagFor(digits);
  final hasAmount = amount != null;

  final parts = [
    _tlv('00', '01'),
    _tlv('01', hasAmount ? '12' : '11'),
    _tlv(
      '29',
      _tlv('00', _guidPromptPay) + _tlv(targetTag, _formatTarget(digits)),
    ),
    _tlv('58', 'TH'),
    _tlv('53', '764'),
    if (hasAmount) _tlv('54', amount.toStringAsFixed(2)),
  ];

  final payloadBeforeCrc = '${parts.join()}6304';
  final crc = crc16Ccitt(
    payloadBeforeCrc,
  ).toRadixString(16).toUpperCase().padLeft(4, '0');
  return payloadBeforeCrc + crc;
}
