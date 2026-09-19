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
- `11-multi-branch.md` — 🚧 พบว่าอีก session กำลังทำอยู่จริงบน branch อื่น (ยังไม่ merge) —
  backend scoping เสร็จแล้ว ยังไม่มี UI ดูรายละเอียดในไฟล์ ticket

## 🟢 Nice-to-have (backlog, ไม่ตัด ticket แยก)
- ระบบจองโต๊ะ (reservation) ผูกกับผังโต๊ะ
- แจ้งเตือนสต๊อกใกล้หมด/ยกเลิกออเดอร์ผิดปกติ ผ่าน push/LINE Notify
- Flutter integration test กับ backend จริง (README ระบุว่ายังไม่มี มีแค่ unit/widget test)
- เอา pagination ที่ backend รองรับอยู่แล้วมาใช้ฝั่ง app

## นอกเหนือจาก gap analysis เดิม (ผู้ใช้ร้องขอเพิ่มเติมภายหลัง — audit ทั้ง financial และ restaurant manager)
- `13-order-audit-trail.md` — ✅ เสร็จแล้ว — ขยาย audit log (ticket 08) ให้ครอบคลุม
  "ใครกดสั่ง/แก้ไขออเดอร์" สำหรับ**ผู้จัดการร้าน** ไม่ใช่แค่เหตุการณ์เสี่ยงต่อการทุจริต
- `14-financial-audit-trail.md` — ✅ เสร็จแล้ว — audit ระดับ**บัญชี/การเงิน**: แก้ราคาเมนู/
  โปรโมชัน/สต๊อกวัตถุดิบถูก log ครบแล้ว, export audit log เป็น CSV ได้ (เว็บเท่านั้น), มี
  date range picker บน UI (ของค้างจาก ticket 08)
- `15-ai-ask-your-data.md` — ✅ เสร็จแล้ว — **จุดขาย**: AI ถามตอบข้อมูลร้านด้วยภาษาพูด (ยอดขาย/
  เมนูขายดี/ลูกค้า) ผ่าน LLM tool-calling ที่เรียก endpoint จริงในระบบเท่านั้น (กัน hallucinate
  ตัวเลข) ต่อยอดจากดีไซน์ dashboard ที่ทำไว้ก่อนหน้า ดู `docs/DECISIONS.md` #33
- `12-report-export.md` — ✅ เสร็จแล้ว — export รายงานยอดขาย/เมนูขายดี/ยอดขายรายวันเป็น CSV +
  Z-report ต่อกะ/ต่อวัน (scope ด้วย `payments.shift_id` กันกะข้ามเที่ยงคืนนับผิด) — implement บน
  branch `claude/pos-restaurant-project-3djpp6` (commit `4e2684d`) **ขนานกัน** กับตอนที่เซสชันนี้
  เขียน full spec ให้ (`/to-spec`, ก่อนรู้ว่ามีอีก session ทำอยู่แล้ว) — ดู `docs/DECISIONS.md` #35

## พบระหว่างตรวจโค้ดจริงซ้ำ (2026-09-15) — ไม่เคยอยู่ใน gap analysis รอบแรก
- `16-promptpay-qr.md` — ✅ เสร็จแล้ว — 🔴 Critical gap เดียวที่เหลืออยู่หลังจากรายการ 1-4 เดิม
  ทำครบแล้ว: ช่องทางจ่าย "QR" เดิมเป็นแค่ label ไม่มี PromptPay QR จริงให้ลูกค้าสแกน
- ✅ เสร็จแล้ว — self code-review รอบใหม่ (clean code/tech debt/state management/architecture/
  spaghetti) พบว่า `14-financial-audit-trail.md` ยังเหลือรูอยู่ 3 จุด: เปิด/ปิดกะ, รับชำระเงิน,
  กรอก/ถอดโค้ดส่วนลด ไม่มี audit log (จุดหลังไม่มี transaction ห่อด้วย) — ปิดครบแล้ว
  ดู `docs/DECISIONS.md` #28 และหัวข้อ "ส่วนต่อขยาย" ใน `14-financial-audit-trail.md`

## PO re-verify รอบใหม่ (2026-09-19) — ตอบคำถาม "พร้อมให้คนโหลดไปใช้จริงหรือยัง"

ผู้ใช้ถามตรงๆ ว่าฟีเจอร์ตอนนี้ดีพอให้คนโหลดไปใช้จริงหรือยัง (กังวลว่าจะมีคนคิดว่า "ฟรีแต่ฟีเจอร์ไม่พอ
ยอมเสียเงินดีกว่า") แทนที่จะเชื่อสถานะ ✅ เดิม แบ่งตรวจอิสระ 3 ทาง — รายละเอียดเต็มดู
`docs/DECISIONS.md` #35:

- ✅ สุ่มตรวจ 4 ticket ที่ติ๊ก ✅ ไว้ (01 shift, 02 refund, 06 inventory, 07 tax invoice) ยืนยันว่า
  ทำจริงครบ DB+backend+UI ไม่มีจุดที่เป็นของปลอมแบบ ticket 16 เดิม
- ✅ ยืนยัน `11-multi-branch.md` ยัง out-of-scope ตามที่ตั้งใจจริง ไม่มี drift ณ ตอนตรวจ — **ภายหลัง
  พบว่าไม่จริงแล้ว** อีก session เริ่มทำ multi-branch backend อยู่บนอีก branch ขนานกัน (ดูหมายเหตุ
  ในไฟล์ `11-multi-branch.md`) บทเรียนซ้ำกับ #12 ด้านล่าง: "ยืนยันด้วยโค้ดจริง" ยังจำกัดอยู่แค่โค้ดที่
  session นี้มองเห็น ณ ตอนนั้น ไม่ครอบคลุม branch อื่นที่ session อื่นกำลังทำขนานกันอยู่
- 🟠 ยกระดับ `12-report-export.md` เป็น High แล้วเขียน full spec (`/to-spec`) — **ภายหลังพบว่าซ้ำกับ
  งานที่อีก session ทำจริงไปแล้วบน branch อื่น** (`claude/pos-restaurant-project-3djpp6`, commit
  `4e2684d`, ยังไม่ merge เข้า main) เป็นตัวอย่างของ concurrent session ทำงานซ้ำกันในโปรเจกต์นี้ —
  spec ที่เขียนไว้ตรงกับของจริงมาก (โดยเฉพาะจุด scope ด้วย `payments.shift_id`) จึงเก็บไว้เป็น
  reference ไม่ลบทิ้ง แต่ปิด ticket เป็น ✅ เสร็จแล้วตามของจริง ไม่ใช่ตามสเปกที่เขียนไว้
- 🐛 **พบและแก้บั๊กจริงใน ticket 15 (AI assistant)**: โมเดิลตอบข้อความเฉยๆ โดยไม่เรียก
  `submit_answer` เคยหลุดผ่านเป็นคำตอบสุดท้ายได้ (ขัดกฎ "ห้ามเดา/แต่งคำตอบ" ของทิกเก็ตเอง) — แก้แล้ว
  พร้อมเทสต์ยืนยัน (`backend/src/modules/ai-assistant/ai-assistant.service.js`,
  `backend/tests/ai-assistant.test.js`)
