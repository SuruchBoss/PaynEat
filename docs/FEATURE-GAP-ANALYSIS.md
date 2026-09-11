# PaynEat POS — Feature Gap Analysis (มุมมอง PO)

วันที่วิเคราะห์: 2026-09-09
ผู้วิเคราะห์: PO review (ผ่าน Claude Code) โดยอ่านโค้ดจริง + README + `docs/DECISIONS.md`

เอกสารนี้สรุปว่าฟีเจอร์ POS พื้นฐานอะไร **มีอยู่แล้ว** และอะไร **ยังขาด** เทียบกับสิ่งที่ POS
ร้านอาหารทั่วไปต้องมีเพื่อใช้งานจริง (ไม่ใช่แค่ demo/portfolio) ใช้เป็น input สำหรับตัด ticket
พัฒนาต่อ — ดู tickets ที่เกี่ยวข้องใน `docs/tickets/` (สร้างจากเอกสารนี้)

## สิ่งที่มีอยู่แล้ว (ยืนยันจากโค้ดจริง)

- ผังโต๊ะ + สถานะ (available/occupied/reserved/billing), ย้ายโต๊ะ, รวมบิล (merge)
- สั่งอาหาร + modifier/option group, บันทึกครัว, ตะกร้ารวมรายการซ้ำอัตโนมัติ
- ครัว (KDS) realtime ผ่าน Socket.IO, แจ้งเตือนออเดอร์ค้างนาน
- ชำระเงิน 4 ช่องทาง (cash/qr/card/transfer), แบ่งจ่ายหลายช่องทาง, แบ่งบิลตามรายการ/ต่อคน
- ส่วนลดแบบ manual ต่อบิล (%, บาท) และโปรโมชันแบบตั้งเงื่อนไขล่วงหน้า (percent/amount/bogo,
  เงื่อนไขวัน/เวลา/เมนู-หมวดหมู่/ยอดขั้นต่ำ, auto-apply หรือรับโค้ดส่วนลด)
- ใบเสร็จบนหน้าจอ + พิมพ์จริงผ่านเครื่องพิมพ์ความร้อน ESC/POS บนวง LAN/WiFi
- เปิด/ปิดกะ + กระทบยอดเงินสด, คืนเงินหลังชำระเงินแล้ว (เต็มจำนวน/บางส่วน)
- Offline mode สำหรับสั่งอาหารเพิ่มเข้าออเดอร์เดิม (queue ในเครื่อง + sync อัตโนมัติ)
- Dashboard + รายงานย้อนหลัง (ยอดขายรายวัน, สินค้าขายดี, สัดส่วนการชำระเงิน)
- จัดการเมนู/หมวดหมู่, จัดการพนักงาน + RBAC 5 role (admin/manager/waiter/cashier/kitchen)
- ตั้งค่าร้าน (VAT rate, service charge, VAT-inclusive toggle)
- คำนวณ VAT + service charge ตรงกันทั้ง frontend/backend มี test คุม

ที่มา: `README.md`, `docs/DECISIONS.md`, `backend/src/db/schema.sql`,
`app/lib/features/**`, `backend/src/modules/**`

## Gap ที่พบ (เรียงตามความสำคัญ)

### 🔴 Critical — บล็อกการใช้งานจริง (ร้านจริงต้องมี ไม่ใช่ของเสริม)

✅ **ทำครบแล้วทั้ง 4 รายการ** (ดูรายละเอียดที่ `docs/tickets/01-04-*.md` และ
`docs/DECISIONS.md` #11/#13 สำหรับขอบเขตที่ตั้งใจจำกัดไว้)

| # | ฟีเจอร์ที่ขาด | ทำไมสำคัญ | สถานะ |
|---|---|---|---|
| 1 | เปิด/ปิดกะ + กระทบยอดเงินสด (Shift & Cash Drawer Reconciliation) | ไม่มี table `shift`/`cash_session` เลย ร้านจริงต้องนับเงินตั้งต้น/ปิดกะเทียบยอดระบบ ไม่งั้นตรวจสอบเงินหายไม่ได้ | ✅ เสร็จแล้ว |
| 2 | คืนเงินหลังชำระเงินแล้ว (Refund) | มีแค่ "cancel" ก่อนเสิร์ฟ/ก่อนจ่าย ไม่มี flow คืนเงินหลังจ่ายสำเร็จ ไม่มี table `refunds` เลย | ✅ เสร็จแล้ว |
| 3 | พิมพ์ใบเสร็จจริง (Thermal/ESC-POS printer) | ปัจจุบันมีแค่ใบเสร็จบนจอ (ตั้งใจไม่ทำตาม `docs/DECISIONS.md` เพราะเป็น demo) แต่ร้านจริงต้องมี | ✅ เสร็จแล้ว (LAN/WiFi — Bluetooth/USB ยังไม่ทำ ดู #11) |
| 4 | Offline mode | เน็ตร้านอาหารหลุดบ่อย ตอนนี้ order พึ่ง backend ตลอด ไม่มี local queue + sync กลับ | ✅ เสร็จแล้ว (เฉพาะสั่งเพิ่มเข้าออเดอร์เดิม ดู #13) |

### 🟠 High — ควรมีเร็ว ๆ นี้เพื่อแข่งขันได้

| # | ฟีเจอร์ที่ขาด | ทำไมสำคัญ | สถานะ |
|---|---|---|---|
| 5 | ส่วนลด/โปรโมชันแบบมีเงื่อนไข (Promotion Engine) | ตอนนี้ลดได้แค่ manual ต่อบิล ไม่มี happy hour, โค้ดส่วนลด, buy-1-get-1, ตามช่วงเวลา/เมนู | ✅ เสร็จแล้ว (ดู `docs/tickets/05-promotion-engine.md`, `docs/DECISIONS.md` #14) |
| 6 | สต๊อก/วัตถุดิบ (Inventory) | ไม่มี table stock ขายของหมดก็ยังสั่งได้ (มีแค่ toggle sold-out มือ) ไม่ตัดสต๊อกอัตโนมัติ ไม่แจ้งเตือนของใกล้หมด | ✅ เสร็จแล้ว (ดู `docs/tickets/06-inventory-stock.md`, `docs/DECISIONS.md` #15) |
| 7 | ใบกำกับภาษี (Tax Invoice / e-Tax) | ยังไม่รองรับข้อกำหนดใบกำกับภาษีของไทย จำเป็นถ้าจะขายให้ร้านที่จด VAT จริง | |
| 8 | Audit log | ไม่มี log ว่าใครลบ/ยกเลิกออเดอร์ ใครให้ส่วนลดพิเศษ/แก้ราคา — จำเป็นป้องกันทุจริตหน้าร้าน | |

### 🟡 Medium — เพิ่มมูลค่า/ขยายธุรกิจ

| # | ฟีเจอร์ที่ขาด | ทำไมสำคัญ |
|---|---|---|
| 9 | ลูกค้า/สมาชิก/แต้มสะสม (Customer & Loyalty) | ไม่มี table customer ผูกประวัติซื้อ/สมาชิกไม่ได้ |
| 10 | Takeaway/Delivery flow เต็มรูปแบบ | schema มี `type: dine_in/takeaway/delivery` แต่ UI/logic ทำแต่ dine-in ไม่มีคิวรับอาหาร ไม่เชื่อม Grab/LINE MAN |
| 11 | Multi-branch/multi-store | ตั้งใจ scope สาขาเดียวไว้ก่อน (repository layer แยกไว้รองรับ Postgres ในอนาคต) |
| 12 | Export รายงาน (Excel/CSV/PDF) + End-of-day / Z-report | ปัจจุบันดูได้แค่ในแอป ยังส่งบัญชีไม่ได้ |

### 🟢 Nice-to-have

- ระบบจองโต๊ะ (reservation) ผูกกับผังโต๊ะ
- แจ้งเตือนสต๊อกใกล้หมด/ยกเลิกออเดอร์ผิดปกติ ผ่าน push/LINE Notify
- Flutter integration test กับ backend จริง (README ระบุว่ายังไม่มี มีแค่ unit/widget test)
- เอา pagination ที่ backend รองรับอยู่แล้วมาใช้ฝั่ง app (ตอนนี้โหลดเมนูทั้งหมดมา filter ฝั่ง client — จะมีปัญหาเมื่อเมนูเยอะขึ้น)

## คำแนะนำลำดับพัฒนา (Roadmap)

1. ✅ **Sprint แรก (เสร็จแล้ว)**: 4 รายการ 🔴 (เปิด-ปิดกะ, refund, พิมพ์ใบเสร็จจริง, offline mode) — เป็น "ของที่ POS ทุกตัวต้องมี" ไม่ใช่ของเสริม
2. **เฟส 2** (โปรโมชัน + สต๊อก ✅ เสร็จแล้ว, เหลือ 2 รายการ 🟠: ใบกำกับภาษี, audit log) — เพื่อแข่งขันกับ POS เจ้าอื่นได้
3. **เฟส ขยายธุรกิจ**: 🟡 (ลูกค้า/loyalty, takeaway/delivery, multi-branch, export รายงาน)
4. **Backlog**: 🟢 nice-to-have ตามความเหมาะสม
