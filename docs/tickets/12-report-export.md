# Ticket: Export รายงาน (Excel/CSV/PDF) + End-of-day / Z-report

**Priority:** 🟡 Medium
**Ref:** `docs/FEATURE-GAP-ANALYSIS.md` #12 · **สถานะ:** ✅ เสร็จแล้ว (ดู `docs/DECISIONS.md` #35)

## ปัญหา
รายงานปัจจุบัน (`reports_page.dart`, `/reports/summary`, `/reports/top-items`,
`/reports/sales-by-day`) ดูได้แค่ในแอปเท่านั้น ไม่มีทาง export เป็นไฟล์เพื่อส่งต่อฝ่ายบัญชี
และไม่มีรายงานสรุปปิดวัน (End-of-day/Z-report) แบบมาตรฐาน

## ทำไมสำคัญ
ร้านอาหารต้องส่งข้อมูลยอดขายให้ฝ่ายบัญชี/สำนักงานบัญชีภายนอกเป็นประจำ การดูได้แค่ในแอป
ไม่พอ ต้อง export เป็นไฟล์ได้ และ Z-report (สรุปยอดขาย/ภาษี/ส่วนลด/ช่องทางชำระเงินของวันนั้น)
เป็นเอกสารมาตรฐานที่ POS ต้องมี

## ขอบเขตงาน (ที่ทำจริง)
- **Backend — export รายงานเป็น CSV**: `GET /reports/export/summary`, `/export/top-items`,
  `/export/sales-by-day` ทั้งสามตัว reuse query schema เดิมของรายงานนั้นๆ (`rangeQuerySchema`/
  `topItemQuerySchema`) เพราะตัวเลขในไฟล์ต้องตรงกับที่เห็นในแอปเป๊ะ ต่างกันแค่ format ที่ตอบกลับ
  ประกอบไฟล์ด้วย `backend/src/core/csv.js#toCsv` ตัวเดียวกับที่ audit log export (ticket 14) ใช้
- **Backend — Z-report**: `GET /reports/z-report/by-shift/:shiftId` และ `/z-report/by-date`
  พร้อม endpoint `/export` ของทั้งสองแบบ แยกกันชัดเจนไม่ใช่ endpoint เดียว — ต่อกะมีกระทบยอด
  เงินสด (เงินตั้งต้น/ที่คาดไว้/ที่นับได้จริง/ส่วนต่าง) ต่อวันรวมทุกกะและ**ไม่มี**กระทบยอดเงินสด
  เพราะวันเดียวอาจมีหลายกะ/หลายแคชเชียร์ปนกัน กระทบยอดระดับวันจึงไม่มีความหมาย
- **Backend — query ต่อกะคิดจาก `payments.shift_id` ไม่ใช่วันที่เปิดออเดอร์**: ออเดอร์เปิดค้าง
  ข้ามกะได้ (เปิดกะเช้า จ่ายจริงกะบ่าย) และกะดึกก็ข้ามเที่ยงคืน การ join ผ่าน `shift_id` ของแถว
  การชำระเงินจึงถูกต้องกว่าเทียบวันที่ — และรองรับ split-bill ถูกต้องด้วยเพราะนับจาก payment
  รายแถว ไม่ใช่ order ทั้งก้อน (คอลัมน์นี้มีมาตั้งแต่ ticket 01 ไม่ต้อง migrate เพิ่ม)
- **Frontend**: หน้ารายงานมีปุ่ม export ปุ่มเดียวเป็น `PopupMenuButton<ReportExportKind>`
  ให้เลือกสามรายงาน (สรุปยอดขาย/เมนูขายดี/ยอดขายรายวัน) แล้วเรียก `controller.exportCsv` ตัวเดียว
  ส่วน `z_report_dialog.dart` เปิดได้สองทาง: การ์ดสรุปกะที่เพิ่งปิด และรายการประวัติกะ — ทั้งคู่
  เปิดได้เฉพาะกะที่ปิดแล้ว (`onTap: isOpen ? null : ...`) เพราะยอดกระทบเงินสดยังเป็น `null`
  ตอนกะยังเปิด การโชว์ ฿0.00 จะดูเหมือนกะสมดุลแล้วทั้งที่ยังไม่ได้กระทบจริง
- **Demo Mode**: `demo_store_reports.dart` ประกอบ CSV ฝั่ง Dart ล้วน (`exportSummaryCsv`/
  `exportTopItemsCsv`/`exportSalesByDayCsv` และ `exportZReportCsv` พร้อม wrapper
  `exportZReportByShiftCsv`/`exportZReportByDateCsv`) ให้ทุกแถวตรงกับ `report.service.js`
  แล้วเรียก `toCsv()` ตัวเดียวกับ audit log — คนลองเดโมสาธารณะที่ไม่มี backend ยัง export ได้

## ขอบเขตที่ตั้งใจไม่ทำในทิกเก็ตนี้
- **Excel (`.xlsx`) และ PDF** — ทิกเก็ตยอมรับ "CSV/Excel อย่างน้อย 1 format" กับ "PDF หรือ
  เทียบเท่า" เลือก CSV เพราะ infra มีครบอยู่แล้วทั้งสองฝั่ง เปิดกับ Excel ได้ตรง (มี UTF-8 BOM
  กันอักษรไทยเพี้ยน) ไม่ต้องเพิ่ม dependency ใหม่ (`xlsx`/`pdfkit`) ดู `docs/DECISIONS.md` #35
- **พรีวิว Z-report ระหว่างกะที่ยังไม่ปิด** — ตัดสินใจตั้งใจ ไม่ใช่ของค้าง ถ้าอนาคตอยากได้ยอดขายสด
  ระหว่างกะโดยไม่กระทบเงินสด ให้แยก endpoint/UI ใหม่ อย่า reuse component Z-report เดิม
- **ดาวน์โหลดไฟล์บนแพลตฟอร์มที่ไม่ใช่เว็บ** — `csv_download_stub.dart` คืน
  `isCsvDownloadSupported = false` และ throw `UnsupportedError` เหมือน audit log export เดิม
  (ปุ่มซ่อนเองบนมือถือ/เดสก์ท็อป) เป็นฟีเจอร์ฝั่งเว็บผู้ดูแลระบบ

## Acceptance Criteria
- [x] Export รายงานยอดขาย (ตามช่วงวันที่ที่เลือก) เป็นไฟล์ CSV/Excel ได้ — ทำแล้ว: CSV ทั้งสาม
  รายงาน (สรุปยอดขาย/เมนูขายดี/ยอดขายรายวัน) เลือกจากเมนู export ที่หน้ารายงาน มี UTF-8 BOM
  เปิดกับ Excel ได้ตรง
- [x] มี Z-report สรุปยอดขาย/ภาษี/ส่วนลด/แยกตามช่องทางชำระเงินต่อวัน/ต่อกะ — ทำแล้ว: ต่อกะมีกระทบยอด
  เงินสดด้วย (คิดจาก `payments.shift_id`), ต่อวันรวมทุกกะ (ไม่มีกระทบยอดเงินสด)
- [x] Export/ดาวน์โหลด Z-report เป็นไฟล์ (PDF หรือเทียบเท่า) ได้ — ทำแล้ว: CSV (เทียบเท่าตามที่ระบุไว้
  — ดู `docs/DECISIONS.md` #35 สำหรับเหตุผลไม่ทำ Excel/PDF)
- [x] RBAC: admin/manager/cashier export ได้ (แคชเชียร์ต้องใช้ตอนปิดกะ) พนักงานเสิร์ฟ export ไม่ได้
  — บังคับที่ router ระดับ `authorize('admin', 'manager', 'cashier')` และมีเทสต์ยืนยัน 403
- [x] Demo Mode export ได้ครบทุกปุ่มโดยไม่ต้องมี backend จริง

## เทสต์
- `backend/tests/report-export.test.js` — 8 เคส ยิง HTTP จริงผ่าน supertest: CSV ทั้งสามรายงาน
  (เช็ค BOM + เนื้อแถว), Z-report ต่อกะ (สรุป+กระทบเงินสด), 404 เมื่อไม่พบกะ, Z-report ต่อวัน
  (ต้องเท่ากับ summary ของวันนั้น + ฟิลด์ `type`/`date`), export Z-report รายวัน, และ RBAC 403
- `app/test/presentation/report_controller_test.dart`,
  `app/test/presentation/shift_controller_test.dart` — ระดับ controller
- **ไม่ครอบคลุม** `exportCsv()`/`exportZReportCsv()` เส้นทางสำเร็จ เพราะเรียก `AppDialogs`/
  `downloadCsv` ตรงๆ ต้อง pump `GetMaterialApp` จริง — ตรงกับ `docs/CODING_STANDARDS.md` ข้อ 6.2
  และรูปแบบเดิมของ `audit_log_controller_test.dart`

## ไฟล์ที่เกี่ยวข้อง
- `backend/src/modules/reports/` (`report.routes.js`/`.controller.js`/`.service.js`/`.repository.js`)
- `backend/src/core/csv.js`, `backend/tests/report-export.test.js`, `backend/docs/openapi.yaml`
- `app/lib/features/report/` (domain/data/presentation — `reports_page.dart`,
  `report_controller.dart`, `report_usecases.dart`, `report_remote_data_source.dart`)
- `app/lib/features/shift/presentation/widgets/z_report_dialog.dart`,
  `app/lib/features/shift/presentation/{pages/shift_page.dart,controllers/shift_controller.dart}`
- `app/lib/core/utils/csv.dart`, `app/lib/core/utils/csv_download/` (web/stub)
- `app/lib/core/demo/demo_store_reports.dart`, `demo_report_data_source.dart` (Demo Mode mirror)
- เกี่ยวโยงกับ `01-shift-cash-reconciliation.md` (Z-report ต่อกะใช้ `payments.shift_id` จากทิกเก็ตนั้น)
  และ `14-financial-audit-trail.md` (reuse infra CSV export เดียวกัน)
