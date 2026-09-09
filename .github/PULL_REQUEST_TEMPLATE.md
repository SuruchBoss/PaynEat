## สรุปการเปลี่ยนแปลง

<!-- อธิบายว่าแก้อะไร ทำไม (ไม่ใช่แค่ "ทำอะไร") — ถ้าแก้บั๊ก ลิงก์ Issue ด้วย เช่น Fixes #12 -->

## วิธีทดสอบ

<!-- อธิบายว่าทดสอบยังไง เช่น เพิ่มเทสต์เคสไหน หรือขั้นตอนทดสอบด้วยมือ -->

## Checklist

- [ ] อ่าน [`CONTRIBUTING.md`](../CONTRIBUTING.md) แล้ว
- [ ] เพิ่ม/แก้เทสต์คู่กับโค้ดที่เปลี่ยน (หรืออธิบายว่าทำไมไม่ต้องมี)
- [ ] รันชุดตรวจสอบผ่านครบแล้ว (ดูรายละเอียดใน CONTRIBUTING.md):
  ```bash
  cd app && flutter analyze && dart format --output=none --set-exit-if-changed . && flutter test
  cd backend && npm run format:check && npm run lint && npm test
  ```
- [ ] ถ้าแตะ domain/data layer แล้ว — ตรวจ layer violation ตามหัวข้อ 4.3 ใน `docs/CODING_STANDARDS.md`
- [ ] ถ้าเป็นฟีเจอร์ใหม่ที่กระทบพฤติกรรมที่มีอยู่ — อัปเดต README/docs ที่เกี่ยวข้องด้วย

## หมายเหตุอื่นๆ

<!-- สิ่งที่ reviewer ควรรู้เพิ่มเติม เช่น trade-off ที่ยอมรับ, ส่วนที่ยังไม่สมบูรณ์ -->
