# Ticket: Multi-branch / Multi-store Support

**Priority:** 🟡 Medium
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
