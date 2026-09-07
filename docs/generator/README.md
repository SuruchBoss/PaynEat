# ตัวสร้างเอกสารนำเสนอผลงาน

สคริปต์ชุดนี้ประกอบภาพหน้าจอกับคำอธิบายเป็นไฟล์ PDF สองภาษา

| ไฟล์ | สำหรับใคร | เนื้อหา |
|---|---|---|
| `../PaynEat-POS-Features-TH.pdf` | ผู้ที่มาดูผลงาน / ทีมพัฒนา | เล่าเชิงเทคนิคว่าออกแบบยังไงและเบื้องหลังทำงานยังไง |
| `../PaynEat-POS-Features-EN.pdf` | ลูกค้าธุรกิจ | เล่าเชิงธุรกิจว่าแต่ละหน้าจอแก้ปัญหาอะไรให้ร้าน |

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

## โครงสร้าง

| ไฟล์ | หน้าที่ |
|---|---|
| `content.py` | เนื้อหาฉบับภาษาไทย |
| `content_en.py` | เนื้อหาฉบับภาษาอังกฤษ (เขียนใหม่สำหรับลูกค้าธุรกิจ ไม่ใช่คำแปล) |
| `build.py` | จัดหน้าและสร้าง HTML — ใช้ร่วมกันทั้งสองภาษา |
| `makepdf.mjs` | เรนเดอร์ HTML เป็น PDF |

เนื้อหาแยกจากการจัดหน้า จึงเพิ่มภาษาใหม่ได้โดยเขียนแค่ไฟล์ `content_*.py` เพิ่ม

## ทำไมถึงถ่ายภาพด้วย golden test

ตัวเรนเดอร์ของ `flutter_test` วาด widget จริงออกมาเป็น PNG ได้โดยไม่ต้องเปิดเครื่องจำลอง
หรือเบราว์เซอร์ ทำให้ภาพในเอกสารตรงกับโค้ดล่าสุดเสมอ สร้างซ้ำได้ และรันในเครื่องที่ไม่มีจอก็ได้

การทำภาพชุดนี้ยังช่วยจับบั๊กจริงได้ 4 ข้อ ซึ่งการกดใช้งานตามปกติมองข้ามไป
(แถบตัวกรองไม่รีเฟรช, ฟอนต์ปุ่มหลุดจากธีม, hero tag ซ้ำของปุ่มลอย และกราฟรายชั่วโมงที่ตรึงช่วงเวลาไว้ตายตัว)

## หมายเหตุ

- ต้องมีฟอนต์ที่ `app/tool/fonts/` เพราะ `flutter_test` ไม่มีฟอนต์ระบบให้ใช้
- ฉบับภาษาอังกฤษใช้ฟอนต์ Noto Sans ส่วนฉบับภาษาไทยใช้ Noto Sans Thai (ตั้งค่าที่ `LABELS['font']`)
