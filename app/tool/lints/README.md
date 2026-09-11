# payneat_lints

กฎ lint เฉพาะของโปรเจกต์นี้ ใช้ดักรูปแบบการเขียนที่**เคยทำให้เกิดบั๊กจริงมาแล้ว**ในโค้ดเบสนี้
ไม่ใช่กฎสไตล์ทั่วไป — ถ้าอยากได้กฎสไตล์ ใช้ `flutter_lints` ที่ include ไว้แล้วใน
`analysis_options.yaml`

กฎจะขึ้นเส้นหยักใน IDE ให้เห็นตั้งแต่ตอนพิมพ์ และรันซ้ำใน CI ด้วย `dart run custom_lint`

## กฎที่มี

### `text_style_needs_font_family`

ดัก `TextStyle(...)` ที่สร้างขึ้นใหม่โดยไม่ระบุ `fontFamily` ในตำแหน่งที่ Flutter
จะเอาไป **แทนที่** สไตล์เดิมทั้งก้อน แทนที่จะ merge กับธีม

**ทำไมต้องมี** — บั๊กนี้เกิดจริงในโปรเจกต์นี้มาแล้วสองครั้ง และทั้งสองครั้ง
อักษรไทยกลายเป็นกล่องสี่เหลี่ยมบนหน้าจอจริง:

| ครั้งที่ | จุดที่พัง | อาการ |
|---|---|---|
| 1 | `ButtonStyle.textStyle` ของปุ่มเดินสถานะอาหาร | ปุ่ม "เริ่มทำ" กลายเป็น `◻◻◻◻◻◻◻` |
| 2 | `NavigationRail.selectedLabelTextStyle` | ชื่อเมนู "ครัว" / "บัญชี" กลายเป็นกล่อง |

ครั้งที่สองเกิดขึ้น**ทั้งที่มีคอมเมนต์เตือนเรื่องนี้อยู่แล้ว**ใน `lib/app/theme/app_theme.dart`
— ซึ่งเป็นเหตุผลที่ต้องเปลี่ยนจากคอมเมนต์มาเป็นกฎที่บังคับได้

**เขียนยังไงให้ผ่าน**

```dart
// ✅ copyWith ต่อจากสไตล์ของธีม — วิธีที่แนะนำ เพราะได้ทั้งฟอนต์และค่าอื่นของธีมมาด้วย
textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12.5)

// ✅ ระบุ fontFamily ตรง ๆ — ใช้ตอนอยู่ใน const context ที่เรียก Theme.of ไม่ได้
selectedLabelTextStyle: const TextStyle(
  fontFamily: AppTheme.fontFamily,
  fontSize: 13,
)

// ❌ TextStyle เปล่า — ฟอนต์จะหลุดไปใช้ค่า default ของแต่ละแพลตฟอร์ม
textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)
```

**ขอบเขตของกฎ**

กฎดูทั้ง "ชื่อ widget" และ "ชื่อพารามิเตอร์" ประกอบกัน ไม่ได้ดูแค่ชื่อพารามิเตอร์
เพราะชื่อเดียวกันพฤติกรรมต่างกันตาม widget ตัวอย่างที่จงใจ **ไม่** ดัก:

| จุด | ทำไมไม่ดัก |
|---|---|
| `Text(style:)` · `TextSpan(style:)` | merge กับ `DefaultTextStyle` ให้อยู่แล้ว |
| `Chip.labelStyle` | source เขียนว่า `labelStyle.merge(widget.labelStyle)` |
| `TabBar.labelStyle` | source เขียนว่า `.merge(labelStyle ?? tabBarTheme.labelStyle)` |

ตอนร่างกฎครั้งแรกดักด้วยชื่อพารามิเตอร์อย่างเดียว ได้ false positive 6 จุดทันที
ซึ่งทั้งหมดเป็นโค้ดที่ถูกต้องอยู่แล้ว — ถ้าปล่อยไว้แบบนั้นคนจะปิดกฎทิ้ง
ซึ่งแย่กว่าไม่มีกฎเลย

**เวลาจะเพิ่มรายการใหม่** ให้เปิด source ของ widget นั้นใน Flutter SDK ดูก่อนว่า
สไตล์ถูกเลือกด้วย `a ?? b ?? c` (แทนที่ — ต้องดัก) หรือ `.merge()` (ปลอดภัย — ไม่ต้องดัก)
รายการปัจจุบันตรวจจาก source มาแล้วทุกบรรทัด

## รันเอง

```bash
cd app
dart run custom_lint          # รันทั้งโปรเจกต์
dart run custom_lint --watch  # รันค้างไว้ระหว่างแก้โค้ด
```

## เพิ่มกฎใหม่

1. เขียนคลาสที่ extend `DartLintRule` ใน `lib/payneat_lints.dart`
2. ลงทะเบียนใน `_PaynEatLints.getLintRules`
3. เขียนเหตุผลไว้ใน README นี้ว่ากันบั๊กอะไร — กฎที่ไม่มีเหตุผลรองรับจะถูกปิดทิ้งในที่สุด
