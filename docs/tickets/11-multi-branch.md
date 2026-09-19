# Ticket: Multi-branch / Multi-store Support

**Priority:** 🟡 Medium
**Status:** 🚧 **กำลังทำอยู่ (บน branch อื่น)** — พบว่าอีก session เริ่มงานนี้จริงแล้วบน branch
`claude/pos-restaurant-project-3djpp6` (commit `68568c1`, ยังไม่ merge เข้า `main` ณ ตอนที่เขียน
บันทึกนี้) ขณะที่เซสชันนี้เพิ่งยืนยันไปเมื่อ 2026-09-19 ว่า "ยัง out-of-scope ไม่มี drift" (ดู
`docs/DECISIONS.md` #35/#36) — เป็นอีกตัวอย่างของ concurrent session ทำงานซ้อนกัน ของจริงที่ทำไปแล้ว:
เพิ่ม `branch_id` scoping ให้ tables/menu/ingredients/orders/reports ฝั่ง backend ครบ + RBAC + 16
เทสต์ใหม่ (`backend/tests/branches.test.js`) — **backend เท่านั้น ยังไม่มี branch-management UI /
เลือกสาขาตอน login ฝั่ง Flutter** (ตาม commit message ของ branch นั้นเอง) ดังนั้น Acceptance Criteria
ด้านล่างนี้ยังไม่ครบทั้งหมด — เมื่อ branch นั้น merge เข้า main แล้วควรอัปเดตบันทึกนี้ให้ตรงกับสถานะ
จริงอีกครั้ง (backend เสร็จบางส่วน / frontend ยังไม่เริ่ม)
**Ref:** `docs/FEATURE-GAP-ANALYSIS.md` #11

## ปัญหา
ระบบตั้งใจ scope ไว้แค่สาขาเดียวตั้งแต่ต้น (`docs/DECISIONS.md`) — ใช้ SQLite ไฟล์เดียว,
`settings` เป็น key-value เดียวไม่ผูกกับสาขา, ไม่มี table `branches`/`stores`

## ทำไมสำคัญ
ถ้าลูกค้าเป้าหมายของ PaynEat มีแผนขยายสาขา ระบบปัจจุบันรองรับไม่ได้เลย ต้องวางแผน
migration ทั้ง database (SQLite → PostgreSQL ตามที่ `docs/DECISIONS.md` เตรียม repository
layer ไว้รองรับ) และ data model (เพิ่มมิติ branch เข้าไปแทบทุก entity)

## ขอบเขตงาน (คร่าวๆ) — งานใหญ่ ควรแตกเป็นหลาย ticket ย่อยเมื่อจะเริ่มทำจริง
- ตัดสินใจ database migration path: SQLite → PostgreSQL (repository layer แยกไว้แล้วตาม
  design decision เดิม ควรกระทบ service/controller น้อย)
- Schema: เพิ่ม table `branches`, เพิ่ม `branch_id` FK ในแทบทุก entity (menu_items,
  dining_tables, orders, users-to-branch mapping, settings ต่อสาขา)
- Backend: ทุก query ต้อง scope ด้วย branch_id, auth/JWT ต้องพก branch context
- Frontend: เลือกสาขาตอน login (ถ้า user มีสิทธิ์หลายสาขา), แยกข้อมูล/รายงานตามสาขา,
  รายงานภาพรวมข้ามสาขาสำหรับ owner/admin ระดับองค์กร

## Acceptance Criteria
- [ ] มี table branches และทุก entity หลักผูกกับ branch_id
- [ ] User ที่มีสิทธิ์หลายสาขาเลือกสาขาที่จะทำงานได้ตอน login
- [ ] ข้อมูล/รายงานแยกตามสาขาไม่ปนกัน
- [ ] Owner/admin ระดับองค์กรดูรายงานสรุปรวมทุกสาขาได้

## หมายเหตุ
ควร grill/ประเมิน scope นี้กับ PO ก่อนเริ่ม เพราะกระทบ architecture มากที่สุดในบรรดา
ticket ทั้งหมด แนะนำให้ทำหลัง Critical + High priority เสร็จก่อน
