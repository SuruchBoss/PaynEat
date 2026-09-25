# Ticket: log และ metric ตามสัญญา telemetry ของระบบนิเวศ PaynEat

**Priority:** 🟠 High — **เริ่มได้ทันที** ไม่ต้องรอ PaynEat ERP
**Ref:** [PaynEat ERP ADR-0011](https://github.com/SuruchBoss/PaynEat-ERP/blob/main/docs/adr/0011-ecosystem-and-sherwhyve.md),
[สัญญา telemetry v1.1](https://github.com/SuruchBoss/PaynEat-ERP/blob/main/docs/TELEMETRY.md), `docs/DECISIONS.md` #66

## ปัญหา
backend ของ POS เขียน log ด้วย `morgan` เป็นข้อความธรรมดา กับ `console.log` อีกไม่กี่จุด ไม่มี correlation id และไม่มี
metric เลย ผลคือ:
- ตามคำขอหนึ่งครั้ง หรือยอดขายหนึ่งรายการ ข้ามระบบไม่ได้ (ต่อไปจะมี POS → ERP)
- SherWhyve (AI สืบสวนเหตุขัดข้องในระบบนิเวศ) ค้น log ด้วย `severity`, `labels.*` และ `trace` — log แบบข้อความธรรมดา
  ค้นอะไรไม่เจอ

## ทำไมสำคัญ
ต่อไป POS จะส่งยอดขายเข้า ERP (tickets 25, 26) ถ้าวันไหน "ยอดขายสาขา 2 ไม่เข้า ERP" ต้องมี log และ metric ที่พิสูจน์ได้ว่า
พังตรงไหน สัญญา telemetry v1 ถูกกำหนดไว้ครั้งเดียวสำหรับ POS, ERP และ Cwork ให้ใช้ query ชุดเดียวกันได้ POS ต้องทำตาม
**ก่อน**เชื่อม ERP จริง เพราะเติม correlation id ทีหลังให้การเชื่อมระบบที่ใช้งานอยู่แล้วแพงกว่ามาก

## ขอบเขตงาน
- **log แบบ JSON บรรทัดละ object** แทน `morgan` และ `console.*` ทั้งหมด ช่องตามสัญญา:
  - `severity` เป็น**ข้อความ** (`INFO`, `WARNING`, `ERROR`, …) ไม่ใช่ตัวเลข
  - `time`, `message`
  - `labels` แบบ object ธรรมดา ที่มี `app=payneat-pos-api`, `event` และ `correlation_id` และใส่ `location_code`
    เมื่อเกี่ยวกับสาขา — **ค่าเริ่มต้นไม่มีชื่อ vendor ใดๆ** เพราะ POS ต้อง self-host ได้
  - ถ้าตั้ง `LOG_FORMAT=gcp` (เฉพาะ deployment บน Google Cloud) ให้เขียน object เดียวกันนี้ไว้ใต้
    `logging.googleapis.com/labels` และ trace เป็น `logging.googleapis.com/trace` แทน
- **`x-request-id`**: ถ้า client ส่งมาและตรง `^[\w-]{8,64}$` ให้ใช้ค่านั้น ไม่งั้นสร้างใหม่ ส่งกลับใน response header
  ใส่ในทุกบรรทัด log ของคำขอนั้น และใส่ใน error body
- **แอป Flutter**: ส่ง `x-request-id` ทุกคำขอ และเมื่อ error ให้แสดงรหัสนี้ในข้อความ error เพื่อให้ร้านแจ้งปัญหาแล้วโยงหา log ได้
- **`http.request.completed`** พร้อม `httpRequest` โดย `requestUrl` เป็น path **ไม่รวม query string**, `latency` เป็น
  ข้อความรูปแบบ `"0.231s"` (ไม่ใช่ตัวเลข) และแปลง status เป็น `severity` ตามสัญญา
- **`GET /metrics`** (Prometheus) มี `http_requests_total` และ `http_request_duration_seconds` แยกตาม **route template**
  (`/orders/:id` ไม่ใช่ `/orders/123`) **ห้ามเปิดสาธารณะ**: ป้องกันด้วย token จาก env หรือจำกัดให้เครือข่ายภายในเท่านั้น
  เลือกแล้วบันทึกเหตุผลใน DECISIONS
- **ห้ามอยู่ใน log และ label เด็ดขาด:**
  - รหัสผ่าน, token, PIN
  - ข้อมูลลูกค้า (ชื่อ เบอร์โทร อีเมล เลขผู้เสียภาษี ที่อยู่)
  - body ของคำขอ/คำตอบ และ query string
  - endpoint สาธารณะของ QR สั่งอาหารเองต้องระวังเป็นพิเศษ

## ขอบเขตที่ตั้งใจไม่ทำ
- metric ของ outbox (อยู่ใน ticket 26)
- distributed tracing เต็มรูป (OpenTelemetry span) — ส่งต่อ `traceparent` ได้ถ้ามี แต่ไม่สร้าง span
- การตั้งค่าส่ง log ไปที่ใดที่หนึ่ง — ใช้ stdout ตามสัญญา
- Demo Mode ไม่เกี่ยว (ไม่มี backend)

## Acceptance Criteria
- [ ] ทุกบรรทัด log ของ backend เป็น JSON ตามสัญญา v1.1 ทั้งแบบค่าเริ่มต้นและแบบ `LOG_FORMAT=gcp` ไม่มี `morgan` / `console.*` เหลือใน `backend/src`
- [ ] `x-request-id` ไปกลับครบ: รับจาก client ถ้าถูกรูปแบบ สร้างใหม่ถ้าไม่ถูก อยู่ใน response header, log ทุกบรรทัด และ error body
- [ ] แอปส่ง `x-request-id` และแสดงรหัสนี้ตอน error
- [ ] `/metrics` มี metric HTTP ตาม route template และเข้าถึงจากภายนอกไม่ได้
- [ ] เทสต์ยืนยันว่าการสร้าง/แก้ลูกค้าและการ login ไม่ทำให้ชื่อ เบอร์ อีเมล หรือรหัสผ่าน โผล่ใน log
- [ ] README (ไทย/อังกฤษ) และ `docs/DECISIONS.md` อัปเดตตาม `CLAUDE.md`

## เทสต์
backend (`node:test` + supertest): รูปแบบ log, การไปกลับของ `x-request-id`, `/metrics`, ไม่มีข้อมูลส่วนบุคคลใน log
แอป: controller test ที่ยืนยันว่า error message แสดงรหัสคำขอ
