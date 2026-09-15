# Ticket: Audit ระดับบัญชี/การเงิน (Financial/Accounting Audit)

**Priority:** 🟠 High — ต่อยอดจาก `docs/tickets/13-order-audit-trail.md` (เสร็จแล้ว)
**สถานะ:** ยังไม่ได้ทำ
**Ref:** `docs/tickets/08-audit-log.md` (เสร็จแล้ว — audit ป้องกันทุจริตหน้าร้าน),
`docs/tickets/13-order-audit-trail.md` (เสร็จแล้ว — audit ระดับผู้จัดการร้าน "ใครสั่ง/แก้ไข
ออเดอร์"), `docs/tickets/12-report-export.md` (ยังไม่ได้ทำ — export รายงาน/Z-report)

## ปัญหา

ระบบมี audit log ครบ 2 ระดับแล้ว: (1) เหตุการณ์เสี่ยงต่อการทุจริตหน้าร้าน (ticket 08 — ยกเลิก/void/
คืนเงิน/แก้สิทธิ์พนักงาน) และ (2) ใครกดสั่ง/แก้ไขออเดอร์ในมุมผู้จัดการร้าน (ticket 13) — แต่ **ยังไม่มี
ชั้นที่ฝ่ายบัญชี/ผู้ตรวจสอบภายนอกต้องการ** เมื่อตรวจสอบตัวเลขทางการเงินของร้านย้อนหลัง:

1. **การแก้ไขข้อมูลหลักที่กระทบรายได้/ต้นทุนไม่ถูก log เลย** — ตรวจโค้ดจริงแล้วยืนยันว่า
   `menu.service.js` (แก้ราคาเมนู), `promotion.service.js` (สร้าง/แก้/ลบโปรโมชัน),
   `ingredient.service.js` (ปรับสต๊อก/ต้นทุนวัตถุดิบมือ) **ไม่มีการเรียก `auditLogService.log()`
   เลยสักจุดเดียว** — ถ้าผู้จัดการแอบลดราคาเมนูให้พวกพ้องแล้วเปลี่ยนกลับ หรือแก้เงื่อนไขโปรโมชันให้
   เอื้อประโยชน์ ไม่มีทางตรวจสอบย้อนหลังได้เลย ต่างจาก order-level discount (ticket 08) ที่ log
   ครบแล้ว
2. **ไม่มีทาง export audit log ให้ฝ่ายบัญชี/ผู้ตรวจสอบภายนอก** — หน้า "ประวัติการทำรายการ" ดูได้แค่
   ในแอปเท่านั้น (ตรวจโค้ดยืนยันว่าไม่มี endpoint/ปุ่ม export ใดๆ ทั้ง backend และ Flutter) ฝ่ายบัญชี
   ที่ต้องปิดงบเดือน/ปีต้องได้ไฟล์ไปประกอบเอกสาร ไม่ใช่แค่เปิดแอปดู
3. **UI ยังไม่มี date range picker สำหรับ audit log** — backend รองรับ `dateFrom`/`dateTo` อยู่แล้ว
   (ค้างมาตั้งแต่ `docs/DECISIONS.md` #21) แต่ฝ่ายบัญชีต้องการดึงรายการเฉพาะรอบบัญชีที่กำลังปิดงบ
   (เช่น "เดือนมีนาคม") ทำผ่าน UI ตอนนี้ไม่ได้
4. **ไม่เชื่อมโยงกับผลต่างเงินสดตอนปิดกะ (shift variance)** — ปิดกะแล้วเงินขาด/เกิน (ticket 01) กับ
   audit log ที่อาจอธิบายสาเหตุ (เช่น refund/discount ที่เกิดระหว่างกะนั้น) เป็นคนละหน้าจอ ไม่มีทาง
   ดูคู่กันเพื่อสอบทานว่าผลต่างมาจากอะไร

## ทำไมสำคัญ

Audit log ที่มีอยู่ตอบคำถาม "ใครทำอะไรกับ**ออเดอร์**" ได้ดีแล้ว แต่การตรวจสอบบัญชี (financial
audit) มักเริ่มจากอีกทิศทาง: **"ตัวเลขรายได้/ต้นทุนที่ใช้คำนวณทั้งหมดมาจากฐานข้อมูลหลักที่ถูกต้อง
หรือเปล่า"** — ถ้าราคาเมนูหรือเงื่อนไขโปรโมชันที่ใช้คำนวณยอดขายถูกแก้โดยไม่มีใครรู้ ตัวเลขยอดขาย
ทั้งหมดที่ audit log ระดับออเดอร์ยืนยันไว้ก็ยังพิสูจน์ความถูกต้องไม่ได้อยู่ดี — เป็น gap เชิงโครงสร้าง
ไม่ใช่แค่ "ยังไม่ครบทุก action"

## ขอบเขตงาน (คร่าวๆ)

- **Backend**: เพิ่ม `auditLogService.log()` เข้า `menu.service.js#update` (เฉพาะตอนราคาเปลี่ยนจริง,
  เหมือนหลักการเดียวกับ `order.item.edit` ในทิกเก็ต 13 — ไม่ log ทุก field เปลี่ยน), 
  `promotion.service.js#create/update/delete`, `ingredient.service.js` (ปรับสต๊อก/ต้นทุนมือ)
- **Backend**: endpoint export audit log เป็น CSV (`GET /audit-logs/export?from=&to=&format=csv`)
  — reuse filter เดิมที่มีอยู่แล้ว (`actorUserId`/`action`/`entityType`/`dateFrom`/`dateTo`)
- **Frontend**: เพิ่ม date range picker ในหน้า "ประวัติการทำรายการ" (ของค้างจาก `docs/DECISIONS.md`
  #21) และปุ่ม "ส่งออก CSV"
- **เชื่อมโยงกับ ticket 01/12**: เมื่อ ticket 12 (report export/Z-report) ถูกทำ ให้ Z-report แต่ละกะ
  ลิงก์ไปหา audit log entries ที่เกิดขึ้นระหว่างกะนั้นได้ (filter ตามช่วงเวลาเปิด-ปิดกะ)

## ขอบเขตที่ตั้งใจไม่ทำในทิกเก็ตนี้

- **e-Tax invoice ยื่นอิเล็กทรอนิกส์ต่อกรมสรรพากร** — อยู่นอกขอบเขต ตามที่ `docs/tickets/07-tax-invoice.md`
  เลื่อนไว้แล้ว ไม่เกี่ยวกับทิกเก็ตนี้
- **Immutable/tamper-evident storage (hash chaining, WORM)** — เกินความจำเป็นสำหรับร้านอาหาร
  สาขาเดียวขนาดนี้ ตาราง `audit_logs` แบบ append-only (ไม่มี endpoint แก้ไข/ลบ) ที่มีอยู่แล้วถือว่า
  เพียงพอ

## Acceptance Criteria

- [ ] แก้ราคาเมนูถูกบันทึก audit log (ราคาเก่า → ใหม่) แต่แก้ field อื่นที่ไม่กระทบราคาไม่ log
- [ ] สร้าง/แก้ไข/ลบโปรโมชันถูกบันทึก audit log ครบ
- [ ] ปรับสต๊อก/ต้นทุนวัตถุดิบด้วยมือถูกบันทึก audit log
- [ ] Export audit log เป็น CSV ได้ตามช่วงวันที่/ตัวกรองที่เลือกไว้ (admin เท่านั้น)
- [ ] หน้า "ประวัติการทำรายการ" มี date range picker ใช้งานได้จริง (ไม่ใช่แค่ backend รองรับ)

## ไฟล์ที่เกี่ยวข้อง

- `backend/src/modules/menu/menu.service.js`
- `backend/src/modules/promotions/promotion.service.js`
- `backend/src/modules/ingredients/ingredient.service.js`
- `backend/src/modules/audit-logs/`
- `app/lib/features/audit_log/presentation/pages/audit_log_page.dart`
