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
- `11-multi-branch.md` — ✅ เสร็จแล้ว — backend scope 4 entity (โต๊ะ/เมนู/ออเดอร์/วัตถุดิบ) ตาม
  `branch_id` + หน้าเลือก/สลับสาขาใน Flutter (`branch_selection_page.dart`) โหมดสาธิตยังมีสาขาเดียว
  โดยตั้งใจ ดู `docs/DECISIONS.md` #36
- `12-report-export.md` — ✅ เสร็จแล้ว — export รายงานขาย (สรุป/เมนูขายดี/รายวัน) เป็น CSV และ
  Z-report ปิดกะ/ปิดวัน (ต่อกะมีกระทบยอดเงินสด คิดจาก `payments.shift_id` จึงถูกต้องแม้ออเดอร์
  หรือกะจะข้ามวัน) ดู `docs/DECISIONS.md` #35

## 🟠 ร้านเนื้อ + ขายส่ง B2B (ผู้ใช้จริงรายแรก 2026-09-23 — ไม่อยู่ใน gap analysis รอบแรก)
- `18-sell-by-weight.md` — ✅ เสร็จแล้ว — ราคาต่อกิโลกรัม น้ำหนักเก็บเป็นกรัม ราคาตรงกันทุกสตางค์ทั้ง
  ตะกร้า/backend/ใบเสร็จ ตัดสต๊อกเป็น กก. ดู `docs/DECISIONS.md` #48, #51
- `19-barcode-scale.md` — ✅ เสร็จแล้ว — สแกนบาร์โค้ดสินค้า + ฉลากตาชั่ง EAN-13 (น้ำหนักอยู่ในรหัส)
  ตั้งรูปแบบฉลากได้ อ่านรหัสในเครื่อง ดู `docs/DECISIONS.md` #49
- `20-b2b-credit.md` — ✅ เสร็จแล้ว — ขายเชื่อตามวงเงิน/เครดิตเทอม ใบวางบิล ใบเสร็จรับชำระหนี้ อายุหนี้
  เงินสดที่รับชำระนับเข้าลิ้นชักตอนปิดกะ ดู `docs/DECISIONS.md` #50

## 🟢 Nice-to-have (backlog, ไม่ตัด ticket แยก)
- ระบบจองโต๊ะ (reservation) ผูกกับผังโต๊ะ
- แจ้งเตือนสต๊อกใกล้หมด/ยกเลิกออเดอร์ผิดปกติ ผ่าน push/LINE Notify
- ~~Flutter integration test กับ backend จริง~~ ✅ เสร็จแล้ว — ชุด E2E `app/test_e2e/` (42 เคส) เปิด
  backend ตัวจริงแล้วให้โค้ดชั้น data/domain ของแอปเดินหนึ่งวันทำงานของร้าน รอบแรกเจอบั๊กจริง 5 ตัวใน
  ticket 02/07/12/17 แก้แล้วทั้งหมด ดู `docs/DECISIONS.md` #43–#47
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

## เทียบกับตลาดรอบใหม่ (2026-09-19)
- `17-qr-self-order.md` — ✅ เสร็จแล้ว — 1 ใน 3 gap ที่เหลือเทียบกับ POS คู่แข่งในตลาดไทย (อีก 2 คือ
  เชื่อมแพลตฟอร์มเดลิเวอรีและ payment gateway อัตโนมัติ ซึ่งตั้งใจไม่ทำ ดู `docs/DECISIONS.md`
  #23/#26): ลูกค้าสแกน QR ที่โต๊ะแล้วสั่งอาหารเองจากมือถือตัวเองได้โดยไม่ต้อง login ผ่าน endpoint
  สาธารณะที่ reuse business logic เดิมทั้งหมด ดู `docs/DECISIONS.md` #37

## PO re-verify รอบใหม่ (2026-09-19) — ตอบคำถาม "พร้อมให้คนโหลดไปใช้จริงหรือยัง"

ผู้ใช้ถามตรงๆ ว่าฟีเจอร์ตอนนี้ดีพอให้คนโหลดไปใช้จริงหรือยัง (กังวลว่าจะมีคนคิดว่า "ฟรีแต่ฟีเจอร์ไม่พอ
ยอมเสียเงินดีกว่า") แทนที่จะเชื่อสถานะ ✅ เดิม แบ่งตรวจอิสระ 3 ทาง — รายละเอียดเต็มดู
`docs/DECISIONS.md` #38:

- ✅ สุ่มตรวจ 4 ticket ที่ติ๊ก ✅ ไว้ (01 shift, 02 refund, 06 inventory, 07 tax invoice) ยืนยันว่า
  ทำจริงครบ DB+backend+UI ไม่มีจุดที่เป็นของปลอมแบบ ticket 16 เดิม
- 🐛 **พบและแก้บั๊กจริงใน ticket 15 (AI assistant)**: โมเดิลตอบข้อความเฉยๆ โดยไม่เรียก
  `submit_answer` เคยหลุดผ่านเป็นคำตอบสุดท้ายได้ (ขัดกฎ "ห้ามเดา/แต่งคำตอบ" ของทิกเก็ตเอง) — แก้แล้ว
  พร้อมเทสต์ยืนยัน (`backend/src/modules/ai-assistant/ai-assistant.service.js`,
  `backend/tests/ai-assistant.test.js`)
- ⚠️ **บทเรียนเรื่อง session ทำงานขนานกัน**: รอบตรวจนั้นสรุปว่า ticket 11 ยัง out-of-scope และ
  ticket 12 ยังไม่ได้ทำ จึงเขียน full spec (`/to-spec`) ของ 12 ขึ้นมาใหม่ — ทั้งสองข้อไม่จริง ทั้งคู่
  ถูกทำเสร็จอยู่ก่อนแล้วบน branch `claude/pos-restaurant-project-3djpp6` (ticket 12 ที่ commit
  `4e2684d`, ticket 11 ครบทั้ง backend และ UI) และตอนนี้ merge เข้า `main` แล้ว — "ยืนยันด้วยโค้ดจริง"
  ครอบคลุมแค่โค้ดที่ session นั้นมองเห็น ไม่รวม branch อื่นที่ทำขนานกันอยู่ ครั้งหน้าต้องเช็ค branch
  ที่ยัง active ก่อนสรุปว่างานยังไม่ได้ทำ
