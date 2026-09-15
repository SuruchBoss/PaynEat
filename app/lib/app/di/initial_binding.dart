import 'package:get/get.dart';

import '../../core/services/storage_service.dart';
import 'bindings/core_bindings.dart';
import 'bindings/data_source_bindings.dart';
import 'bindings/global_controller_bindings.dart';
import 'bindings/repository_bindings.dart';
import 'bindings/use_case_bindings.dart';

/// ประกอบ dependency ของทั้งแอปไว้ที่เดียว (composition root)
///
/// จุดสำคัญของ Clean Architecture: ชั้นบนรู้จักเฉพาะ abstract ส่วนตัวจริงถูกผูกที่นี่ที่เดียว
/// เปลี่ยนไปใช้ mock หรือ data source อื่นได้โดยไม่ต้องแตะโค้ดหน้าจอเลย
///
/// ใช้ `fenix: true` เพื่อให้ GetX สร้างใหม่อัตโนมัติหากถูกเก็บกวาดไปแล้วมีคนเรียกใช้อีก
///
/// แยกแต่ละขั้นตอนเป็นไฟล์ย่อยใน `bindings/` ตามลำดับที่ต้องผูก (core → data source →
/// repository → use case → global controller — แต่ละชั้นพึ่งชั้นก่อนหน้าผ่าน `Get.find`)
/// แทนที่จะรวมทุกโดเมนไว้ในไฟล์เดียว (ดู `docs/CODING_STANDARDS.md` 2.2)
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.find<StorageService>();

    bindCoreServices(storage);
    bindDataSources();
    bindRepositories(storage);
    bindUseCases();
    bindGlobalControllers();
  }
}
