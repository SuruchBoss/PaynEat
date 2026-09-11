// PaynEat POS — original project by SuruchBoss (https://github.com/SuruchBoss/PaynEat)
// Licensed under Apache License 2.0 — see LICENSE and NOTICE at repo root
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/app.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // storage ต้องพร้อมก่อนสร้างแอป เพราะ InitialBinding ต้องใช้อ่าน token
  final storage = await StorageService.init();
  Get.put<StorageService>(storage, permanent: true);

  runApp(const PaynEatApp());
}
