# Ticket: คืนเงินหลังชำระเงินแล้ว (Refund)

**Priority:** 🔴 Critical
**Ref:** `docs/FEATURE-GAP-ANALYSIS.md` #2

## ปัญหา
ระบบมีแค่ "cancel" ออเดอร์/รายการก่อนเสิร์ฟ/ก่อนจ่ายเงิน (ดู `order_items.status`,
`orders.status = cancelled`) แต่ไม่มี flow คืนเงินหลังชำระเงินสำเร็จเลย ไม่มี table
`refunds` ใน schema

## ทำไมสำคัญ
ร้านจริงเจอเคสลูกค้าคืนของ/ร้านเก็บเงินผิด/ยกเลิกบิลหลังจ่ายแล้วบ่อยมาก ถ้าไม่มี flow
คืนเงินที่มี audit trail ชัดเจน จะกระทบยอดขาย/รายงาน/เงินสดผิดพลาด และเสี่ยงต่อการทุจริต

## ขอบเขตงาน (คร่าวๆ)
- Schema: table `refunds` (id, payment_id FK, order_id FK, amount, reason, refunded_by
  user_id, approved_by user_id nullable, created_at)
- Business rule: ใครอนุมัติ refund ได้บ้าง (เช่น ต้อง manager ขึ้นไป คล้ายกับ void ที่ต้อง
  manager หลังเข้าสถานะ cooking)
- Backend: endpoint `POST /payments/:id/refund` (เต็มจำนวน/บางส่วน), อัปเดตยอดขาย/รายงาน
  ให้หัก refund ออก
- Frontend: ปุ่ม refund ในหน้า order history / receipt, กรอกเหตุผล, ต้องมี role ที่
  เหมาะสมยืนยัน

## Acceptance Criteria
- [ ] Manager ขึ้นไป refund บิลที่จ่ายแล้วได้ (เต็ม/บางส่วน) พร้อมระบุเหตุผล
- [ ] มี record การ refund แยกจาก payment เดิม เก็บ audit trail ผู้ทำรายการ
- [ ] รายงานยอดขาย/dashboard หัก refund ออกจากยอดขายสุทธิถูกต้อง
- [ ] Order/receipt แสดงสถานะว่าถูก refund (เต็ม/บางส่วน) ชัดเจน

## ไฟล์ที่เกี่ยวข้อง
- `backend/src/db/schema.sql`
- `backend/src/modules/payments/`
- `backend/src/modules/reports/`
- `app/lib/features/payment/`, `app/lib/features/report/`
