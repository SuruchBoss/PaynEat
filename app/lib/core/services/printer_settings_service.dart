import 'dart:convert';

import 'package:get/get.dart';

import '../../features/settings/domain/entities/printer_profile.dart';
import 'storage_service.dart';

/// เก็บและอ่านการตั้งค่าเครื่องพิมพ์ใบเสร็จของ "เครื่องนี้"
///
/// เป็น GetxService เพราะทั้งหน้าตั้งค่าเครื่องพิมพ์และหน้าใบเสร็จต้องอ่านค่าเดียวกัน
/// ต่างจาก [SessionService] ตรงที่ไม่ต้อง login ก่อนอ่าน/เขียนได้ (ผูกกับอุปกรณ์ ไม่ผูกกับ
/// ผู้ใช้) จึงปลอดภัยที่จะสร้างตั้งแต่แอปเริ่ม
class PrinterSettingsService extends GetxService {
  PrinterSettingsService({required StorageService storage})
    : _storage = storage {
    _profile.value = _load();
  }

  final StorageService _storage;
  final Rx<PrinterProfile> _profile = Rx<PrinterProfile>(PrinterProfile.empty);

  PrinterProfile get profile => _profile.value;
  Rx<PrinterProfile> get profileRx => _profile;

  PrinterProfile _load() {
    final raw = _storage.printerProfileJson;
    if (raw == null) return PrinterProfile.empty;
    try {
      return PrinterProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PrinterProfile.empty;
    }
  }

  Future<void> save(PrinterProfile profile) async {
    _profile.value = profile;
    await _storage.savePrinterProfile(jsonEncode(profile.toJson()));
  }
}
