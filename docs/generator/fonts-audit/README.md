# ฟอนต์ Waree (เฉพาะรายงานตรวจคุณภาพโค้ด)

`Waree-Regular.ttf` / `Waree-Bold.ttf` จากแพ็กเกจ `fonts-tlwg-waree` (Thai Linux Working Group)
สัญญาอนุญาต GPL-2+ with Font Exception — ฝังในเอกสาร/แจกจ่ายได้อิสระ
ที่มา: https://linux.thai.net/pub/thailinux/software/fonts-tlwg

## ทำไมไม่ใช้ Noto Sans Thai เหมือนเอกสารอื่น

`docs/PaynEat-POS-Audit-Report-TH.pdf` สร้างด้วยฟอนต์นี้แทน Noto Sans Thai เพราะพบว่า
Noto Sans Thai ชนกับบั๊กของ **Chromium print-to-PDF** ที่ทำให้ข้อความไทยที่มีวรรณยุกต์/สระซ้อน
(เช่น "ผ่าน", "ด้วย", "เกินไป") ถูกคัดลอก (copy-paste) ออกมาผิดเพี้ยน ตัวอักษรซ้ำหรือสลับที่
— ทั้งที่แสดงผลบนหน้าจอ/พิมพ์ออกมาถูกต้อง 100%

ทดสอบแล้วว่าบั๊กนี้เกิดกับ Noto Sans Thai ใน **ทุก** เอนจินที่ลอง (Chromium ปกติ, Chromium
tagged-pdf, WeasyPrint, LibreOffice) แต่ฟอนต์ตระกูล TLWG (Waree, Kinnari, Umpush) ให้ผล
คัดลอกถูกต้อง 100% ในทุกกรณีทดสอบ จึงเปลี่ยนมาใช้ Waree เฉพาะเอกสารนี้ที่เน้นให้คัดลอกข้อความ
ไปใช้ต่อได้ (ต่างจากเอกสารฟีเจอร์ที่เน้นความสวยงามของภาพหน้าจอเป็นหลัก)
