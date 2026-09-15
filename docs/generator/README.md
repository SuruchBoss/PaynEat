# ตัวสร้างเอกสารนำเสนอผลงาน

สคริปต์ชุดนี้ประกอบภาพหน้าจอกับคำอธิบายเป็นไฟล์ PDF สองภาษา

| ไฟล์ | สำหรับใคร | เนื้อหา |
|---|---|---|
| `../PaynEat-POS-Features-TH.pdf` | ผู้ที่มาดูผลงาน / ทีมพัฒนา | เล่าเชิงเทคนิคว่าออกแบบยังไงและเบื้องหลังทำงานยังไง |
| `../PaynEat-POS-Features-EN.pdf` | ลูกค้าธุรกิจ | เล่าเชิงธุรกิจว่าแต่ละหน้าจอแก้ปัญหาอะไรให้ร้าน |
| `../PaynEat-POS-Audit-Report-TH.pdf` | ทีมพัฒนา / ผู้ตรวจโค้ด | สรุปผลตรวจ Clean Code / State Management / Clean Architecture / Technical Debt / โครงสร้างโฟลเดอร์ |

## ขั้นตอน

```bash
# 1) ถ่ายภาพหน้าจอจากแอปจริง (ผลลัพธ์ลง app/tool/screenshots/images/)
cd app
flutter test --update-goldens --dart-define=DEMO_MODE=true tool/screenshots/capture_test.dart

# 2) ย่อภาพลง docs/screenshots/ แล้วประกอบเป็น HTML
cd ../docs/generator
python3 build.py document-th.html content       # ฉบับภาษาไทย
python3 build.py document-en.html content_en    # ฉบับภาษาอังกฤษ

# 3) เรนเดอร์เป็น PDF ด้วย Chromium (ผ่าน Playwright)
node makepdf.mjs "$(pwd)/document-th.html" ../PaynEat-POS-Features-TH.pdf "PaynEat POS — เอกสารรวมฟีเจอร์และหน้าจอ"
node makepdf.mjs "$(pwd)/document-en.html" ../PaynEat-POS-Features-EN.pdf "PaynEat POS — Feature and screen guide"
```

รายงานผลตรวจคุณภาพโค้ด (ไม่ต้องมีภาพหน้าจอ) สร้างจาก 3 สคริปต์แยกต่างหาก:

```bash
cd docs/generator

# 1) เขียน HTML + ส่งออกข้อความล้วนของแต่ละหน้าเป็น .pages.json คู่กัน
python3 build_audit_report.py audit-report.html

# 2) เรนเดอร์เป็น PDF ด้วย Chromium — หน้าตาถูกต้อง 100% แต่ "คัดลอกข้อความไม่ได้ทุกครั้ง" (ดูหมายเหตุด้านล่าง)
node makepdf.mjs "$(pwd)/audit-report.html" audit-report-visual.pdf "PaynEat POS — รายงานผลตรวจคุณภาพโค้ด"

# 3) แปลงแต่ละหน้าเป็นภาพ แล้วฝังเลเยอร์ข้อความที่ถูกต้อง (มองไม่เห็น) ทับลงไป — ได้ผลลัพธ์สุดท้าย
python3 overlay_text_layer.py audit-report-visual.pdf audit-report.pages.json ../PaynEat-POS-Audit-Report-TH.pdf

rm -f audit-report.html audit-report.pages.json audit-report-visual.pdf  # ไฟล์ระหว่างทาง ไม่ต้อง commit
```

> **หมายเหตุสำคัญ**: ทำไมต้อง overlay ข้อความ — Chromium print-to-PDF มีบั๊กที่ทำให้ข้อความไทย
> ที่มีวรรณยุกต์/สระซ้อนกัน (เช่น "ผ่าน", "ด้วย", "คุณภาพ") ถูกฝังใน PDF ด้วย ToUnicode CMap ที่ผิด —
> แสดงผล/พิมพ์ออกมาถูกต้อง 100% แต่คัดลอก (copy-paste) ออกมาแล้วตัวอักษรซ้ำหรือสลับที่
> (เช่น "ผ่าน" กลายเป็น "ผ่าผ่ น") ไล่ทดสอบแล้วว่าเกิดแบบสุ่มไปตามคำที่ใช้ ไม่ขึ้นกับฟอนต์หรือ
> เอนจินตัวใดตัวหนึ่ง — ลองมาแล้ว Noto Sans Thai, Waree, Kinnari, Umpush, Garuda, Purisa, Norasi,
> Loma ผ่าน Chromium ปกติ, Chromium tagged-pdf, WeasyPrint, LibreOffice ทุกชุดพังแบบไม่คงที่ต่างกันไป
> จึงแก้ที่ปลายทางแทน: `overlay_text_layer.py` แปลงหน้า PDF ที่ Chromium เรนเดอร์ (ภาพถูกต้อง)
> เป็นรูปภาพ แล้วฝังข้อความล้วนที่รู้อยู่แล้วว่าถูกต้อง (จากขั้นตอนที่ 1) ลงไปแบบมองไม่เห็นด้วย
> reportlab ซึ่งไม่ทำ shaping ที่ซับซ้อน จึงวาดสตริง Unicode ตรงตามที่ป้อนเข้าไปเป๊ะ — สคริปต์
> ตรวจสอบเองท้ายกระบวนการว่า extract ข้อความกลับมาตรงกับต้นฉบับ 100% ทุกหน้า
>
> ต้องติดตั้งเพิ่ม: `pip install reportlab pypdfium2 pillow`

## โครงสร้าง

| ไฟล์ | หน้าที่ |
|---|---|
| `content.py` | เนื้อหาฉบับภาษาไทย |
| `content_en.py` | เนื้อหาฉบับภาษาอังกฤษ (เขียนใหม่สำหรับลูกค้าธุรกิจ ไม่ใช่คำแปล) |
| `build.py` | จัดหน้าและสร้าง HTML ของเอกสารฟีเจอร์ — ใช้ร่วมกันทั้งสองภาษา |
| `makepdf.mjs` | เรนเดอร์ HTML เป็น PDF (ใช้ร่วมกันทั้งเอกสารฟีเจอร์และรายงานตรวจโค้ด) |
| `build_audit_report.py` | เนื้อหา + จัดหน้า HTML ของรายงานตรวจคุณภาพโค้ด พร้อมส่งออกข้อความล้วนแต่ละหน้า |
| `overlay_text_layer.py` | ฝังเลเยอร์ข้อความที่ถูกต้องแบบมองไม่เห็นทับ PDF ที่เรนเดอร์แล้ว (แก้บั๊กคัดลอกข้อความไทย) |

เนื้อหาแยกจากการจัดหน้า จึงเพิ่มภาษาใหม่ได้โดยเขียนแค่ไฟล์ `content_*.py` เพิ่ม

## ทำไมถึงถ่ายภาพด้วย golden test

ตัวเรนเดอร์ของ `flutter_test` วาด widget จริงออกมาเป็น PNG ได้โดยไม่ต้องเปิดเครื่องจำลอง
หรือเบราว์เซอร์ ทำให้ภาพในเอกสารตรงกับโค้ดล่าสุดเสมอ สร้างซ้ำได้ และรันในเครื่องที่ไม่มีจอก็ได้

การทำภาพชุดนี้ยังช่วยจับบั๊กจริงได้ 4 ข้อ ซึ่งการกดใช้งานตามปกติมองข้ามไป
(แถบตัวกรองไม่รีเฟรช, ฟอนต์ปุ่มหลุดจากธีม, hero tag ซ้ำของปุ่มลอย และกราฟรายชั่วโมงที่ตรึงช่วงเวลาไว้ตายตัว)

## หมายเหตุ

- ต้องมีฟอนต์ที่ `app/tool/fonts/` เพราะ `flutter_test` ไม่มีฟอนต์ระบบให้ใช้
- **เวลาถูกตรึงไว้ที่ 11 ก.ย. 2026 19:42** (`ScreenshotHarness.capturedAt`) ถ่ายกี่ครั้ง
  ก็ได้ไฟล์เหมือนเดิมทุกไบต์ ภาพที่เปลี่ยนใน git จึงเป็นการเปลี่ยนแปลงจริงของ UI เสมอ
  ไม่ใช่แค่นาฬิกาเดิน — โค้ดที่ผลลัพธ์ขึ้นกับเวลาปัจจุบันต้องเรียกผ่าน `AppClock.now()`
  ไม่ใช่ `DateTime.now()` ตรง ๆ ไม่งั้นจะหลุดการตรึงนี้
- ฉบับภาษาอังกฤษใช้ฟอนต์ Noto Sans ส่วนฉบับภาษาไทยใช้ Noto Sans Thai (ตั้งค่าที่ `LABELS['font']`)
