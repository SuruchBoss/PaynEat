import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'storage_service.dart';

/// สลับระดับคอนทราสต์ทั้งแอปและจำค่าไว้ในเครื่อง
///
/// โหมดคอนทราสต์สูงมีไว้สำหรับสภาพหน้างานจริงของร้านอาหาร ไม่ใช่ความชอบส่วนตัว:
/// จอครัวที่โดนไอน้ำ โต๊ะริมหน้าต่างตอนกลางวัน และแท็บเล็ตที่มีรอยนิ้วมือ
/// สภาพพวกนี้กินคอนทราสต์ไปอีกชั้นหนึ่งจากที่วัดได้บนจอสะอาดในร่ม
///
/// ผูกกับ "เครื่อง" ไม่ใช่ "บัญชีผู้ใช้" เหมือนการตั้งค่าภาษาและเครื่องพิมพ์ —
/// แท็บเล็ตหน้าร้านที่โดนแดดควรตั้งคอนทราสต์สูงค้างไว้ ไม่ว่าใครจะมาล็อกอิน
class ContrastService {
  const ContrastService._();

  static const String _highValue = 'high';

  static bool get isHigh => AppColors.isHighContrast;

  /// อ่านค่าที่เคยเลือกไว้กลับมาตอนเปิดแอป — เรียกก่อนสร้าง widget แรกเสมอ
  static void restore() {
    if (!Get.isRegistered<StorageService>()) return;
    final saved = Get.find<StorageService>().contrast;
    AppColors.contrast = saved == _highValue
        ? AppContrast.high
        : AppContrast.standard;
  }

  static Future<void> change(bool high) async {
    AppColors.contrast = high ? AppContrast.high : AppContrast.standard;

    // ธีมถูกสร้างใหม่จาก AppColors ที่เพิ่งเปลี่ยน — ต้องสั่ง GetX ให้ใช้ตัวใหม่
    // ไม่งั้นสีที่ไหลผ่านธีม (AppBar, การ์ด, ช่องกรอก) จะค้างเป็นของโหมดเดิม
    Get.changeTheme(AppTheme.light);

    // สีส่วนใหญ่ในแอปอ่านจาก AppColors ตรง ๆ ไม่ได้ผ่านธีม การเปลี่ยนธีมอย่างเดียว
    // จึงไม่พอ ต้องบังคับให้ทุกหน้าที่ค้างอยู่ใน stack วาดใหม่ด้วย
    Get.forceAppUpdate();

    if (Get.isRegistered<StorageService>()) {
      await Get.find<StorageService>().saveContrast(
        high ? _highValue : 'standard',
      );
    }
  }
}
