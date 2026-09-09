# Ticket: ลูกค้า/สมาชิก/แต้มสะสม (Customer & Loyalty)

**Priority:** 🟡 Medium
**Ref:** `docs/FEATURE-GAP-ANALYSIS.md` #9

## ปัญหา
ไม่มี table customer ใน schema เลย ระบบไม่สามารถผูกประวัติการซื้อกับลูกค้ารายบุคคล หรือทำ
ระบบสมาชิก/แต้มสะสมได้

## ทำไมสำคัญ
ระบบสมาชิกและแต้มสะสมเป็นเครื่องมือการตลาดที่ช่วยรักษาฐานลูกค้าเดิม (retention) และเป็น
ฟีเจอร์ที่ POS ระดับกลาง-สูงส่วนใหญ่มี

## ขอบเขตงาน (คร่าวๆ)
- Schema: table `customers` (id, name, phone, email nullable, points_balance,
  created_at), ผูก `orders.customer_id` (nullable — ลูกค้าทั่วไปไม่ต้องผูกก็ได้)
- Backend: endpoint ค้นหา/สร้างลูกค้า (เช่นจากเบอร์โทร), logic สะสม/ใช้แต้ม (อัตราแลกที่
  ตั้งค่าได้ใน settings)
- Frontend: ค้นหา/เพิ่มลูกค้าตอนเปิดออเดอร์หรือตอนชำระเงิน, แสดง/ใช้แต้มสะสมตอนเช็คบิล,
  หน้าประวัติการซื้อของลูกค้ารายคน (admin)

## Acceptance Criteria
- [ ] ผูกออเดอร์กับลูกค้า (ค้นหาจากเบอร์โทรหรือสร้างใหม่) ได้แบบ optional
- [ ] สะสมแต้มอัตโนมัติตามยอดซื้อ ตามอัตราที่ตั้งค่าได้
- [ ] ใช้แต้มสะสมแลกส่วนลดตอนชำระเงินได้
- [ ] Admin ดูประวัติการซื้อ/แต้มสะสมของลูกค้ารายคนได้

## ไฟล์ที่เกี่ยวข้อง
- `backend/src/db/schema.sql`
- `backend/src/modules/orders/`, `backend/src/modules/payments/`
- `app/lib/features/order/`, `app/lib/features/payment/`
