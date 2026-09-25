# Ticket: ส่งยอดขายเข้า PaynEat ERP ผ่าน outbox — ครั้งเดียวแน่นอน แม้เน็ตหลุด

**Priority:** 🟠 High — สัปดาห์ที่ 4 ของแผน PaynEat ERP v1
**Ref:** [ERP ADR-0002](https://github.com/SuruchBoss/PaynEat-ERP/blob/main/docs/adr/0002-system-boundaries-and-pos-integration.md),
[สัญญา telemetry v1](https://github.com/SuruchBoss/PaynEat-ERP/blob/main/docs/TELEMETRY.md), `docs/DECISIONS.md` #66
**Blocked by:** `25-erp-connected-mode.md`, [PaynEat-ERP#9](https://github.com/SuruchBoss/PaynEat-ERP/issues/9)

## ปัญหา
ERP ต้องรู้ว่าแต่ละสาขาขายอะไรไป เพื่อคำนวณการใช้วัตถุดิบตามสูตร ต้นทุน และการย้อนรอย lot แต่เน็ตหน้าร้านหลุดได้เป็นชั่วโมง
ถ้าส่งตรงตอนขาย ยอดจะหายตอนเน็ตหลุด ถ้า retry แบบไม่ระวัง ยอดจะนับซ้ำ

## ทำไมสำคัญ
เป็นครึ่งหนึ่งของเส้นทาง demo "จากจานย้อนกลับไปถึง lot ของซัพพลายเออร์" และเป็นจุดที่ SherWhyve จะถูกใช้สืบสวนบ่อยที่สุด
("ยอดขายสาขา 2 ไม่เข้า ERP")

## ขอบเขตงาน
- **ส่งเมื่อไร**: เมื่อบิลถูก**ชำระครบ** ส่งหนึ่ง event ต่อบรรทัดขายที่ไม่ถูกยกเลิก
  - เวลาขาย = เวลาที่ชำระครบ
  - บรรทัดชั่งน้ำหนักส่งน้ำหนักจริง (kg)
  - ส่ง modifier ไปด้วย
  - ให้บันทึกความหมายนี้ในสัญญาฝั่ง ERP ด้วย ดูคอมเมนต์ใน PaynEat-ERP#9
- **outbox**: เขียนแถว event ลงตาราง outbox **ใน transaction เดียวกับการชำระเงิน** ถ้าการชำระเงินล้ม ต้องไม่มีแถว outbox
  - idempotency key คงที่ต่อบรรทัดขาย (เช่น `<pos-instance>:<order-item-id>`) และไม่เปลี่ยนเมื่อ retry
  - ทำเฉพาะโหมดเชื่อมต่อ ส่วนโหมดเดี่ยวไม่เขียนแถวใดๆ
- **ตัวส่ง** (background): ส่งตามลำดับ retry แบบ exponential backoff ใส่ `x-request-id` = idempotency key
  - ERP ตอบ "ซ้ำ" = สำเร็จ
  - 422 = dead-letter พร้อมเหตุผล
  - credential ถูกเพิกถอน (401) = หยุดส่งทั้งคิวและแจ้งเตือน admin
  - พยายามครบ N ครั้งแล้วยังไม่ผ่าน = dead-letter
- **หน้าจอสถานะ outbox** (admin/manager): จำนวนที่รอส่ง, อายุของรายการที่เก่าที่สุด, รายการ dead-letter พร้อมเหตุผล
  และปุ่มส่งใหม่
- **telemetry v1**:
  - metric `outbox_pending_events{app,destination}` และ `outbox_oldest_pending_age_seconds{app,destination}`
  - log `outbox.delivery.failed` (`WARNING`, และ `ERROR` เมื่อ dead-letter) โดยมี idempotency key เป็น `correlation_id`
- **contract test**: event ที่ POS สร้างต้องผ่าน JSON Schema ของ sales event v1 จาก ERP ใน CI

## ขอบเขตที่ตั้งใจไม่ทำ (ช่องว่างที่รู้ตัว บันทึกใน DECISIONS #66)
- คืนเงินหรือ void หลังชำระแล้ว ยังไม่ส่งเข้า ERP ใน v1 (อาหารที่คืนเงินส่วนใหญ่ถูกทำไปแล้ว ส่วนต่างให้ ERP จับด้วยการตรวจนับ)
- อาหารที่ทำแล้วแต่ถูกยกเลิกก่อนชำระ (ของเสีย) ยังไม่ส่ง
- การสแกน lot ที่สาขา (ERP ADR-0006)

## Acceptance Criteria
- [ ] ชำระบิลในโหมดเชื่อมต่อ → หนึ่งแถว outbox ต่อบรรทัดที่ไม่ถูกยกเลิก ใน transaction เดียวกับการชำระ
- [ ] ERP ล่ม → รอส่งแล้วส่งครบเมื่อ ERP กลับมา ERP ไม่นับซ้ำ (idempotency key คงที่)
- [ ] ERP ตอบซ้ำ = สำเร็จ, 422 = dead-letter พร้อมเหตุผล, 401 = หยุดคิวและแจ้งเตือน
- [ ] บรรทัดชั่งน้ำหนักส่งน้ำหนัก และส่ง modifier ครบ
- [ ] โหมดเดี่ยวไม่มีแถว outbox เลย
- [ ] metric และ log ตามสัญญา telemetry v1, contract test ผ่าน
- [ ] README (ไทย/อังกฤษ), `docs/DECISIONS.md`, `docs/FEATURE-GAP-ANALYSIS.md` อัปเดตตาม `CLAUDE.md`

## เทสต์
backend ใช้ stub server ของ ERP ครอบคลุม: ส่งสำเร็จ, ERP ล่มแล้วกลับมา, ตอบซ้ำ, 422, 401, การชำระล้มแล้วต้องไม่มีแถว
outbox, บรรทัดชั่งน้ำหนัก และโหมดเดี่ยว
E2E ฝั่งแอป: ชำระบิลแล้วหน้าจอสถานะ outbox แสดงรายการรอส่ง
