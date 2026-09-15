# ร่วมพัฒนา PaynEat POS

ขอบคุณที่สนใจร่วมพัฒนา! เอกสารนี้สรุปขั้นตอนตั้งแต่ตั้งค่าเครื่องจนถึงเปิด Pull Request

## เตรียมเครื่อง

ทำตาม [🚀 วิธีรัน ใน README](README.md#-วิธีรัน-สำหรับผู้ที่มาตรวจผลงาน) เพื่อรันทั้ง backend
และแอปในเครื่องให้ได้ก่อน — ใช้เวลาประมาณ 5 นาที

โครงสร้างโปรเจกต์เป็น monorepo 2 ส่วน:

- `app/` — Flutter (GetX + Clean Architecture) รันได้ทั้ง Android/iOS/Web
- `backend/` — Node.js/Express + SQLite + Socket.IO

## ก่อนเริ่มเขียนโค้ด

- อ่าน [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md) — มาตรฐาน Clean Code, การใช้ GetX,
  ทิศทาง dependency ของ Clean Architecture และตำแหน่งไฟล์ตามชั้นสถาปัตยกรรม
- อ่าน [`docs/DECISIONS.md`](docs/DECISIONS.md) — เหตุผลเบื้องหลังการตัดสินใจเชิงออกแบบที่สำคัญ
  (เช่น ทำไมเก็บเงินเป็นสตางค์, ทำไมเลือก SQLite) กันเสนอเปลี่ยนสิ่งที่ตั้งใจทำแบบนี้อยู่แล้วโดยไม่รู้ตัว
- ถ้าจะทำฟีเจอร์ใหญ่หรือเปลี่ยนสถาปัตยกรรม แนะนำเปิด Issue คุยแนวทางก่อนลงมือ กันเสียเวลาทำแล้วไม่ตรงทิศทาง

## Workflow

1. Fork repo แล้ว clone เครื่องตัวเอง
2. สร้าง branch ใหม่จาก `main` ตั้งชื่อสื่อความหมาย เช่น `fix/split-bill-rounding` หรือ
   `feat/loyalty-points`
3. เขียนโค้ด + เทสต์คู่กัน (ดูหัวข้อเทสต์ด้านล่าง)
4. รันชุดตรวจสอบให้ผ่านครบก่อน commit (ดูหัวข้อถัดไป)
5. Commit ด้วยข้อความสื่อความหมาย — จะเขียนไทยหรืออังกฤษก็ได้ แต่ให้บอกว่า "ทำไม" ไม่ใช่แค่ "ทำอะไร"
   โปรเจกต์นี้ใช้รูปแบบ `type(scope): คำอธิบาย` เช่น `feat(app): ...`, `fix(backend): ...`,
   `docs: ...` — ไม่บังคับแต่แนะนำให้ตามเพื่อความสม่ำเสมอ
6. Push แล้วเปิด Pull Request เข้า `main` อธิบายว่าแก้อะไร ทำไม และทดสอบยังไง

## ก่อน commit / เปิด PR ต้องผ่านครบ — ไม่มีข้อยกเว้น

```bash
# Flutter (โฟลเดอร์ app/)
flutter analyze                                    # ต้องขึ้น "No issues found!"
dart format --output=none --set-exit-if-changed .  # ต้อง exit 0
flutter test                                        # ต้องขึ้น "All tests passed!"

# Backend (โฟลเดอร์ backend/)
npm run format:check                                # ต้องขึ้น "All matched files use Prettier code style!"
npm run lint                                        # ต้อง 0 errors, 0 warnings
npm test                                            # ต้อง fail 0
```

CI (`.github/workflows/ci.yml`) รันชุดเดียวกันนี้อัตโนมัติทุก push/PR — PR ที่ CI ไม่ผ่านจะไม่ถูก merge

### แนวทางเขียนเทสต์

- เพิ่มฟีเจอร์ = ต้องมีเทสต์คู่กันเสมอ ทั้งสองฝั่งถ้าตรรกะซ้ำกัน (เช่นการคิดบิลที่เขียนไว้ทั้ง Dart
  และ JavaScript ดู [`docs/DECISIONS.md`](docs/DECISIONS.md) #2)
- Controller ฝั่ง Flutter ที่แตะ `Get.snackbar`/`Get.dialog`/`Get.offNamed` โดยไม่มี `GetMaterialApp`
  จริงจะ crash ในเทสต์ระดับ unit — ครอบคลุมเฉพาะ guard/early-return หรือ pure computation
  (ดูตัวอย่างและเหตุผลในหัวข้อ 6.2 ของ `docs/CODING_STANDARDS.md`)
- แก้ไฟล์ในชั้น domain/data → รันคำสั่งตรวจ layer violation ในหัวข้อ 4.3 ของ CODING_STANDARDS.md ด้วย

## รายงานบั๊ก / เสนอฟีเจอร์

เปิด [Issue](https://github.com/SuruchBoss/PaynEat/issues) พร้อมข้อมูล:

- **บั๊ก**: ขั้นตอนทำซ้ำ, ผลที่คาดหวัง vs ที่เกิดจริง, เวอร์ชัน Flutter/Node ที่ใช้
- **เสนอฟีเจอร์**: ปัญหาที่อยากแก้ (ไม่ใช่แค่วิธีแก้ที่คิดไว้) จะได้คุยแนวทางที่เหมาะสมที่สุดร่วมกันได้

> ⚠️ **พบช่องโหว่ด้านความปลอดภัย?** ห้ามเปิดเป็น public Issue — ทำตาม [`SECURITY.md`](SECURITY.md) แทน

## มารยาท

ให้เกียรติกันในการรีวิวโค้ดและคอมเมนต์ — วิจารณ์ที่โค้ด ไม่ใช่ที่ตัวคน ทุกคนที่มีส่วนร่วมในโปรเจกต์นี้
ต้องปฏิบัติตาม [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)

## License

โค้ดที่ contribute เข้ามาจะอยู่ภายใต้สัญญาอนุญาต Apache License 2.0 เดียวกับโปรเจกต์ (ดู [`LICENSE`](LICENSE)
และ [`NOTICE`](NOTICE))
