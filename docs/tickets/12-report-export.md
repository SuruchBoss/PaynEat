# Ticket: Export รายงาน (Excel/CSV/PDF) + End-of-day / Z-report

**Priority:** 🟡 Medium
**Ref:** `docs/FEATURE-GAP-ANALYSIS.md` #12

## ปัญหา
รายงานปัจจุบัน (`reports_page.dart`, `/reports/summary`, `/reports/top-items`,
`/reports/sales-by-day`) ดูได้แค่ในแอปเท่านั้น ไม่มีทาง export เป็นไฟล์เพื่อส่งต่อฝ่ายบัญชี
และไม่มีรายงานสรุปปิดวัน (End-of-day/Z-report) แบบมาตรฐาน

## ทำไมสำคัญ
ร้านอาหารต้องส่งข้อมูลยอดขายให้ฝ่ายบัญชี/สำนักงานบัญชีภายนอกเป็นประจำ การดูได้แค่ในแอป
ไม่พอ ต้อง export เป็นไฟล์ได้ และ Z-report (สรุปยอดขาย/ภาษี/ส่วนลด/ช่องทางชำระเงินของวันนั้น)
เป็นเอกสารมาตรฐานที่ POS ต้องมี

## ขอบเขตงาน (คร่าวๆ)
- Backend: endpoint export รายงาน (summary/top-items/sales-by-day) เป็น CSV/Excel
  อย่างน้อย 1 format, endpoint สร้าง Z-report ต่อวัน/ต่อกะ (ผูกกับ ticket #1 shift ถ้าทำ
  พร้อมกัน)
- Frontend: ปุ่ม export ในหน้ารายงาน, หน้าจอ/ปุ่มพิมพ์-ดาวน์โหลด Z-report ตอนปิดกะ/ปิดวัน

## Acceptance Criteria
- [x] Export รายงานยอดขาย (ตามช่วงวันที่ที่เลือก) เป็นไฟล์ CSV/Excel ได้ — ทำแล้ว: CSV (สรุปยอดขาย/
  เมนูขายดี/ยอดขายรายวัน แยกปุ่มกันที่หน้ารายงาน)
- [x] มี Z-report สรุปยอดขาย/ภาษี/ส่วนลด/แยกตามช่องทางชำระเงินต่อวัน/ต่อกะ — ทำแล้ว: ต่อกะมีกระทบยอด
  เงินสดด้วย (คิดจาก `payments.shift_id`), ต่อวันรวมทุกกะ (ไม่มีกระทบยอดเงินสด)
- [x] Export/ดาวน์โหลด Z-report เป็นไฟล์ (PDF หรือเทียบเท่า) ได้ — ทำแล้ว: CSV (เทียบเท่าตามที่ระบุไว้
  — ดู `docs/DECISIONS.md` #35 สำหรับเหตุผลไม่ทำ Excel/PDF)

## ไฟล์ที่เกี่ยวข้อง
- `backend/src/modules/reports/`
- `app/lib/features/report/`
- เกี่ยวโยงกับ ticket `01-shift-cash-reconciliation.md` ถ้า Z-report ผูกกับกะ
