# มาตรฐานการเขียนโค้ด (Coding Standards)

เอกสารนี้เป็นผลจากการตรวจสอบโค้ดทั้งโปรเจกต์ (2026-09-07) ใน 5 มิติ: Clean Code,
State Management, Clean Architecture, Technical Debt และโครงสร้างโฟลเดอร์
เขียนไว้เพื่อ **ใช้เป็นมาตรฐานของการพัฒนาต่อจากนี้** ไม่ใช่แค่รายงานผลตรวจครั้งเดียว

กฎทุกข้อด้านล่างอ้างอิงจากโค้ดจริงในโปรเจกต์ (ไม่ใช่ทฤษฎีทั่วไป) — บางข้อคือสิ่งที่ทำถูกอยู่แล้วและ
ต้องรักษาไว้ บางข้อคือปัญหาจริงที่เจอระหว่างตรวจและแก้ไปแล้ว

---

## สรุปผลตรวจ (ณ วันที่ตรวจ)

| มิติ | สถานะ | รายละเอียด |
|---|---|---|
| Clean Code | ✅ ดี | `flutter analyze` ไม่มี warning, `dart format` ผ่าน, ไม่มี `print()`/`TODO`/`FIXME` ค้าง, backend มี ESLint + Prettier ครบแล้ว |
| State Management (GetX) | ✅ ดี | แยก ephemeral state (setState) กับ app state (Rx) ชัดเจน, ไม่มี controller รั่ว |
| Clean Architecture | ✅ แก้ครบแล้ว | domain เคย import จาก data (ดูหัวข้อ 4.4) — แก้แล้ว |
| Technical Debt | ✅ แก้ครบทุกรายการที่แก้ได้จริง | เหลือเฉพาะ transitive dependency ที่ผูกกับ Flutter SDK เอง แก้จากในโปรเจกต์ไม่ได้ (ดูหัวข้อ 6) |
| โครงสร้างโฟลเดอร์ | ✅ แก้ครบแล้ว | backend 3 module เคยข้าม controller layer (ดูหัวข้อ 5.3) — เพิ่มครบแล้ว |

Flutter: 151 เทสต์ผ่าน · Backend: 94 เทสต์ผ่าน · รวม 245 เทสต์อัตโนมัติ

ดูสรุปแบบอ่านง่าย (PDF 8 หน้า) ได้ที่ [`docs/PaynEat-POS-Audit-Report-TH.pdf`](PaynEat-POS-Audit-Report-TH.pdf)

---

## 1. หลักการรวม

1. **ทิศทาง dependency ห้ามย้อนกลับ** — ชั้นในไม่รู้จักชั้นนอก (ดูหัวข้อ 4)
2. **ชื่อสื่อความหมาย ไม่ต้องมีคอมเมนต์อธิบายว่าโค้ดทำอะไร** — คอมเมนต์มีไว้อธิบาย "ทำไม" เท่านั้น
   (เหตุผลที่เลือกทางนี้, edge case ที่ไม่ชัดเจน, workaround ของบั๊กเฉพาะที่)
3. **ฟังก์ชันคิดเงินต้องเป็น pure function และมีเทสต์คู่กันเสมอ** — ห้ามมี side effect
4. **ไฟล์ใหม่ต้องอยู่ในตำแหน่งที่ layer เดียวกันหาเจอโดยไม่ต้องเดา** — ดูหัวข้อ 5
5. **ก่อน merge: `flutter analyze` + `dart format --set-exit-if-changed` + `flutter test` ต้องผ่านทั้งหมด**
   ฝั่ง backend: `npm run lint` + `npm run format:check` + `npm test` ต้องผ่านทั้งหมด — ไม่มีข้อยกเว้น

---

## 2. Clean Code

### 2.1 กฎที่บังคับใช้อยู่แล้ว (รักษาไว้)

- ห้ามใช้ `print()` (Dart) หรือ `console.log()` (JS) ในโค้ด business logic — ใช้ได้เฉพาะใน
  entry point (`server.js`, สคริปต์ CLI อย่าง `seed.js`/`migrate.js`) หรือ error handler ตัวเดียว
  ที่กำหนดไว้ (`errorHandler.js`)
- ห้ามเหลือ `TODO` / `FIXME` / `HACK` ค้างใน `main` — ถ้ามีงานค้างจริง ให้บันทึกในหัวข้อ 6 ของเอกสารนี้แทน
- ทุก PR ต้องผ่าน `flutter analyze` (0 issues) และ `dart format --set-exit-if-changed .`
  ก่อน merge เสมอ — ห้าม format เอง manual

### 2.2 ขนาดไฟล์และฟังก์ชัน

ไม่มีการบังคับจำนวนบรรทัดตายตัว แต่ไฟล์ไหนเกิน ~400 บรรทัด ให้ตั้งคำถามว่าแยกความรับผิดชอบได้ไหม
ตัวอย่างที่ต้องระวังในโปรเจกต์นี้:

- `core/demo/demo_store.dart` — **แก้แล้ว** เคยเป็นไฟล์เดียว 1,142 บรรทัด ตอนนี้แยกเป็น
  `demo_store.dart` (112 บรรทัด — เก็บเฉพาะ state ร่วมและ helper ที่ใช้ทุกโดเมน) บวก part file
  ตามโดเมน 17 ไฟล์ (รายการนี้ต้องอัปเดตทุกครั้งที่แยกไฟล์ใหม่ — ตรวจสอบด้วย
  `wc -l lib/core/demo/demo_store_*.dart` ก่อนแก้เอกสาร อย่าเดา/คัดลอกเลขเก่า): `demo_store_auth.dart`
  (132), `demo_store_menu.dart` (210), `demo_store_ingredients.dart` (178),
  `demo_store_tables.dart` (83), `demo_store_orders.dart` (423 — order lifecycle: create/send
  to kitchen/discount/move/merge/cancel), `demo_store_order_items.dart` (285 — เพิ่ม/แก้/ลบ/
  เปลี่ยนสถานะรายการอาหารในออเดอร์ แยกจาก orders เพราะเดิมไฟล์เดียวโต 825 บรรทัด),
  `demo_store_order_promotions.dart` (125 — resolve/redeem/remove โปรโมชันของออเดอร์ แยกออก
  จากไฟล์เดียวกัน), `demo_store_payments.dart` (321), `demo_store_promotions.dart` (117),
  `demo_store_refunds.dart` (70), `demo_store_shifts.dart` (85), `demo_store_reports.dart`
  (197), `demo_store_seed_history.dart` (127), `demo_store_tax_invoices.dart` (146),
  `demo_store_settings.dart` (46), `demo_store_audit_logs.dart` (134),
  `demo_store_customers.dart` (60), `demo_store_receivables.dart` (280 — ยอดค้าง/อายุหนี้/วงเงิน
  ของลูกค้าเครดิต), `demo_store_ar_documents.dart` (379 — ใบเสร็จรับชำระหนี้/ใบวางบิล แยกออกจาก
  receivables เพราะรวมกันแล้ว 652 บรรทัด ticket 20) — ใช้ `part`/`part of` + `extension ... on DemoStore` ต่อไฟล์
  ยังเป็นคลาสเดียวกัน เข้าถึง field/เมธอด private ข้ามไฟล์ได้ปกติเพราะ part ทั้งหมดอยู่ใน library
  เดียวกัน (สมาชิก `static` เช่น `openingHour` ต้องระบุ `DemoStore.` นำหน้าเมื่อเรียกจาก extension —
  จุดเดียวที่ต่างจากตอนอยู่ในคลาสเดียว) ยืนยันด้วย `test/core/demo_store_test.dart` และเทสต์เดิม
  ทั้งหมดผ่านครบทุกครั้งที่แยกไฟล์เพิ่ม เพิ่มฟีเจอร์ demo ใหม่จากนี้ไปให้เพิ่มในไฟล์ย่อยตามโดเมนที่
  เกี่ยวข้อง ไม่ใช่ไฟล์เดียวรวมกัน
- `core/demo/demo_data_sources.dart` — **แก้แล้ว** เคยเป็นไฟล์เดียว 846 บรรทัด รวม 14 คลาส
  `Demo*DataSource` ไม่เกี่ยวข้องกัน ตอนนี้แยกเป็น `demo_data_sources.dart` (69 บรรทัด — import
  รวม + helper ส่วนกลาง `_delayed`) บวก part file ต่อ 1 คลาส (`demo_auth_data_source.dart`,
  `demo_menu_data_source.dart`, `demo_ingredient_data_source.dart`, `demo_table_data_source.dart`,
  `demo_order_data_source.dart`, `demo_promotion_data_source.dart`, `demo_payment_data_source.dart`,
  `demo_tax_invoice_data_source.dart`, `demo_shift_data_source.dart`, `demo_report_data_source.dart`,
  `demo_staff_data_source.dart`, `demo_settings_data_source.dart`, `demo_audit_log_data_source.dart`,
  `demo_customer_data_source.dart`) — ต่างจาก `demo_store.dart` ตรงที่แต่ละคลาสเป็นอิสระต่อกัน
  ไม่ได้แชร์ state แต่ยังใช้ `part`/`part of` เพื่อแชร์ helper `_delayed` ตัวเดียวแบบ private
  ข้ามไฟล์ได้โดยไม่ต้อง export
- `app/di/initial_binding.dart` — **แก้แล้ว** เคยเป็นไฟล์เดียว 644 บรรทัด ผูก data source/
  repository/use case ของ 14 โดเมนรวมกันในเมธอดเดียว (`_bindUseCases` อย่างเดียวยาว 326 บรรทัด)
  ตอนนี้ `initial_binding.dart` เหลือแค่ composition root (31 บรรทัด — เรียก 5 ฟังก์ชันตามลำดับ)
  ย้าย logic ไปไฟล์ใน `app/di/bindings/` ตามขั้นตอนที่ต้องผูก (ไม่ใช่ตามโดเมน เพราะแต่ละขั้นตอน
  วนลูปทุกโดเมนอยู่แล้ว): `core_bindings.dart` (`bindCoreServices` — 38), `data_source_bindings.dart`
  (`bindDataSources`/demo variant — 142), `repository_bindings.dart` (`bindRepositories` — 109),
  `use_case_bindings.dart` (`bindUseCases` — 340), `global_controller_bindings.dart`
  (`bindGlobalControllers` — 23) — เป็นฟังก์ชัน top-level ธรรมดา ไม่ใช้ `part`/`part of` เพราะแต่ละ
  ฟังก์ชันพึ่งพากันผ่าน `Get.find<T>()` (service locator) อยู่แล้ว ไม่ต้องแชร์ private state ข้ามไฟล์
  เหมือน `demo_store.dart` — ต่างจาก `presentation/bindings/*_binding.dart` ที่มีอยู่แล้ว
  (`home_binding.dart`, `order_bindings.dart`, `payment_bindings.dart`, `customer_bindings.dart`)
  ตรงที่ไฟล์เหล่านั้นผูก **controller ระดับหน้าจอ** จาก use case ที่ `InitialBinding` ผูกไว้แล้ว
  ส่วน `app/di/bindings/` คือ composition root ระดับแอปที่ต้องรันก่อนเสมอ คนละชั้นกัน
- ไฟล์หน้าจอ (page) ที่เกิน 400 บรรทัดขึ้นไป ให้แยก widget ย่อยออกเป็นไฟล์ใน `presentation/widgets/`
  ของ feature เดียวกัน แทนที่จะเก็บเป็น private class ในไฟล์เดียวกันทั้งหมด

### 2.3 Backend: ESLint + Prettier — แก้แล้ว

เพิ่ม `backend/eslint.config.js` (flat config ของ ESLint 9) และ `backend/.prettierrc.json` แล้ว
ทั้งคู่ต้องผ่านก่อน merge เสมอ (CI เช็คให้อัตโนมัติในทุก PR):

```bash
cd backend
npm run lint           # eslint src tests — 0 errors, 0 warnings
npm run format:check   # prettier --check src tests
npm run format         # prettier --write src tests (รันตอนแก้เอง ก่อน commit)
```

**กฎที่บังคับใช้**: `no-unused-vars` (ยกเว้นชื่อขึ้นต้นด้วย `_` เช่น พารามิเตอร์ `_next` ที่ Express
error middleware ต้องมีแต่ไม่ได้ใช้), `no-var`, `prefer-const`, `eqeqeq` (สมาร์ต — ยกเว้น `== null`),
`no-console` (warn เฉพาะ `console.log`/`console.error` เท่านั้น ตัวอื่นห้ามใช้)

**Prettier**: `singleQuote: true`, `printWidth: 100`, `trailingComma: "all"` — ตรงกับสไตล์เดิมของ
โค้ดเบสอยู่แล้ว (single quote + semicolon) จึงมีไฟล์ที่ format เปลี่ยนแค่การตัดบรรทัดยาวเกิน 100
ตัวอักษรเป็นส่วนใหญ่ ไม่ใช่การเปลี่ยนสไตล์ทั้งหมด

**ข้อยกเว้นที่ตั้งใจ**: อาเรย์ข้อมูลตัวอย่าง (`USERS`, `CATEGORIES`, `MENU`, `TABLES` ใน
`backend/src/db/seed.js`) ใส่ `// prettier-ignore` ไว้เพราะเป็นข้อมูลดิบแบบตาราง (1 บรรทัด/1 แถว)
ที่ scan ด้วยตาง่ายกว่าเวอร์ชันขยายหลายบรรทัดของ Prettier ชัดเจน — ใช้ `// prettier-ignore` แบบนี้
ได้เฉพาะกับ literal ข้อมูลดิบเท่านั้น ห้ามใช้กับ logic code เพื่อเลี่ยงกฎ format

---

## 3. State Management (GetX)

### 3.1 กฎการเลือกว่าจะใช้ `setState` หรือ GetX reactive state

นี่คือกฎที่สำคัญที่สุดของหัวข้อนี้ เพราะเป็นจุดที่มักสับสน:

| ใช้ | เมื่อไหร่ | ตัวอย่างจริงในโปรเจกต์ |
|---|---|---|
| `StatefulWidget` + `setState()` | state เป็น **ephemeral UI state** ที่ไม่มีใครนอก widget นี้สนใจ (ค่าใน dialog, toggle ใน form, ตัวเลขใน quantity selector ก่อนกดยืนยัน) | `DiscountDialog`, `OptionSelectionSheet` (ตัวเลือกก่อนกดเพิ่มลงตะกร้า), `MenuFormPage` (ฟอร์มก่อน submit) |
| `GetxController` + `.obs` + `Obx()` | state เป็น **app/business state** ที่หน้าอื่นหรือ widget อื่นต้องรู้ด้วย, หรือมาจาก API | ตะกร้า (`CartController`), รายการออเดอร์, สถานะล็อกอิน |

**ห้ามผสมสองแบบในโมเดลเดียวกัน** เช่น ห้ามเก็บตะกร้าสินค้าด้วย `setState` ในหน้า order taking
เพราะหน้าอื่น (mini cart bar, badge จำนวนสินค้า) ต้องรู้การเปลี่ยนแปลงด้วย

### 3.2 กฎการใช้ `Obx()` — บั๊กจริงที่เคยเกิด

**ห้ามอ่านค่า observable (`.value`) ใน `itemBuilder`/callback ที่อยู่ *ข้างใน* `Obx()`
ต้องอ่านที่ scope บนสุดของ `Obx(() { ... })` เท่านั้น**

บั๊กนี้เคยเกิดจริงใน `orders_page.dart` — chip กรองสถานะไม่ rebuild เมื่อกดเปลี่ยนตัวกรอง เพราะ GetX
ติดตาม (`track`) เฉพาะ observable ที่ถูกอ่านตอน `Obx` builder รันครั้งแรกเท่านั้น ถ้าค่าถูกอ่านใน
`itemBuilder` ที่เรียกทีหลัง (ตอน scroll หรือ rebuild) GetX จะไม่รู้ว่าต้อง subscribe

```dart
// ❌ ผิด — ItemBuilder ถูกเรียกทีหลัง ไม่อยู่ใน scope ที่ Obx ติดตาม
Obx(() => ListView.builder(
  itemBuilder: (context, i) {
    final selected = controller.statusFilter.value == filters[i].value; // ไม่ rebuild!
    return ChoiceChip(selected: selected, ...);
  },
));

// ✅ ถูก — อ่านค่าที่ scope บนสุดของ Obx ก่อน แล้วค่อยส่งต่อเข้า itemBuilder
Obx(() {
  final activeFilter = controller.statusFilter.value; // อ่านตรงนี้ที่เดียว
  return ListView.builder(
    itemBuilder: (context, i) {
      final selected = activeFilter == filters[i].value;
      return ChoiceChip(selected: selected, ...);
    },
  );
});
```

ดูโค้ดจริงที่แก้แล้วที่ `app/lib/features/order/presentation/pages/orders_page.dart`

### 3.3 Dependency Injection

- Composition root มีที่เดียว: `app/lib/app/di/initial_binding.dart` — การประกาศ
  `Get.lazyPut`/`Get.put` ทั้งหมดต้องอยู่ในไฟล์นี้หรือ `*_binding.dart` ของแต่ละ feature เท่านั้น
- แต่ละหน้าใช้ `GetView<XController>` แล้วเข้าถึง controller ผ่าน `controller` getter ที่มีให้อยู่แล้ว
  **ห้าม** เรียก `Get.find<XController>()` ซ้ำเองถ้า generic type ของ `GetView` ตรงกับ controller นั้นอยู่แล้ว
- ถ้าหน้าเดียวต้องใช้มากกว่า 1 controller (เช่น `order_taking_page.dart` ใช้ทั้ง `MenuBrowseController`
  ผ่าน `GetView` และ `CartController` เพิ่ม) การเรียก `Get.find()` เพิ่มสำหรับตัวที่สองถือว่ายอมรับได้
- **แนวทางที่ควรปรับปรุง** (ไม่ใช่บั๊ก แต่ควรทำให้สม่ำเสมอกว่านี้): private widget ย่อยหลายตัว
  (เช่น `_TableSummaryBar`, `_UserChip`) เรียก `Get.find<T>()` เองข้างในแทนที่จะรับ controller
  ผ่าน constructor หรือ extends `GetView<T>` — ทำให้ widget ผูกกับ service locator โดยตรง
  ทดสอบแยกจาก DI ยากขึ้น กฎจากนี้ไป: **ถ้า private widgetอยู่ใน build tree เดียวกับหน้าที่เป็น
  `GetView<T>` อยู่แล้ว ให้ widget นั้น extends `GetView<T>` ด้วย แทนการเรียก `Get.find()` ซ้ำ**

### 3.4 Controller lifecycle

- ถ้า controller มี `StreamSubscription`, `Timer`, หรือ `TextEditingController` ต้อง override
  `onClose()` และ cleanup ทุกตัวเสมอ (ตรวจแล้วว่า `AuthController`, `CheckoutController`,
  `SettingsController`, `MenuController` ทำถูกครบ — ใช้เป็นตัวอย่างอ้างอิงได้)

### 3.5 `Rx<T>`/`Rxn<T>` กับ entity ที่ override `==` ด้วย id เท่านั้น — บั๊กจริงที่เคยเกิด

**ห้ามวางใจว่า `someRx.value = newObject` จะอัปเดตค่าเสมอ ถ้า `T` override `==` แบบเทียบแค่ id**
(เช่น `Order`, `OrderItem`, `MenuItem`, `Category`, `User`, `DiningTable` ในโปรเจกต์นี้ทุกตัวทำแบบนี้)

GetX's `RxImpl.value` setter มี short-circuit ว่า `if (_value == val) return;` — ถ้าอ็อบเจกต์เก่ากับใหม่
`==` กันแล้วได้ `true` (เพราะเทียบแค่ `id` เหมือนกัน) มันจะ **ไม่แทนที่ `_value` เลย** แม้เนื้อหาข้างในต่างกัน
จริง (เช่น `items` เปลี่ยนจำนวน, `status` เปลี่ยน) และไม่แจ้ง listener ด้วย

บั๊กนี้เคยเกิดจริงใน `OrderDetailController._run()` — หลัง `changeItemQuantity`/`advanceItemStatus`/
`sendToKitchen`/ฯลฯ สำเร็จ เซิร์ฟเวอร์ส่ง `Order` ก้อนใหม่กลับมา (id เดิม เนื้อหาต่างกัน) แต่
`order.value = data;` ไม่มีผลอะไรเลยเพราะ id ตรงกับของเดิม ทำให้จอค้างข้อมูลเก่าหลังแก้ไข/เปลี่ยนสถานะ
ทุกครั้ง (ตรวจพบตอนเขียน unit test ที่ปลอมข้อมูลคืนค่าจาก use case ให้ต่างจากเดิมโดยตั้งใจ)

**ตามไปเจอเพิ่มอีก 3 จุดตอนทำฟีเจอร์ย้ายโต๊ะ/รวมบิล/แยกบิล** — จุดที่ร้ายแรงที่สุดคือ
`OrderDetailController.load()` (เมธอด `load()` ธรรมดา ไม่ใช่แค่ `_run()`) เพราะ `load()` ถูกเรียกซ้ำ
จาก **realtime update** (`_listenToRealtimeUpdates` เรียก `load(showLoader: false)` ทุกครั้งที่มี
`ORDER_UPDATED`/`ORDER_ITEM_UPDATED` เด้งมา) ตลอดเวลาที่เปิดหน้านี้ค้างไว้ — ถ้าไม่แก้
หน้ารายละเอียดออเดอร์จะ**ไม่มีทางอัปเดตแบบเรียลไทม์เลยหลังโหลดครั้งแรก** เพราะทุก
`load(showLoader: false)` รอบถัดไปโดน short-circuit ด้วย id เดิมหมด (มี regression test ล็อกพฤติกรรม
นี้ไว้แล้วในชื่อ "load เรียกซ้ำด้วย order id เดิม") อีก 2 จุดคือ `CheckoutController.load()`
(เรียกซ้ำหลัง `submit()` จ่ายไม่ครบ) และ `ReceiptController.load()`/`SplitBillController.load()`
— ผลกระทบตอนนี้เบากว่าเพราะฟิลด์ของ `Order` ที่แสดงผลในหน้านั้นๆ ไม่ค่อยเปลี่ยนระหว่างการ reload
แต่ก็แก้ไปด้วยเพื่อความถูกต้องและกันบั๊กแฝงในอนาคต

```dart
// ❌ ผิด — ถ้า data.id == order.value?.id (ปกติเป็นแบบนี้เสมอ เพราะเป็นออเดอร์ใบเดิม)
// GetX จะมองว่า "ค่าเดิม" แล้วข้าม assignment ไปเฉยๆ ตาม == ของ Order
order.value = data;

// ✅ ถูก — เคลียร์เป็น null ก่อนเพื่อบังคับให้ `_value == val` เป็น false เสมอ
order.value = null;
order.value = data;
```

ดูโค้ดจริงที่แก้แล้วที่ `order_detail_controller.dart` (`_run()` และ `load()`),
`checkout_controller.dart` (`load()`), `receipt_controller.dart` (`load()`),
`split_bill_controller.dart` (`load()`, `submit()`) และเทสต์ที่ล็อกพฤติกรรมไว้ที่
`app/test/presentation/order_detail_controller_test.dart`

**กฎจากเคสนี้**: ทุกครั้งที่ reassign `Rx<T>`/`Rxn<T>` ด้วยอ็อบเจกต์ใหม่ที่ id อาจจะซ้ำกับของเดิม
(เช่น refetch entity เดิมหลัง mutate) ให้เคลียร์เป็น `null` ก่อนเสมอ หรือถ้าเป็น `Rx<T>` ที่ไม่รับ
`null` ให้ใช้ `.refresh()` ควบคู่กับการเช็คว่าอ็อบเจกต์ใหม่ถูก assign เข้า `_value` จริง —
**ห้ามพึ่ง `==` ของ entity ที่ id-based ในการตัดสินว่า Rx ต้อง notify หรือไม่**

---

## 4. Clean Architecture

### 4.1 ทิศทาง dependency ที่บังคับ

```
presentation  →  domain  ←  data
   (UI, GetX)   (entities,     (models, datasources,
                 usecases,      repository impl)
                 repo interface)
```

- **domain ห้าม import จาก data หรือ presentation เด็ดขาด** — domain ต้องเป็น pure Dart
  ไม่รู้จัก `package:get`, ไม่รู้จัก HTTP, ไม่รู้จัก widget ใดๆ
- **presentation ห้าม import datasource ตรงๆ** ต้องผ่าน controller → usecase/repository เท่านั้น
- **data ห้าม import จาก presentation**

### 4.2 Backend layering ที่บังคับ

```
routes → controller → service → repository → db
```

- `service` **ห้าม** รู้จัก `req`/`res` ของ Express (ห้าม import อะไรจาก express เข้า service)
- `controller`/`routes` **ห้าม** import repository หรือ `better-sqlite3` ตรงๆ ข้าม service

### 4.3 วิธีเช็คว่าไม่ผิดกฎ (รันก่อน commit ทุกครั้งที่แตะ domain/data layer)

```bash
bash tool/check-architecture.sh
```

สคริปต์นี้รันกฎทั้ง 5 ข้อข้างล่าง (ทุกคำสั่งต้องไม่มี output) และ **CI รันให้ทุก push** ตั้งแต่
job `architecture` ถูกเพิ่มเข้าไป — กฎที่ต้องอาศัยคนจำว่าต้องรันเอง ไม่ใช่กฎที่บังคับอะไรได้จริง
§4.4 ข้างล่างคือหลักฐานว่าเคยผิดกฎแล้วกว่าจะเจอก็ตอนไล่ตรวจด้วยมือ

```bash
# Flutter: domain ต้องไม่ import จาก data/presentation
grep -rn "import.*['\"].*\/data\/"                    app/lib/features/*/domain/
grep -rn "import.*['\"].*\/presentation\/"            app/lib/features/*/domain/
grep -rnE "^\s*(import|export) .*package:get"        app/lib/features/*/domain/
# ทั้ง 3 คำสั่งต้องไม่มี output ใดๆ

# Backend: service ห้ามรู้จัก req/res, controller ห้าม import repository ตรงๆ
# (ตัดคอมเมนต์ // ออกก่อน — ดูหมายเหตุใต้บล็อกนี้)
for f in backend/src/modules/*/*.service.js; do sed 's://.*::' "$f" | grep -q "req\.\|res\." && echo "$f"; done
grep -rn "require.*\.repository"                      backend/src/modules/*/*.routes.js backend/src/modules/*/*.controller.js
# ทั้ง 2 คำสั่งต้องไม่มี output ใดๆ
```

> ข้อที่ 3 เดิมเขียนว่า `grep -rln "package:get"` (จับทุกที่ที่มีข้อความนี้) ตอนเอามาแขวนใน CI
> ครั้งแรกมันสะดุด**คอมเมนต์ที่อธิบายว่าทำไมห้ามใช้ GetX ใน domain** ซึ่งไม่ใช่ dependency
> เปลี่ยนเป็นเทียบเฉพาะบรรทัด `import`/`export` ให้ตรงกับเจตนาของกฎ

> ข้อที่ 4 สะดุดแบบเดียวกันอีกรอบตอน ticket 17 — `grep -rln "req\.\|res\."` จับ**คอมเมนต์ที่
> อ้างถึง `req.user`/`req.branchId` เพื่ออธิบายว่าค่านั้นมาจากไหน** ใน `public-order.service.js`
> และ `user.service.js` ทั้งที่ไม่มีโค้ดบรรทัดไหนแตะ Express เลย ทำให้ CI แดงโดยไม่มีอะไรผิดจริง
> เปลี่ยนเป็นตัดคอมเมนต์ `//` ออกก่อนแล้วค่อยเทียบ ให้ตรงกับเจตนาของกฎเหมือนข้อที่ 3

### 4.4 กรณีจริงที่เจอและแก้แล้ว: payload class อยู่ผิดชั้น

ตอนตรวจพบว่า `menu_repository.dart` และ `order_repository.dart` (ทั้งคู่อยู่ใน `domain/repositories/`)
import `MenuItemPayload` จาก `data/models/menu_item_model.dart` และ `OrderItemPayload` จาก
`data/datasources/order_remote_data_source.dart` — เป็นการผิดกฎข้อ 4.1 ตรงๆ (domain พึ่ง data)

**สาเหตุ**: `MenuItemPayload`/`OrderItemPayload` เป็นพารามิเตอร์สำหรับสร้าง/แก้ไขข้อมูล (มีแค่ field
ธรรมดา + เมธอด `toJson()`) แต่ถูกวางไว้ในไฟล์ data layer แทนที่จะเป็น domain object

**วิธีแก้ (ทำแล้วในการตรวจครั้งนี้)**: ย้ายทั้งสองคลาสไปไว้ที่
`features/menu/domain/entities/menu_item_payload.dart` และ
`features/order/domain/entities/order_item_payload.dart` แล้วให้ data layer (repository impl,
datasource) import จาก domain แทน (ทิศทางถูกต้อง: data → domain)

**กฎที่ตั้งจากเคสนี้**: พารามิเตอร์ input ของ usecase/repository (คำที่ลงท้ายด้วย `Payload`,
`Params`, `Filter`) ที่ไม่ได้ทำ HTTP เอง **ต้องอยู่ใน `domain/entities/` หรือประกาศไว้ใน
usecase file เอง** แม้จะมีเมธอด `toJson()` ติดไปด้วยก็ตาม เพราะ `toJson()` เป็นแค่ helper
แปลงข้อมูล ไม่ใช่ transport-layer dependency (ไม่ import `dio`/`http`) — สิ่งที่ตัดสินว่าคลาสอยู่
layer ไหนคือ **ตำแหน่งไฟล์และทิศทาง import** ไม่ใช่ว่ามันมีเมธอด serialize หรือเปล่า

---

## 5. โครงสร้างโฟลเดอร์และตำแหน่งไฟล์

### 5.1 Flutter — feature-first + Clean Architecture (มาตรฐานปัจจุบัน ใช้ต่อ)

ทุก feature ใหม่ต้องตามโครงนี้ (มี 9 features ที่ทำถูกแบบนี้อยู่แล้ว: auth, home, kitchen, menu,
order, payment, report, settings, staff, table):

```
features/<feature>/
  domain/
    entities/          # โมเดลบริสุทธิ์ ไม่มี fromJson/toJson ที่ผูกกับ API shape
    repositories/       # abstract class เท่านั้น (interface)
    usecases/           # 1 usecase = 1 class ที่มี call()
    services/           # business logic ที่ไม่ผูกกับ state (ถ้ามี เช่น order/domain/services)
  data/
    models/             # extends entity + fromJson/toJson ที่ผูกกับ API shape จริง
    datasources/        # เรียก ApiClient ตรงๆ (remote) หรือ local storage
    repositories/        # implements domain repository interface
  presentation/
    bindings/            # ผูก Get.lazyPut ของ controller ในหน้านี้
    controllers/          # GetxController
    pages/                # 1 route = 1 ไฟล์ page หลัก (private widget ย่อยอยู่ไฟล์เดียวกันได้ถ้าเล็ก)
    widgets/              # widget ที่ใช้ซ้ำหลายหน้าใน feature เดียวกัน หรือไฟล์ page ใหญ่เกินไป
```

**กฎเพิ่มเติม**:
- ไม่บังคับว่าทุก feature ต้องมีโฟลเดอร์ `widgets/` — ถ้า page นั้นไม่มี widget ที่ใหญ่พอจะแยก
  (เช่น `staff/`, `settings/`) ไม่ต้องสร้างโฟลเดอร์เปล่าไว้ล่วงหน้า
- ไฟล์ที่ชื่อลงท้าย `_payload.dart`, `_params.dart`, `_filter.dart` → อยู่ `domain/entities/`
  หรือรวมในไฟล์ usecase เดียวกันถ้าใช้แค่ที่เดียว (ดูหัวข้อ 4.4)

### 5.2 Backend — module-per-domain (มาตรฐานปัจจุบัน ใช้ต่อ)

```
modules/<module>/
  <name>.routes.js       # ผูก path + middleware, เรียก controller
  <name>.controller.js    # แปลง req → เรียก service → ส่ง response
  <name>.service.js       # business logic ล้วนๆ ไม่รู้จัก req/res
  <name>.repository.js    # SQL query
  <name>.mapper.js        # แปลง DB row ↔ API shape (รวม toSatang/toBaht)
  <name>.schema.js         # zod validation schema
```

### 5.3 ข้อไม่สม่ำเสมอที่พบและแก้แล้ว: 3 module เคยข้าม controller layer

`payments/`, `reports/`, `settings/` เคยไม่มีไฟล์ `.controller.js` — route handler เรียก
`xxxService.method()` ตรงจาก `routes.js` เลย ในขณะที่อีก 6 module (auth, categories, menu, orders,
tables, users) มี controller คั่นกลางตามที่ README อธิบายสถาปัตยกรรมไว้

**แก้แล้ว**: เพิ่ม `payment.controller.js`, `report.controller.js`, `settings.controller.js`
ตามรูปแบบเดียวกับ `table.controller.js` (object literal ที่แต่ละ method ห่อด้วย `asyncHandler`
แล้วเรียก service + ส่ง response) และแก้ `routes.js` ทั้ง 3 ไฟล์ให้เรียก controller แทนการเรียก
service ตรงๆ — path, middleware, ลำดับ validation, response shape เดิมทุกอย่าง ยืนยันด้วย
`npm test` (36 ผ่านเหมือนเดิม) และยิง API จริงตรวจ 3 endpoint (`GET /settings`,
`GET /reports/dashboard`, `GET /payments/order/:id`) ผ่านทั้งหมด

**กฎจากนี้ไป**: module ใหม่ทุกตัว **ต้องมี controller layer เสมอ** แม้จะเป็น CRUD ธรรมดา
เพื่อให้ route handler บางเสมอ (`controller.method` ที่ห่อด้วย `asyncHandler` ไว้แล้วในไฟล์ controller)
และเทสต์ controller แยกจาก service ได้ในอนาคต

---

## 6. Technical Debt ที่ติดตามอยู่

รายการนี้ต้องอัปเดตทุกครั้งที่แก้หรือเพิ่มรายการใหม่ — ห้ามปล่อยให้ debt ใหม่เกิดขึ้นแบบไม่มีบันทึก

| # | รายการ | ผลกระทบ | แผนแก้ | สถานะ |
|---|---|---|---|---|
| 1 | Backend ไม่มี ESLint/Prettier | style/simple bug ไม่ถูกจับอัตโนมัติ นอกจาก test coverage | เพิ่ม `eslint.config.js` + `.prettierrc.json` แล้ว และเช็คใน CI ทุก PR (ดูหัวข้อ 2.3) | ✅ **แก้แล้ว** |
| 2 | Controller ใน Flutter ยังไม่มี unit test ครบทุกตัว | บั๊ก logic ใน controller ที่เหลือจับได้ช้าลง ต้องพึ่ง manual QA | เพิ่ม unit test ครบทั้ง 14 controller แล้ว: `AuthController`, `OrderListController`, `TableController` (ชุดแรก) + `MenuBrowseController`, `MenuManagementController`, `KitchenController`, `CheckoutController`, `ReceiptController`, `HomeController`, `SettingsController`, `StaffController`, `OrderDetailController`, `DashboardController`, `ReportController` (ชุดที่สอง) — เฉพาะ path ที่ไม่แตะ `Get.*`/`AppDialogs` โดยตรง (ดูหัวข้อ 6.2) ระหว่างทางเจอบั๊กจริงใน `OrderDetailController` แล้วแก้ (ดูหัวข้อ 3.5) | ✅ **แก้แล้ว** |
| 3 | Backend module ไม่มี test เฉพาะ module | อาศัย integration test เดียวคุมทั้งระบบ — ถ้า fail จะไม่รู้ทันทีว่าโมดูลไหนพัง | เพิ่มเทสต์แยกครบทั้ง 9 module แล้ว: `menu`, `table`, `payment` (26 เคส) + `categories`, `settings`, `users`, `reports` (25 เคส) รวมกับ `auth`/`order-flow`/`calculator` เดิม | ✅ **แก้แล้ว** |
| 4 | `demo_store.dart` 1,142 บรรทัดในไฟล์เดียว | แก้ยากขึ้นเรื่อยๆ เมื่อเพิ่ม demo scenario ใหม่ | แยกเป็น 20 ไฟล์ตามโดเมนด้วย part/part of แล้ว (ดูหัวข้อ 2.2) — เช็ครอบล่าสุด (self code-review) ยังพบ `demo_data_sources.dart` (846 บรรทัด) กับ `app/di/initial_binding.dart` (644 บรรทัด) โตเกินแบบเดียวกันแต่ไม่เคยถูก backfill เข้าเอกสารนี้ แก้ครบทั้งคู่แล้วด้วย (ดูหัวข้อ 2.2) | ✅ **แก้แล้ว** |
| 5 | 3 backend module ไม่มี controller layer | ไม่สม่ำเสมอกับสถาปัตยกรรมที่ README ประกาศไว้ | เพิ่ม controller ให้ `payments`/`reports`/`settings` แล้ว (ดูหัวข้อ 5.3) | ✅ **แก้แล้ว** |
| 6 | Flutter dependencies ล้าหลัง ~15 แพ็กเกจ (minor version) | ไม่กระทบการทำงาน แต่ควรตามให้ทันเป็นระยะ | บัมป์ `flutter_lints` เป็น `^6.0.0` แล้ว (เดียวที่คุมเวอร์ชันเองได้ผ่าน `pubspec.yaml`) แก้ 24 lint ใหม่ที่โผล่มา (`unnecessary_underscores`, `use_null_aware_elements`) จนกลับมา `flutter analyze` = "No issues found!" — `flutter pub outdated` ตอนนี้ขึ้น "all dependencies are up-to-date" ทั้ง direct และ dev dependencies ส่วนแพ็กเกจที่เหลือ (`path_provider`, `vector_math`, `meta` ฯลฯ) เป็น transitive dependency ที่ผูกเวอร์ชันตายตัวกับ Flutter SDK (3.35.1) เอง ไม่ใช่จาก `pubspec.yaml` — ต้องอัปเดต Flutter SDK ทั้งก้อนถึงจะขยับได้ ไม่ใช่สิ่งที่แก้จากในโปรเจกต์นี้ได้ | ✅ **แก้แล้ว** (เท่าที่แก้ได้จากในโปรเจกต์) |
| 7 | domain layer import จาก data layer (`MenuItemPayload`, `OrderItemPayload`) | ผิดกฎ Clean Architecture ข้อ 4.1 | ย้ายเข้า `domain/entities/` แล้ว | ✅ **แก้แล้ว** (การตรวจครั้งนี้) |

**นโยบาย**: รายการที่ "ค้าง" ไม่ได้แปลว่าต้องหยุดพัฒนาฟีเจอร์ใหม่รอแก้ก่อน — แต่ถ้าจะแตะไฟล์/โมดูล
ที่มีรายการ debt เกี่ยวข้องอยู่แล้ว ให้ถือโอกาสแก้ไปพร้อมกันเสมอ ("boy scout rule")

### 6.1 Debt ที่ตั้งใจ ไม่ต้องแก้ (บันทึกไว้กันสับสน)

รายการเหล่านี้เป็นการตัดสินใจเชิงออกแบบที่มีเหตุผลรองรับแล้วใน `docs/DECISIONS.md` **ไม่ใช่ debt
ที่ต้องแก้**:

- ตรรกะคิดบิลเขียนซ้ำ 2 ภาษา (Dart preview + JS source of truth) — ดู DECISIONS.md ข้อ 2
- สถานะ (`OrderStatus`, `UserRole` ฯลฯ) เป็น string constants class ไม่ใช่ Dart `enum` จริง
  — เพราะ mirror กับ string enum ฝั่ง backend ตรงๆ ไม่ต้องมี mapping layer, ป้องกัน typo ด้วย
  named constants อยู่แล้ว (ตรวจแล้วว่าไม่มีจุดไหน compare ด้วย string literal ตรงๆ)
- `Result<T>` เขียนเอง แทน `dartz` — ดู DECISIONS.md ข้อ 3

### 6.2 แนวทางเทสต์ controller ที่แตะ `Get.*`/`AppDialogs`

Controller หลายตัวมีเมธอดที่เรียก `Get.toNamed`/`Get.offNamed`/`Get.back`/`Get.dialog`/
`AppDialogs.success`/`AppDialogs.error`/`AppDialogs.confirm` ตรงๆ — ฟังก์ชันพวกนี้ต้องมี
`GetMaterialApp` ที่ถูก pump จริงในต้นไม้วิดเจ็ต ไม่งั้นจะ throw หรือ fail แบบเงียบๆ

โปรเจกต์นี้ **ไม่สร้าง widget harness เต็มรูปแบบสำหรับเทสต์ controller ระดับ unit** (ต่างจาก
widget test/golden test ที่ pump จริงอยู่แล้วในโฟลเดอร์อื่น) เพื่อให้เทสต์เร็วและไม่ผูกกับ UI —
แนวทางที่ใช้แทนคือ:

1. เทสต์เฉพาะ path ที่ไม่แตะ `Get.*`/`AppDialogs` โดยตรง (getter, guard clause ต้น method,
   success path ที่ไม่ส่ง `successMessage`, ฯลฯ)
2. path ที่แตะทั้งหมด (เช่น `save()`/`delete()`/`toggleActive()` ที่เรียก `AppDialogs` ทุกเส้นทาง
   รวมถึง validation guard) ให้ข้ามและ**คอมเมนต์ไว้ในไฟล์เทสต์ว่าทำไมถึงข้าม** อ้างอิงหัวข้อนี้
3. ถ้า method มี `late final` field ที่ตั้งค่าใน `onInit()` (เช่น `orderId` จาก `Get.arguments`)
   ต้องเรียก `controller.onInit()` ก่อนเสมอ (ไม่ใช่เรียก `load()` ตรงๆ) แล้ว
   `await Future<void>.delayed(Duration.zero);` เพื่อให้ fire-and-forget `load()` ข้างใน
   `onInit()` มีเวลารันจบก่อนไปสเต็ปถัดไป — ดูตัวอย่างที่ `checkout_controller_test.dart`,
   `order_detail_controller_test.dart`

ดูตัวอย่างครบทั้ง 14 controller ที่ `app/test/presentation/*_controller_test.dart`

---

## 7. Checklist ก่อน commit / เปิด PR

```bash
# Flutter
cd app
flutter analyze                                    # ต้อง "No issues found!"
dart format --output=none --set-exit-if-changed .  # ต้อง exit 0
flutter test                                        # ต้อง "All tests passed!"
flutter test test_e2e                               # ต้อง "All tests passed!" (แอปจริง ↔ backend จริง — ต้อง `npm ci` ใน backend ก่อน)

# Backend
cd backend
npm run format:check                                # ต้อง "All matched files use Prettier code style!"
npm run lint                                        # ต้อง 0 errors, 0 warnings
npm test                                            # ต้อง fail 0
```

เพิ่ม feature ใหม่ที่แตะ domain/data layer → รันชุดคำสั่งตรวจ layer violation ในหัวข้อ 4.3 ด้วย

ถ้าเพิ่ม/แก้ controller GetX ใหม่ → เช็คหัวข้อ 3.1–3.4 ว่าเลือก `setState` หรือ Rx ถูกแบบ,
`Obx` อ่านค่าถูก scope, มี `onClose()` ถ้าจำเป็น

ถ้าสร้างไฟล์ใหม่ → เช็คหัวข้อ 5 ว่าอยู่ตำแหน่งที่ถูกต้องตามชั้นสถาปัตยกรรม
