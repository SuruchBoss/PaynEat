# ตัวสร้างเอกสารนำเสนอผลงาน

สคริปต์ชุดนี้ประกอบภาพหน้าจอกับคำอธิบายเป็นไฟล์ PDF `docs/PaynEat-POS-Features.pdf`

## ขั้นตอน

```bash
# 1) ถ่ายภาพหน้าจอจากแอปจริง (ผลลัพธ์ลง app/tool/screenshots/images/)
cd app
flutter test --update-goldens --dart-define=DEMO_MODE=true tool/screenshots/capture_test.dart

# 2) ย่อภาพลง docs/screenshots/ แล้วประกอบเป็น HTML
cd ../docs/generator
python3 build.py document.html

# 3) เรนเดอร์เป็น PDF ด้วย Chromium (ผ่าน Playwright)
node makepdf.mjs "$(pwd)/document.html" ../PaynEat-POS-Features.pdf
```

## ทำไมถึงถ่ายภาพด้วย golden test

ตัวเรนเดอร์ของ `flutter_test` วาด widget จริงออกมาเป็น PNG ได้โดยไม่ต้องเปิดเครื่องจำลอง
หรือเบราว์เซอร์ ทำให้ภาพในเอกสารตรงกับโค้ดล่าสุดเสมอ สร้างซ้ำได้ และรันในเครื่องที่ไม่มีจอก็ได้

การทำภาพชุดนี้ยังช่วยจับบั๊กจริงได้ 3 ข้อ (แถบตัวกรองไม่รีเฟรช ฟอนต์ปุ่มหลุดจากธีม
และ hero tag ซ้ำของปุ่มลอย) ซึ่งการกดใช้งานตามปกติมองข้ามไป

## หมายเหตุ

- ต้องมีฟอนต์ไทยที่ `app/tool/fonts/` เพราะ `flutter_test` ไม่มีฟอนต์ระบบให้ใช้
- `content.py` เก็บเนื้อหาทั้งหมด แยกจาก `build.py` ที่ทำหน้าที่จัดหน้า แก้ข้อความได้โดยไม่ต้องแตะเลย์เอาต์
