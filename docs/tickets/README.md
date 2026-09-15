# PaynEat — Feature Gap Tickets

Ticket เหล่านี้สร้างจาก `docs/FEATURE-GAP-ANALYSIS.md` (PO gap analysis, 2026-09-09)
แต่ละไฟล์คือ 1 ticket อิสระ อ่านแล้วเริ่ม plan/implement ต่อได้เลย ไม่ต้องกลับไปอ่าน gap
analysis ซ้ำ (แต่ลิงก์ไว้เผื่ออยากดู context เพิ่ม)

จัดกลุ่มตามลำดับที่ควรทำ (ตัวเลขนำหน้าไฟล์ = ลำดับความสำคัญ ไม่ใช่ ticket id ตายตัว):

## 🔴 Critical (Sprint แรก — ของที่ POS ทุกตัวต้องมี)
- `01-shift-cash-reconciliation.md`
- `02-refund-flow.md`
- `03-receipt-printer.md`
- `04-offline-mode.md`

## 🟠 High (เฟส 2 — แข่งขันกับ POS เจ้าอื่น)
- `05-promotion-engine.md`
- `06-inventory-stock.md`
- `07-tax-invoice.md`
- `08-audit-log.md`

## 🟡 Medium (เฟสขยายธุรกิจ)
- `09-customer-loyalty.md`
- `10-takeaway-delivery-flow.md`
- `11-multi-branch.md`
- `12-report-export.md`

## 🟢 Nice-to-have (backlog, ไม่ตัด ticket แยก)
- ระบบจองโต๊ะ (reservation) ผูกกับผังโต๊ะ
- แจ้งเตือนสต๊อกใกล้หมด/ยกเลิกออเดอร์ผิดปกติ ผ่าน push/LINE Notify
- Flutter integration test กับ backend จริง (README ระบุว่ายังไม่มี มีแค่ unit/widget test)
- เอา pagination ที่ backend รองรับอยู่แล้วมาใช้ฝั่ง app

## นอกเหนือจาก gap analysis เดิม (ผู้ใช้ร้องขอเพิ่มเติมภายหลัง — audit ทั้ง financial และ restaurant manager)
- `13-order-audit-trail.md` — ✅ เสร็จแล้ว — ขยาย audit log (ticket 08) ให้ครอบคลุม
  "ใครกดสั่ง/แก้ไขออเดอร์" สำหรับ**ผู้จัดการร้าน** ไม่ใช่แค่เหตุการณ์เสี่ยงต่อการทุจริต
- `14-financial-audit-trail.md` — ยังไม่ได้ทำ — audit ระดับ**บัญชี/การเงิน**: แก้ราคาเมนู/โปรโมชัน/
  ต้นทุนวัตถุดิบยังไม่ถูก log เลย, ไม่มี export audit log ให้ฝ่ายบัญชี, ไม่มี date range picker
  บน UI (ของค้างจาก ticket 08)
- `15-ai-ask-your-data.md` — ยังไม่ได้ทำ — **จุดขาย**: AI ถามตอบข้อมูลร้านด้วยภาษาพูด (ยอดขาย/
  เมนูขายดี/ลูกค้า) ผ่าน LLM tool-calling ที่เรียก endpoint จริงในระบบเท่านั้น (กัน hallucinate
  ตัวเลข) ต่อยอดจากดีไซน์ dashboard ที่ทำไว้ก่อนหน้า
