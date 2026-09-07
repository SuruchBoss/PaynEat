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
| Clean Code | ✅ ดี | `flutter analyze` ไม่มี warning, `dart format` ผ่าน, ไม่มี `print()`/`TODO`/`FIXME` ค้าง |
| State Management (GetX) | ✅ ดี | แยก ephemeral state (setState) กับ app state (Rx) ชัดเจน, ไม่มี controller รั่ว |
| Clean Architecture | ✅ แก้ครบแล้ว | domain เคย import จาก data (ดูหัวข้อ 4.4) — แก้แล้ว |
| Technical Debt | ⚠️ มีรายการต้องติดตาม | เทสต์ยังไม่ครบทุก controller/module (ดูหัวข้อ 6) |
| โครงสร้างโฟลเดอร์ | ✅ แก้ครบแล้ว | backend 3 module เคยข้าม controller layer (ดูหัวข้อ 5.3) — เพิ่มครบแล้ว |

Flutter: 46 เทสต์ผ่าน · Backend: 36 เทสต์ผ่าน · รวม 82 เทสต์อัตโนมัติ

ดูสรุปแบบอ่านง่าย (PDF 8 หน้า) ได้ที่ [`docs/PaynEat-POS-Audit-Report-TH.pdf`](PaynEat-POS-Audit-Report-TH.pdf)

---

## 1. หลักการรวม

1. **ทิศทาง dependency ห้ามย้อนกลับ** — ชั้นในไม่รู้จักชั้นนอก (ดูหัวข้อ 4)
2. **ชื่อสื่อความหมาย ไม่ต้องมีคอมเมนต์อธิบายว่าโค้ดทำอะไร** — คอมเมนต์มีไว้อธิบาย "ทำไม" เท่านั้น
   (เหตุผลที่เลือกทางนี้, edge case ที่ไม่ชัดเจน, workaround ของบั๊กเฉพาะที่)
3. **ฟังก์ชันคิดเงินต้องเป็น pure function และมีเทสต์คู่กันเสมอ** — ห้ามมี side effect
4. **ไฟล์ใหม่ต้องอยู่ในตำแหน่งที่ layer เดียวกันหาเจอโดยไม่ต้องเดา** — ดูหัวข้อ 5
5. **ก่อน merge: `flutter analyze` + `dart format --set-exit-if-changed` + `flutter test` ต้องผ่านทั้งหมด**
   ฝั่ง backend: `npm test` ต้องผ่านทั้งหมด — ไม่มีข้อยกเว้น

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

- `core/demo/demo_store.dart` (1,142 บรรทัด) — เป็นเซิร์ฟเวอร์จำลองทั้งร้านสำหรับ Demo Mode
  ยอมรับว่าใหญ่เพราะจำลองทุกโมดูล แต่ **ถ้าจะเพิ่มฟีเจอร์ demo ใหม่ ให้แยกเป็นไฟล์ย่อยตามโดเมน**
  (เช่น `demo_store_orders.dart`, `demo_store_reports.dart`) แทนที่จะเพิ่มในไฟล์เดิม
- ไฟล์หน้าจอ (page) ที่เกิน 400 บรรทัดขึ้นไป ให้แยก widget ย่อยออกเป็นไฟล์ใน `presentation/widgets/`
  ของ feature เดียวกัน แทนที่จะเก็บเป็น private class ในไฟล์เดียวกันทั้งหมด

### 2.3 Backend logging

ตอนนี้ backend ไม่มี ESLint/Prettier config — พึ่งเทสต์ (`npm test`, 36 เทสต์) กับ code review
เป็นตัวจับความผิดพลาดเท่านั้น **ถือเป็น technical debt** (บันทึกไว้ในหัวข้อ 6) เพราะ error ทาง
syntax/style เล็กๆ (unused var, inconsistent quotes) จะไม่ถูกจับอัตโนมัติ

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
# Flutter: domain ต้องไม่ import จาก data/presentation
grep -rn "import.*['\"].*\/data\/"         app/lib/features/*/domain/
grep -rn "import.*['\"].*\/presentation\/" app/lib/features/*/domain/
grep -rln "package:get"                    app/lib/features/*/domain/
# ทั้ง 3 คำสั่งต้องไม่มี output ใดๆ

# Backend: service ห้ามรู้จัก req/res, controller ห้าม import repository ตรงๆ
grep -rln "req\.\|res\."                    backend/src/modules/*/*.service.js
grep -rn "require.*\.repository"            backend/src/modules/*/*.routes.js backend/src/modules/*/*.controller.js
# ทั้ง 2 คำสั่งต้องไม่มี output ใดๆ
```

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
| 1 | Backend ไม่มี ESLint/Prettier | style/simple bug ไม่ถูกจับอัตโนมัติ นอกจาก test coverage | เพิ่ม `eslint` + `eslint-config-airbnb-base` หรือเทียบเท่า ก่อนโค้ดเบสใหญ่กว่านี้ | ค้าง |
| 2 | Controller ส่วนใหญ่ใน Flutter ไม่มี unit test เฉพาะตัว (มีแค่ `CartController`) | บั๊ก logic ใน controller (เช่น auth flow, order list filter) จับได้ช้าลง ต้องพึ่ง manual QA | เพิ่ม unit test ให้ `AuthController`, `OrderListController`, `TableController` เป็นลำดับแรก (กระทบ user มากสุด) | ค้าง |
| 3 | Backend module ส่วนใหญ่ไม่มี unit test เฉพาะ module (มีแค่ `auth`, `order-flow` integration, `calculator`) | อาศัย integration test เดียวคุมทั้งระบบ — ถ้า fail จะไม่รู้ทันทีว่าโมดูลไหนพัง | เพิ่ม unit test แยกให้ `menu.service.js`, `table.service.js`, `payment.service.js` | ค้าง |
| 4 | `demo_store.dart` 1,142 บรรทัดในไฟล์เดียว | แก้ยากขึ้นเรื่อยๆ เมื่อเพิ่ม demo scenario ใหม่ | แยกเป็นไฟล์ย่อยตามโดเมนตอนแก้ไขครั้งถัดไป (ดูหัวข้อ 2.2) | ค้าง |
| 5 | 3 backend module ไม่มี controller layer | ไม่สม่ำเสมอกับสถาปัตยกรรมที่ README ประกาศไว้ | เพิ่ม controller ให้ `payments`/`reports`/`settings` แล้ว (ดูหัวข้อ 5.3) | ✅ **แก้แล้ว** |
| 6 | Flutter dependencies ล้าหลัง ~15 แพ็กเกจ (minor version) | ไม่กระทบการทำงาน แต่ควรตามให้ทันเป็นระยะ | รัน `flutter pub outdated` ทุกไตรมาส แล้วอัปเดตทีละน้อย | ค้าง |
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

---

## 7. Checklist ก่อน commit / เปิด PR

```bash
# Flutter
cd app
flutter analyze                                    # ต้อง "No issues found!"
dart format --output=none --set-exit-if-changed .  # ต้อง exit 0
flutter test                                        # ต้อง "All tests passed!"

# Backend
cd backend
npm test                                            # ต้อง fail 0
```

เพิ่ม feature ใหม่ที่แตะ domain/data layer → รันชุดคำสั่งตรวจ layer violation ในหัวข้อ 4.3 ด้วย

ถ้าเพิ่ม/แก้ controller GetX ใหม่ → เช็คหัวข้อ 3.1–3.4 ว่าเลือก `setState` หรือ Rx ถูกแบบ,
`Obx` อ่านค่าถูก scope, มี `onClose()` ถ้าจำเป็น

ถ้าสร้างไฟล์ใหม่ → เช็คหัวข้อ 5 ว่าอยู่ตำแหน่งที่ถูกต้องตามชั้นสถาปัตยกรรม
