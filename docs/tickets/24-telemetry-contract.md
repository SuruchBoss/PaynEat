# Ticket: log และ metric ตามสัญญา telemetry ของระบบนิเวศ PaynEat

**Priority:** 🟠 High — **เริ่มได้ทันที** ไม่ต้องรอ PaynEat ERP
**สถานะ:** ✅ เสร็จแล้ว (2026-09-25) — ดู "สิ่งที่ทำไปแล้ว" ท้ายไฟล์ และ `docs/DECISIONS.md` #68
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
- [x] ทุกบรรทัด log ของ backend เป็น JSON ตามสัญญา v1.1 ทั้งแบบค่าเริ่มต้นและแบบ `LOG_FORMAT=gcp` ไม่มี `morgan` / `console.*` เหลือใน `backend/src`
- [x] `x-request-id` ไปกลับครบ: รับจาก client ถ้าถูกรูปแบบ สร้างใหม่ถ้าไม่ถูก อยู่ใน response header, log ทุกบรรทัด และ error body
- [x] แอปส่ง `x-request-id` และแสดงรหัสนี้ตอน error
- [x] `/metrics` มี metric HTTP ตาม route template และเข้าถึงจากภายนอกไม่ได้
- [x] เทสต์ยืนยันว่าการสร้าง/แก้ลูกค้าและการ login ไม่ทำให้ชื่อ เบอร์ อีเมล หรือรหัสผ่าน โผล่ใน log
- [x] README (ไทย/อังกฤษ) และ `docs/DECISIONS.md` อัปเดตตาม `CLAUDE.md`

## เทสต์
backend (`node:test` + supertest): รูปแบบ log, การไปกลับของ `x-request-id`, `/metrics`, ไม่มีข้อมูลส่วนบุคคลใน log
แอป: controller test ที่ยืนยันว่า error message แสดงรหัสคำขอ

## สิ่งที่ทำไปแล้ว

- **กฎของสัญญาเป็น pure function** ใน `backend/src/core/telemetry/logRecord.js` (ตรรกะเดียวกับ PaynEat ERP):
  severity ตาม status, latency `"0.231s"`, path ไม่มี query string, รับ `x-request-id` ตาม `^[\w-]{8,64}$`,
  `traceparent` → trace, labels/trace ในรูปแบบค่าเริ่มต้นและ `LOG_FORMAT=gcp`
- **`middlewares/requestContext.js`** ตัวแรกสุดของแอป แทน `morgan`: รหัสคำขอไปกลับ (header, ทุกบรรทัด log, error body
  `error.requestId`), บรรทัด `http.request.completed` หนึ่งบรรทัดต่อคำขอ (5xx มี `error {type, message}`, stack เฉพาะ
  `LOG_LEVEL=DEBUG`), นับ metric ตาม route template — คำขอที่จบก่อนถึง route ได้ `<mount>/*` ไม่เข้า mount ไหนได้ `unmatched`
- **`location_code`** จากรหัสสาขาของพนักงานที่ล็อกอิน (เฉพาะรหัสที่ตรงรูปแบบรหัสสถานที่กลางของ ticket 25)
- **`/metrics` บนพอร์ตแยก `METRICS_PORT` (9464)** ที่ docker compose ไม่เปิดออกนอกเครื่อง — ตั้งเท่ากับ `PORT` เซิร์ฟเวอร์
  ไม่ยอม start, เปิดพอร์ตไม่ได้ตอนรัน POS ขายต่อได้ (DECISIONS #68)
- **ไม่มี `morgan`/`console.*` ใน `backend/src` แล้ว** (ESLint `no-console: error`) — `server.js` และสคริปต์ migrate/seed/reset
  เขียนผ่าน logger เดียวกันด้วย `event: "app.log"` และ seed เลิกพิมพ์รหัสผ่านบัญชีเดโม
- **ช่องรั่วที่เจอระหว่างทาง**: QR token ของโต๊ะใน path ถูกแทนด้วย `:qrToken`; JSON พังเคยตกเป็น 500 พร้อมเนื้อ body ใน
  ข้อความ error — ตอนนี้ตอบ 400 (body ใหญ่เกิน 413) และไม่ลง log; ApiError 5xx ลง log เป็นข้อความแม่แบบ (ไม่มีอีเมลผู้รับจาก
  คำตอบ SMTP)
- **แอป**: `ApiClient` ส่ง `x-request-id` (`pos-` + 16 hex) ทุกคำขอ, `ApiException`/`ServerFailure` มี `requestId`,
  ข้อความ error ที่เซิร์ฟเวอร์ปฏิเสธ/ทำไม่สำเร็จมี "รหัสคำขอ: …" ต่อท้าย (ไม่ต่อกับ 401/403/422) และ 5xx แสดงข้อความที่
  backend แปลตามภาษาแล้วแทนข้อความภาษาอังกฤษของ Dio
- **เทสต์**: `backend/tests/telemetry-log-record.test.js` (13 — กฎของสัญญา), `backend/tests/telemetry.test.js` (11 — ยิงแอปจริง
  ตรวจบรรทัด log จริงทั้งสองรูปแบบ, `x-request-id`, severity, `/metrics`, ไม่มีชื่อ/เบอร์/อีเมล/เลขผู้เสียภาษี/ที่อยู่/รหัสผ่าน/
  token/QR token ใน log), `app/test/presentation/request_id_error_test.dart` (5 — ผ่าน ApiClient → repository → controller จริง)
