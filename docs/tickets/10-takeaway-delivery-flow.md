# Ticket: Takeaway/Delivery Flow เต็มรูปแบบ

**Priority:** 🟡 Medium
**Ref:** `docs/FEATURE-GAP-ANALYSIS.md` #10

## ปัญหา
`orders.type` รองรับค่า `dine_in|takeaway|delivery` ใน schema อยู่แล้ว แต่ UI/business
logic ทั้งหมดออกแบบมาสำหรับ dine-in เป็นหลัก (ผูกกับผังโต๊ะ) ไม่มีคิวรับอาหารสำหรับ
takeaway ไม่มีการเชื่อมต่อแพลตฟอร์มเดลิเวอรี (Grab/LINE MAN เป็นต้น)

## ทำไมสำคัญ
ร้านอาหารส่วนใหญ่ในปัจจุบันมีช่องทางขายนอกเหนือจาก dine-in การไม่มี flow เฉพาะทำให้ต้อง
ฝืนใช้ table map/ระบบที่ออกแบบมาเพื่อโต๊ะจริงกับออเดอร์ที่ไม่มีโต๊ะ

## ขอบเขตงาน (คร่าวๆ)
- Backend: order creation flow ที่ไม่ผูกกับ `table_id` (nullable อยู่แล้ว?
  ตรวจสอบ constraint ปัจจุบัน), สร้างเลขคิว/เลขรับอาหารสำหรับ takeaway
- Frontend: หน้าจอสร้างออเดอร์ takeaway/delivery แยกจาก flow ผังโต๊ะ, แสดงคิว/สถานะ
  "รอลูกค้ามารับ"
- (ถ้า scope เดลิเวอรีจริง) ประเมิน integration กับ platform ภายนอก (Grab/LINE MAN API) —
  แนะนำแยกเป็น ticket ย่อยอีกทีเพราะ scope ใหญ่และขึ้นกับ external API

## Acceptance Criteria
- [ ] สร้างออเดอร์ takeaway ได้โดยไม่ต้องผูกกับโต๊ะ พร้อมเลขคิว/เลขรับอาหาร
- [ ] ครัว (KDS) เห็นความแตกต่างระหว่างออเดอร์ dine-in กับ takeaway/delivery ชัดเจน
- [ ] Cashier เช็คบิล/ชำระเงินสำหรับ takeaway ได้โดยไม่ติด flow ที่บังคับเลือกโต๊ะ
- [ ] (ถ้าทำ) เชื่อมต่อรับออเดอร์จากแพลตฟอร์มเดลิเวอรีอย่างน้อย 1 เจ้าได้

## ไฟล์ที่เกี่ยวข้อง
- `backend/src/modules/orders/`
- `app/lib/features/order/`, `app/lib/features/table/`, `app/lib/features/kitchen/`
