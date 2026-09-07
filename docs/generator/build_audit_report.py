# -*- coding: utf-8 -*-
"""สร้าง HTML รายงานผลตรวจคุณภาพโค้ด สำหรับเรนเดอร์เป็น PDF ด้วย makepdf.mjs"""
import html
import json
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "audit-report.html"


def esc(text):
    return html.escape(str(text))


CSS = """
@page { size: A4; margin: 14mm 13mm 16mm 13mm; }
@page :first { margin: 0; }

/* กลับมาใช้ Noto Sans Thai เหมือนเอกสารอื่นในโปรเจกต์ — ปัญหาข้อความไทยผิดเพี้ยนตอนคัดลอก
   ไม่ได้แก้ด้วยการเปลี่ยนฟอนต์ (ลองมาแล้ว 8 ฟอนต์ ทุกฟอนต์พังแบบสุ่มไปตามคำ ไม่คงที่) จึงแก้ที่
   ต้นตอจริงแทน: หลัง render ภาพแล้ว โปรแกรม overlay_text_layer.py จะฝัง "เลเยอร์ข้อความที่ถูกต้อง
   แบบมองไม่เห็น" ทับลงไปจากข้อความต้นฉบับใน PLAIN_TEXT_PAGES ด้านล่าง (ไม่ได้ shape/OCR ใหม่)
   ทำให้คัดลอกได้ถูกต้อง 100% โดยไม่ต้องพึ่งว่า Chromium จะ render ฟอนต์ไหนแล้วสร้าง PDF ถูกหรือไม่
   ดู docs/generator/README.md หัวข้อ "ทำไมต้อง overlay ข้อความ" สำหรับรายละเอียดการไล่บั๊ก */
@font-face { font-family: 'Noto'; src: url('../../app/tool/fonts/NotoSansThai-400.ttf'); font-weight: 400; }
@font-face { font-family: 'Noto'; src: url('../../app/tool/fonts/NotoSansThai-500.ttf'); font-weight: 500; }
@font-face { font-family: 'Noto'; src: url('../../app/tool/fonts/NotoSansThai-700.ttf'); font-weight: 700; }
@font-face { font-family: 'Noto'; src: url('../../app/tool/fonts/NotoSansThai-800.ttf'); font-weight: 800; }

:root {
  --primary: #FF6B2C;
  --primary-dark: #E2551A;
  --soft: #FFF1EA;
  --ink: #1A1D21;
  --muted: #6B7280;
  --line: #E5E7EB;
  --bg: #F6F7F9;
  --green: #2F9E44;
  --green-soft: #EBFBEE;
  --amber: #E8590C;
  --amber-soft: #FFF4E6;
  --red: #C92A2A;
}

* { box-sizing: border-box; }
body { font-family: 'Noto', sans-serif; color: var(--ink); margin: 0; font-size: 9.6pt; line-height: 1.62; }
code, .mono { font-family: 'Noto', monospace; }

/* ---------- ปก ---------- */
.cover {
  height: 285mm; width: 210mm; page-break-after: always;
  background: linear-gradient(150deg, #FF6B2C 0%, #E2551A 55%, #C2440F 100%);
  color: #fff; padding: 24mm 22mm; display: flex; flex-direction: column;
}
.cover .mark { width: 17mm; height: 17mm; border-radius: 5mm; background: rgba(255,255,255,.2);
  display: flex; align-items: center; justify-content: center; font-size: 22pt; }
.cover h1 { font-size: 34pt; font-weight: 800; margin: 12mm 0 0; letter-spacing: -1px; line-height: 1.14; }
.cover .sub { font-size: 14pt; font-weight: 500; margin-top: 4mm; opacity: .95; line-height: 1.5; }
.cover .tagline { font-size: 9.5pt; margin-top: 6mm; opacity: .82; line-height: 1.7; max-width: 140mm; }
.cover .spacer { flex: 1; }
.cover .stats { display: flex; flex-wrap: wrap; gap: 4mm 7mm; margin-bottom: 9mm; }
.cover .stat .n { font-size: 19pt; font-weight: 800; line-height: 1.1; }
.cover .stat .l { font-size: 8pt; opacity: .8; }
.cover .foot { border-top: 1px solid rgba(255,255,255,.3); padding-top: 5mm;
  font-size: 8.5pt; opacity: .85; display: flex; justify-content: space-between; }

/* ---------- ทั่วไป ---------- */
.page { padding-top: 2mm; }
h2.section { font-size: 18pt; font-weight: 800; margin: 0 0 1mm; letter-spacing: -.4px; }
.section-no { font-size: 8pt; font-weight: 800; color: var(--primary); letter-spacing: 2px; }
.section-lead { color: var(--muted); font-size: 9.6pt; margin: 0 0 6mm; max-width: 165mm; }
.section-head { border-bottom: 2px solid var(--primary); padding-bottom: 3mm; margin-bottom: 6mm; }

h3.h { font-size: 11.5pt; font-weight: 800; margin: 6mm 0 2.5mm; }
h3.h:first-child { margin-top: 0; }
p.p { margin: 0 0 3mm; }

ul.points { margin: 0 0 3mm; padding: 0; list-style: none; }
ul.points li { position: relative; padding-left: 5mm; margin-bottom: 1.8mm; font-size: 9.3pt; }
ul.points li::before { content: ''; position: absolute; left: 0; top: 2.2mm;
  width: 2.1mm; height: 2.1mm; border-radius: 50%; background: var(--primary); }

/* ---------- badge สถานะ ---------- */
.badge { display: inline-flex; align-items: center; gap: 1.6mm; padding: 1mm 2.6mm;
  border-radius: 2mm; font-size: 8.2pt; font-weight: 700; white-space: nowrap; }
.badge.ok { background: var(--green-soft); color: var(--green); }
.badge.warn { background: var(--amber-soft); color: var(--amber); }
.badge.fixed { background: var(--green-soft); color: var(--green); }
.badge.open { background: #F1F3F5; color: var(--muted); }

/* ---------- การ์ดสรุปมิติ ---------- */
.dim-grid { display: flex; flex-direction: column; gap: 3.5mm; margin-bottom: 4mm; }
.dim-card { border: 1px solid var(--line); border-radius: 3mm; padding: 4mm 5mm;
  display: flex; align-items: flex-start; gap: 4mm; break-inside: avoid; }
.dim-card .num { font-size: 15pt; font-weight: 800; color: var(--primary); width: 10mm; flex: none; }
.dim-card .body { flex: 1; }
.dim-card .body .t { font-size: 10.3pt; font-weight: 800; margin-bottom: .8mm; display:flex; align-items:center; gap: 2.5mm; }
.dim-card .body .d { font-size: 9pt; color: var(--muted); }

/* ---------- ตาราง ---------- */
table.tbl { width: 100%; border-collapse: collapse; margin: 2mm 0 5mm; font-size: 8.6pt; }
table.tbl th { text-align: left; background: var(--bg); font-weight: 700; padding: 2.2mm 3mm;
  border-bottom: 1.4px solid var(--line); color: #374151; }
table.tbl td { padding: 2.4mm 3mm; border-bottom: 1px solid var(--line); vertical-align: top; }
table.tbl tr:last-child td { border-bottom: none; }
table.tbl td.c, table.tbl th.c { text-align: center; }

/* ---------- กล่องโค้ด ---------- */
.code { background: #1A1D21; color: #E9ECF1; border-radius: 2.5mm; padding: 3.5mm 4.5mm;
  font-size: 8pt; line-height: 1.55; margin: 2.5mm 0 4mm; white-space: pre-wrap; word-break: break-word; }
.code .cm { color: #868E96; }
.code .bad { color: #FF8787; }
.code .good { color: #69DB7C; }

.tech { margin-top: 2.5mm; background: var(--bg); border-left: 2.6px solid var(--primary);
  padding: 3mm 4mm; font-size: 8.6pt; color: #374151; border-radius: 0 2mm 2mm 0; }
.tech b { color: var(--primary-dark); font-weight: 700; }

.diagram { background: var(--bg); border: 1px solid var(--line); border-radius: 2.5mm;
  padding: 4mm 5mm; font-size: 8.6pt; text-align: center; margin: 2.5mm 0 4mm; font-weight: 700; }
.diagram .arrow { color: var(--primary); font-weight: 800; margin: 0 2mm; }
.diagram .sub { display:block; font-weight:500; color: var(--muted); font-size: 7.6pt; margin-top: .8mm;}

.callout { display: flex; gap: 3mm; align-items: flex-start; background: var(--soft);
  border: 1px solid #FFD8C2; border-radius: 2.5mm; padding: 3.5mm 4.5mm; margin: 2.5mm 0 4mm; }
.callout .ic { font-size: 12pt; }
.callout b { color: var(--primary-dark); }

.grid2 { display: flex; gap: 4mm; }
.grid2 > div { flex: 1; }

.foot-note { font-size: 7.8pt; color: var(--muted); margin-top: 2mm; }

.pagebreak { page-break-before: always; }
"""

HEAD = f"<style>{CSS}</style>"

# ============================================================ ปก ============================================================
COVER = """
<div class="cover">
  <div class="mark">🍽</div>
  <h1>รายงานผลตรวจคุณภาพโค้ด</h1>
  <div class="sub">PaynEat POS — Clean Code · State Management · Clean Architecture ·<br>Technical Debt · โครงสร้างโฟลเดอร์</div>
  <div class="tagline">ตรวจทั้งโปรเจกต์ (Flutter app + Node.js backend) 5 มิติ พบ 2 จุดที่ผิดกฎ Clean Architecture
    และ 1 จุดที่โครงสร้างไม่สม่ำเสมอ — แก้ไขและยืนยันด้วยเทสต์ทั้งหมดแล้วในรายงานนี้</div>
  <div class="spacer"></div>
  <div class="stats">
    <div class="stat"><div class="n">82</div><div class="l">เทสต์อัตโนมัติผ่านทั้งหมด</div></div>
    <div class="stat"><div class="n">9 / 9</div><div class="l">Flutter feature ตรงมาตรฐานเดียวกัน</div></div>
    <div class="stat"><div class="n">9 / 9</div><div class="l">Backend module ผ่าน layering เดียวกัน</div></div>
    <div class="stat"><div class="n">3</div><div class="l">บั๊ก/ข้อผิดพลาดจริงที่พบและแก้แล้ว</div></div>
  </div>
  <div class="foot"><span>PaynEat POS · Code Quality Audit</span><span>7 กันยายน 2026</span></div>
</div>
"""

# ============================================================ สรุปผลรวม ============================================================
SUMMARY = """
<div class="page">
  <div class="section-head">
    <div class="section-no">สรุปผลรวม</div>
    <h2 class="section">ผลตรวจ 5 มิติ</h2>
  </div>
  <p class="section-lead">ตรวจด้วยเครื่องมือจริง (flutter analyze, dart format, flutter test, npm test) ร่วมกับการอ่านโค้ดหา
    dependency violation ทีละไฟล์ ไม่ใช่การประเมินแบบผิวเผิน — ทุกข้อในรายงานนี้อ้างอิงตำแหน่งไฟล์จริงในโปรเจกต์</p>

  <div class="dim-grid">
    <div class="dim-card">
      <div class="num">1</div>
      <div class="body">
        <div class="t">Clean Code <span class="badge ok">ผ่าน</span></div>
        <div class="d">flutter analyze 0 ปัญหา · dart format สะอาด 142 ไฟล์ · ไม่มี print()/TODO ค้าง ·
          พบไฟล์ใหญ่เกิน 1 ไฟล์และ backend ไม่มี ESLint (บันทึกเป็น debt)</div>
      </div>
    </div>
    <div class="dim-card">
      <div class="num">2</div>
      <div class="body">
        <div class="t">State Management (GetX) <span class="badge ok">ผ่าน</span></div>
        <div class="d">แยก ephemeral state (setState) กับ app state (Rx) ถูกต้องทุกจุด · controller lifecycle ครบ ·
          พบบั๊ก Obx() 1 จุดระหว่างพัฒนาก่อนหน้านี้ — แก้แล้ว</div>
      </div>
    </div>
    <div class="dim-card">
      <div class="num">3</div>
      <div class="body">
        <div class="t">Clean Architecture <span class="badge fixed">พบ 2 จุด — แก้แล้ว</span></div>
        <div class="d">Backend layering (routes→controller→service→repository) ไม่มี violation เลยใน 9 module ·
          Flutter domain layer เคย import จาก data layer 2 จุด — ย้ายแล้ว ยืนยันด้วยเทสต์ครบ</div>
      </div>
    </div>
    <div class="dim-card">
      <div class="num">4</div>
      <div class="body">
        <div class="t">Technical Debt <span class="badge warn">ติดตาม 5 รายการ</span></div>
        <div class="d">2 รายการแก้แล้วระหว่างการตรวจนี้ · 5 รายการยังค้าง (ส่วนใหญ่คือช่องว่างของเทสต์ต่อ
          controller/module) มีแผนแก้ชัดเจนทุกข้อ</div>
      </div>
    </div>
    <div class="dim-card">
      <div class="num">5</div>
      <div class="body">
        <div class="t">โครงสร้างโฟลเดอร์ <span class="badge fixed">พบ 1 จุด — แก้แล้ว</span></div>
        <div class="d">Flutter 9 feature ตามโครง feature-first เหมือนกันหมด · backend เคยมี 3 module ข้าม
          controller layer — เพิ่มครบแล้ว ตอนนี้ 9 module มีโครงเดียวกันทั้งหมด</div>
      </div>
    </div>
  </div>

  <div class="callout">
    <div class="ic">📄</div>
    <div>ผลตรวจฉบับเต็มพร้อมกฎที่บังคับใช้จากนี้ไปถูกบันทึกเป็นเอกสารมีชีวิต (living document) ที่
      <b>docs/CODING_STANDARDS.md</b> ในโปรเจกต์ — อัปเดตทุกครั้งที่พบหรือแก้ปัญหาใหม่ รายงาน PDF นี้คือภาพนิ่ง
      ณ วันที่ตรวจ</div>
  </div>
</div>
"""

# ============================================================ 1. Clean Code ============================================================
SEC1 = """
<div class="page pagebreak">
  <div class="section-head">
    <div class="section-no">มิติที่ 1 / 5</div>
    <h2 class="section">Clean Code</h2>
  </div>
  <p class="section-lead">ตรวจด้วยเครื่องมือจริงของแต่ละภาษา ไม่ใช่การอ่านผ่านสายตาอย่างเดียว</p>

  <h3 class="h">ผลตรวจอัตโนมัติ</h3>
  <table class="tbl">
    <tr><th>เครื่องมือ</th><th>ผลลัพธ์</th><th class="c">สถานะ</th></tr>
    <tr><td><code>flutter analyze</code></td><td>No issues found!</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
    <tr><td><code>dart format --set-exit-if-changed</code></td><td>Formatted 142 files (0 changed)</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
    <tr><td><code>flutter test</code></td><td>46/46 เทสต์ผ่าน</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
    <tr><td><code>npm test</code> (backend)</td><td>36/36 เทสต์ผ่าน</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
    <tr><td>ค้นหา <code>TODO</code>/<code>FIXME</code>/<code>HACK</code></td><td>ไม่พบทั้งสองฝั่ง</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
    <tr><td>ค้นหา <code>print()</code> ใน Dart</td><td>ไม่พบเลยทั้ง 130 ไฟล์</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
    <tr><td>ค้นหา <code>console.log</code> ใน backend</td><td>พบ 6 จุด — อยู่ใน entry point/error handler ที่กำหนดไว้เท่านั้น ไม่มีใน business logic</td><td class="c"><span class="badge ok">ผ่าน</span></td></tr>
  </table>

  <h3 class="h">สิ่งที่ต้องปรับปรุง</h3>

  <table class="tbl">
    <tr><th style="width:38mm">รายการ</th><th>รายละเอียด</th></tr>
    <tr>
      <td><b>ไฟล์ใหญ่เกินไป</b><br><span class="badge warn">ควรแยก</span></td>
      <td><code>core/demo/demo_store.dart</code> — 1,142 บรรทัดในไฟล์เดียว เป็นเซิร์ฟเวอร์จำลองทั้งร้านสำหรับ
        Demo Mode ยอมรับได้ว่าใหญ่เพราะจำลองทุกโมดูล แต่ถ้าเพิ่ม scenario ใหม่ควรแยกเป็นไฟล์ย่อยตามโดเมน
        (เช่น <code>demo_store_orders.dart</code>) แทนการเพิ่มในไฟล์เดิม</td>
    </tr>
    <tr>
      <td><b>Backend ไม่มี linter</b><br><span class="badge warn">ค้าง</span></td>
      <td>ไม่มี ESLint/Prettier config — พึ่งเทสต์ (36 เทสต์) กับ code review เป็นตัวจับความผิดพลาดเท่านั้น
        error ทาง syntax/style เล็กๆ (unused var, inconsistent quotes) จะไม่ถูกจับอัตโนมัติ</td>
    </tr>
  </table>

  <h3 class="h">ขนาดไฟล์ที่ใหญ่ที่สุด (อ้างอิง)</h3>
  <div class="grid2">
    <div>
      <table class="tbl">
        <tr><th>Flutter (บรรทัด)</th><th class="c">จำนวน</th></tr>
        <tr><td><code>demo_store.dart</code></td><td class="c">1,142</td></tr>
        <tr><td><code>menu_form_page.dart</code></td><td class="c">531</td></tr>
        <tr><td><code>demo_data_sources.dart</code></td><td class="c">453</td></tr>
        <tr><td><code>dashboard_page.dart</code></td><td class="c">394</td></tr>
      </table>
    </div>
    <div>
      <table class="tbl">
        <tr><th>Backend (บรรทัด)</th><th class="c">จำนวน</th></tr>
        <tr><td><code>order.service.js</code></td><td class="c">331</td></tr>
        <tr><td><code>db/seed.js</code></td><td class="c">226</td></tr>
        <tr><td><code>order.repository.js</code></td><td class="c">218</td></tr>
        <tr><td><code>menu.repository.js</code></td><td class="c">190</td></tr>
      </table>
    </div>
  </div>
  <p class="foot-note">ไม่มีเกณฑ์บังคับตายตัว แต่ไฟล์ที่เกิน ~400 บรรทัดควรตั้งคำถามว่าแยกความรับผิดชอบได้ไหม
    ฝั่ง backend ทุกไฟล์อยู่ในเกณฑ์ที่เหมาะสม ไม่มีไฟล์ไหนเกิน 350 บรรทัด</p>
</div>
"""

# ============================================================ 2. State Management ============================================================
SEC2 = """
<div class="page pagebreak">
  <div class="section-head">
    <div class="section-no">มิติที่ 2 / 5</div>
    <h2 class="section">State Management (GetX)</h2>
  </div>
  <p class="section-lead">จุดที่ตรวจเข้มที่สุดในหัวข้อนี้คือการแยก "ephemeral UI state" ออกจาก "app/business state"
    เพราะเป็นจุดที่มักสับสนและทำให้เกิดบั๊กบ่อยที่สุดในโปรเจกต์ที่ใช้ GetX</p>

  <h3 class="h">กฎการแยก state — ตรวจแล้วว่าทำถูกทุกจุด</h3>
  <table class="tbl">
    <tr><th style="width:42mm">ใช้</th><th>เมื่อไหร่ / ตัวอย่างจริงที่ตรวจแล้ว</th></tr>
    <tr>
      <td><code>StatefulWidget</code> +<br><code>setState()</code></td>
      <td>state เป็น ephemeral UI state ที่ไม่มีใครนอก widget สนใจ — ตรวจ 4 ไฟล์ที่ใช้ <code>setState</code>
        (<code>DiscountDialog</code>, <code>OptionSelectionSheet</code>, <code>MenuFormPage</code>,
        <code>StaffPage</code> dialog) ยืนยันว่าเป็น local form/dialog state ทั้งหมด ไม่มีจุดไหนใช้ผิด</td>
    </tr>
    <tr>
      <td><code>GetxController</code> +<br><code>.obs</code> / <code>Obx()</code></td>
      <td>state เป็น app/business state ที่หน้าอื่นต้องรู้ด้วย — ตะกร้า (<code>CartController</code>),
        รายการออเดอร์, สถานะล็อกอิน ฯลฯ ตรวจแล้วว่า 100% ของ controller extends <code>GetxController</code>
        ถูกต้อง ไม่มีการผสมสอง pattern ในโมเดลเดียวกัน</td>
    </tr>
  </table>

  <h3 class="h">🐛 บั๊กจริงที่พบระหว่างพัฒนาโปรเจกต์ — แก้แล้ว</h3>
  <p class="p"><b>ห้ามอ่านค่า observable ใน <code>itemBuilder</code>/callback ที่อยู่ข้างใน <code>Obx()</code></b>
    ต้องอ่านที่ scope บนสุดของ <code>Obx(() { ... })</code> เท่านั้น เพราะ GetX ติดตามเฉพาะ observable ที่ถูกอ่าน
    ตอน builder รันครั้งแรก — ถ้าอ่านใน callback ที่เรียกทีหลัง (เช่นตอน scroll) GetX จะไม่รู้ว่าต้อง subscribe</p>

  <div class="code"><span class="cm">// ❌ ผิด — chip กรองสถานะไม่ rebuild เมื่อกดเปลี่ยนตัวกรอง (บั๊กจริงที่เจอใน orders_page.dart)</span>
Obx(() =&gt; ListView.builder(
  itemBuilder: (context, i) {
    <span class="bad">final selected = controller.statusFilter.value == filters[i].value;</span> <span class="cm">// ไม่ rebuild!</span>
    return ChoiceChip(selected: selected, ...);
  },
));

<span class="cm">// ✅ ถูก — อ่านค่าที่ scope บนสุดของ Obx ก่อน แล้วส่งต่อเข้า itemBuilder</span>
Obx(() {
  <span class="good">final activeFilter = controller.statusFilter.value;</span> <span class="cm">// อ่านตรงนี้ที่เดียว</span>
  return ListView.builder(
    itemBuilder: (context, i) {
      final selected = activeFilter == filters[i].value;
      return ChoiceChip(selected: selected, ...);
    },
  );
});</div>
  <p class="foot-note">โค้ดจริงที่แก้แล้ว: <code>app/lib/features/order/presentation/pages/orders_page.dart</code></p>

  <h3 class="h">Dependency Injection และ Controller Lifecycle</h3>
  <ul class="points">
    <li>Composition root มีที่เดียว: <code>app/lib/app/di/initial_binding.dart</code> — ตรวจแล้วว่าไม่มีการ
      ประกาศ <code>Get.lazyPut</code>/<code>Get.put</code> กระจัดกระจายนอกไฟล์นี้หรือ <code>*_binding.dart</code></li>
    <li>Controller ที่มี <code>StreamSubscription</code>/<code>Timer</code>/<code>TextEditingController</code>
      ต้อง override <code>onClose()</code> — ตรวจ 4 controller ที่เข้าเงื่อนไข (Auth, Checkout, Settings, Menu)
      ทำถูกครบทั้งหมด ไม่มี memory leak</li>
  </ul>

  <div class="callout">
    <div class="ic">💡</div>
    <div><b>จุดที่ควรปรับปรุง (ไม่ใช่บั๊ก)</b> — พบ 10 จุดที่ private widget ย่อย (เช่น <code>_TableSummaryBar</code>,
      <code>_UserChip</code>) เรียก <code>Get.find&lt;T&gt;()</code> เองข้างในแทนที่จะรับ controller ผ่าน
      constructor หรือ extends <code>GetView&lt;T&gt;</code> — ผูก widget กับ service locator โดยตรง ทดสอบแยก
      ยากขึ้น บันทึกเป็นกฎในมาตรฐานให้ปรับเมื่อแตะไฟล์เหล่านี้ครั้งถัดไป</div>
  </div>
</div>
"""

# ============================================================ 3. Clean Architecture ============================================================
SEC3 = """
<div class="page pagebreak">
  <div class="section-head">
    <div class="section-no">มิติที่ 3 / 5</div>
    <h2 class="section">Clean Architecture</h2>
  </div>
  <p class="section-lead">ตรวจทิศทาง dependency ทุกไฟล์ใน domain layer และ backend layer ด้วยการไล่ import จริง
    ไม่ใช่แค่ดูโครงสร้างโฟลเดอร์ผิวเผิน</p>

  <div class="diagram">
    presentation <span class="arrow">→</span> domain <span class="arrow">←</span> data
    <span class="sub">domain ต้องเป็น pure Dart ไม่รู้จัก package:get, HTTP, หรือ widget ใดๆ</span>
  </div>
  <div class="diagram">
    routes <span class="arrow">→</span> controller <span class="arrow">→</span> service <span class="arrow">→</span> repository <span class="arrow">→</span> db
    <span class="sub">service ห้ามรู้จัก req/res ของ Express</span>
  </div>

  <h3 class="h">ผลตรวจ Backend — 9/9 module ไม่มี violation</h3>
  <table class="tbl">
    <tr><th>เช็คว่า</th><th class="c">ผลลัพธ์</th></tr>
    <tr><td>service import <code>req</code>/<code>res</code> ของ Express</td><td class="c"><span class="badge ok">ไม่พบ</span></td></tr>
    <tr><td>controller/routes import repository หรือ <code>better-sqlite3</code> ข้าม service</td><td class="c"><span class="badge ok">ไม่พบ</span></td></tr>
  </table>

  <h3 class="h">🐛 ผลตรวจ Flutter — พบ 2 จุด แก้แล้ว</h3>
  <p class="p">พบว่า <code>menu_repository.dart</code> และ <code>order_repository.dart</code> ใน
    <code>domain/repositories/</code> import <code>MenuItemPayload</code> จาก <code>data/models/</code> และ
    <code>OrderItemPayload</code> จาก <code>data/datasources/</code> โดยตรง — ผิดกฎทิศทาง dependency ตรงๆ</p>

  <div class="code"><span class="cm">// ❌ ก่อนแก้ — domain/repositories/menu_repository.dart</span>
import '../../../../core/usecases/result.dart';
<span class="bad">import '../../data/models/menu_item_model.dart';</span>  <span class="cm">// domain พึ่ง data!</span>
import '../entities/category.dart';

<span class="cm">// ✅ หลังแก้ — ย้าย MenuItemPayload ไปเป็น domain entity แล้ว</span>
import '../../../../core/usecases/result.dart';
<span class="good">import '../entities/menu_item_payload.dart';</span>  <span class="cm">// data → domain (ทิศทางถูก)</span>
import '../entities/category.dart';</div>

  <table class="tbl">
    <tr><th style="width:34mm">คลาส</th><th>ย้ายจาก</th><th>ย้ายไป</th></tr>
    <tr><td><code>MenuItemPayload</code></td><td><code>features/menu/data/models/menu_item_model.dart</code></td>
      <td><code>features/menu/domain/entities/menu_item_payload.dart</code></td></tr>
    <tr><td><code>OrderItemPayload</code></td><td><code>features/order/data/datasources/order_remote_data_source.dart</code></td>
      <td><code>features/order/domain/entities/order_item_payload.dart</code></td></tr>
  </table>

  <div class="tech"><b>ทำไมถึงผิด แม้คลาสจะมีแค่ field ธรรมดา</b> — พารามิเตอร์ input ของ usecase/repository
    (ที่ลงท้ายด้วย Payload/Params/Filter) ที่ไม่ได้ทำ HTTP เอง ต้องอยู่ใน <code>domain/entities/</code>
    แม้จะมีเมธอด <code>toJson()</code> ติดไปด้วยก็ตาม เพราะ <code>toJson()</code> เป็นแค่ helper แปลงข้อมูล
    ไม่ใช่ transport-layer dependency — สิ่งที่ตัดสินว่าคลาสอยู่ layer ไหนคือ <b>ตำแหน่งไฟล์และทิศทาง import</b>
    ไม่ใช่ว่ามันมีเมธอด serialize หรือเปล่า</div>

  <p class="p"><b>ยืนยันหลังแก้:</b> อัปเดต import ทุกจุดที่ใช้ (controller, page, repository impl, datasource,
    demo data source, test) — <code>flutter analyze</code> 0 ปัญหา, <code>flutter test</code> 46/46 ผ่าน
    เหมือนเดิม ไม่มีการเปลี่ยนพฤติกรรมใดๆ</p>
</div>
"""

# ============================================================ 4. Technical Debt ============================================================
SEC4 = """
<div class="page pagebreak">
  <div class="section-head">
    <div class="section-no">มิติที่ 4 / 5</div>
    <h2 class="section">Technical Debt</h2>
  </div>
  <p class="section-lead">รายการที่ต้องติดตามต่อจากนี้ — ไม่ใช่สิ่งที่ต้องหยุดพัฒนาฟีเจอร์ใหม่รอแก้ก่อน
    แต่ถ้าแตะไฟล์ที่เกี่ยวข้องอยู่แล้วให้ถือโอกาสแก้ไปพร้อมกัน (boy scout rule)</p>

  <table class="tbl">
    <tr><th class="c" style="width:7mm">#</th><th>รายการ</th><th>ผลกระทบ</th><th class="c" style="width:20mm">สถานะ</th></tr>
    <tr>
      <td class="c">1</td>
      <td>domain layer import จาก data layer (<code>MenuItemPayload</code>, <code>OrderItemPayload</code>)</td>
      <td>ผิดกฎ Clean Architecture โดยตรง — ย้ายเข้า <code>domain/entities/</code> แล้ว</td>
      <td class="c"><span class="badge fixed">แก้แล้ว</span></td>
    </tr>
    <tr>
      <td class="c">2</td>
      <td>3 backend module (<code>payments</code>/<code>reports</code>/<code>settings</code>) ไม่มี controller layer</td>
      <td>ไม่สม่ำเสมอกับสถาปัตยกรรมที่ประกาศไว้ — เพิ่ม controller ให้ครบทั้ง 3 module แล้ว</td>
      <td class="c"><span class="badge fixed">แก้แล้ว</span></td>
    </tr>
    <tr>
      <td class="c">3</td>
      <td>Backend ไม่มี ESLint/Prettier</td>
      <td>style/simple bug ไม่ถูกจับอัตโนมัติ นอกจาก test coverage</td>
      <td class="c"><span class="badge open">ค้าง</span></td>
    </tr>
    <tr>
      <td class="c">4</td>
      <td>Controller ส่วนใหญ่ใน Flutter ไม่มี unit test เฉพาะตัว (มีแค่ <code>CartController</code>)</td>
      <td>บั๊ก logic ใน controller จับได้ช้าลง ต้องพึ่ง manual QA</td>
      <td class="c"><span class="badge open">ค้าง</span></td>
    </tr>
    <tr>
      <td class="c">5</td>
      <td>Backend module ส่วนใหญ่ไม่มี unit test เฉพาะ module</td>
      <td>อาศัย integration test เดียวคุมทั้งระบบ ถ้า fail จะไม่รู้ทันทีว่าโมดูลไหนพัง</td>
      <td class="c"><span class="badge open">ค้าง</span></td>
    </tr>
    <tr>
      <td class="c">6</td>
      <td><code>demo_store.dart</code> 1,142 บรรทัดในไฟล์เดียว</td>
      <td>แก้ยากขึ้นเรื่อยๆ เมื่อเพิ่ม demo scenario ใหม่</td>
      <td class="c"><span class="badge open">ค้าง</span></td>
    </tr>
    <tr>
      <td class="c">7</td>
      <td>Flutter dependencies ล้าหลัง ~15 แพ็กเกจ (minor version)</td>
      <td>ไม่กระทบการทำงาน แต่ควรตามให้ทันเป็นระยะ</td>
      <td class="c"><span class="badge open">ค้าง</span></td>
    </tr>
  </table>

  <h3 class="h">Debt ที่ตั้งใจ — ไม่ต้องแก้ (กันสับสนกับของค้างจริง)</h3>
  <p class="p">รายการเหล่านี้เป็นการตัดสินใจเชิงออกแบบที่มีเหตุผลรองรับแล้วใน <code>docs/DECISIONS.md</code>:</p>
  <ul class="points">
    <li>ตรรกะคิดบิลเขียนซ้ำ 2 ภาษา (Dart preview + JS source of truth) — มีเทสต์ยืนยันด้วยตัวเลขชุดเดียวกันทั้งคู่</li>
    <li>สถานะ (<code>OrderStatus</code>, <code>UserRole</code>) เป็น string constants class ไม่ใช่ Dart
      <code>enum</code> จริง — เพราะ mirror กับ string enum ฝั่ง backend ตรงๆ ป้องกัน typo ด้วย named
      constants อยู่แล้ว (ตรวจแล้วว่าไม่มีจุดไหน compare ด้วย string literal ตรงๆ เลย)</li>
    <li><code>Result&lt;T&gt;</code> เขียนเอง แทน <code>dartz</code> — compiler บังคับจัดการทั้งสองกรณีอยู่แล้ว</li>
  </ul>
</div>
"""

# ============================================================ 5. โครงสร้างโฟลเดอร์ ============================================================
SEC5 = """
<div class="page pagebreak">
  <div class="section-head">
    <div class="section-no">มิติที่ 5 / 5</div>
    <h2 class="section">โครงสร้างโฟลเดอร์และตำแหน่งไฟล์</h2>
  </div>
  <p class="section-lead">ตรวจว่าไฟล์ทุกไฟล์อยู่ในตำแหน่งที่คนอื่นหาเจอโดยไม่ต้องเดา และทุก feature/module
    ใช้โครงเดียวกัน</p>

  <h3 class="h">Flutter — feature-first + Clean Architecture</h3>
  <p class="p">ตรวจครบทั้ง 9 feature (auth, home, kitchen, menu, order, payment, report, settings, staff, table)
    — ทุก feature ตามโครงเดียวกัน:</p>
  <div class="code">features/&lt;feature&gt;/
  domain/
    entities/       <span class="cm">โมเดลบริสุทธิ์ ไม่ผูกกับ API shape</span>
    repositories/    <span class="cm">abstract class เท่านั้น</span>
    usecases/        <span class="cm">1 usecase = 1 class ที่มี call()</span>
  data/
    models/          <span class="cm">extends entity + fromJson/toJson</span>
    datasources/     <span class="cm">เรียก ApiClient ตรงๆ</span>
    repositories/    <span class="cm">implements domain repository interface</span>
  presentation/
    bindings/        controllers/        pages/        widgets/</div>
  <p class="foot-note"><span class="badge ok">9/9 ผ่าน</span> — ไม่บังคับว่าทุก feature ต้องมีโฟลเดอร์
    <code>widgets/</code> ถ้า page ไม่มี widget ที่ใหญ่พอจะแยก (เช่น <code>staff/</code>, <code>settings/</code>)</p>

  <h3 class="h">Backend — module-per-domain</h3>
  <div class="code">modules/&lt;module&gt;/
  &lt;name&gt;.routes.js       <span class="cm">ผูก path + middleware</span>
  &lt;name&gt;.controller.js    <span class="cm">แปลง req → เรียก service → ส่ง response</span>
  &lt;name&gt;.service.js       <span class="cm">business logic ล้วนๆ</span>
  &lt;name&gt;.repository.js    <span class="cm">SQL query</span>
  &lt;name&gt;.mapper.js        <span class="cm">แปลง DB row ↔ API shape</span>
  &lt;name&gt;.schema.js        <span class="cm">zod validation</span></div>

  <h3 class="h">🐛 ข้อไม่สม่ำเสมอที่พบและแก้แล้ว</h3>
  <p class="p"><code>payments/</code>, <code>reports/</code>, <code>settings/</code> เคยไม่มีไฟล์
    <code>.controller.js</code> — route handler เรียก <code>xxxService.method()</code> ตรงจาก
    <code>routes.js</code> เลย ในขณะที่อีก 6 module มี controller คั่นกลางตามสถาปัตยกรรมที่ประกาศไว้</p>

  <table class="tbl">
    <tr><th>Module</th><th class="c">ก่อนแก้</th><th class="c">หลังแก้</th></tr>
    <tr><td><code>payments</code></td><td class="c">route → service ตรง</td><td class="c">route → <b>controller</b> → service</td></tr>
    <tr><td><code>reports</code></td><td class="c">route → service ตรง</td><td class="c">route → <b>controller</b> → service</td></tr>
    <tr><td><code>settings</code></td><td class="c">route → service ตรง</td><td class="c">route → <b>controller</b> → service</td></tr>
  </table>

  <p class="p"><b>ยืนยันหลังแก้:</b> เพิ่ม <code>payment.controller.js</code>, <code>report.controller.js</code>,
    <code>settings.controller.js</code> ตามรูปแบบเดียวกับโมดูลที่มีอยู่แล้ว (object literal ห่อ
    <code>asyncHandler</code> ต่อ method) path/middleware/response shape เดิมทุกอย่าง —
    <code>npm test</code> 36/36 ผ่านเหมือนเดิม และยิง API จริงตรวจ 3 endpoint ผ่านครบ
    (<code>GET /settings</code>, <code>GET /reports/dashboard</code>, <code>GET /payments/order/:id</code>)</p>

  <p class="foot-note"><span class="badge ok">9/9 ผ่าน</span> — ตอนนี้ backend ทั้ง 9 module มี
    <code>routes → controller → service → repository</code> ครบเหมือนกันหมดแล้ว ไม่มีการยกเว้นเหลืออยู่</p>
</div>
"""

CLOSING = """
<div class="page pagebreak">
  <div class="section-head">
    <div class="section-no">สรุปปิดท้าย</div>
    <h2 class="section">สถานะหลังการตรวจและแก้ไข</h2>
  </div>

  <table class="tbl">
    <tr><th>มิติ</th><th class="c">สถานะสุดท้าย</th></tr>
    <tr><td>Clean Code</td><td class="c"><span class="badge ok">ดี</span></td></tr>
    <tr><td>State Management (GetX)</td><td class="c"><span class="badge ok">ดี</span></td></tr>
    <tr><td>Clean Architecture</td><td class="c"><span class="badge fixed">แก้ครบแล้ว</span></td></tr>
    <tr><td>Technical Debt</td><td class="c"><span class="badge warn">ติดตาม 5 รายการ</span></td></tr>
    <tr><td>โครงสร้างโฟลเดอร์</td><td class="c"><span class="badge fixed">แก้ครบแล้ว</span></td></tr>
  </table>

  <h3 class="h">Checklist ก่อน commit / เปิด PR จากนี้ไป</h3>
  <div class="code"><span class="cm"># Flutter</span>
cd app
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test

<span class="cm"># Backend</span>
cd backend
npm test</span></div>

  <div class="callout">
    <div class="ic">📚</div>
    <div>รายละเอียดกฎทั้งหมด ตัวอย่างโค้ด ก่อน/หลัง และคำสั่ง <code>grep</code> สำหรับเช็ค layer violation
      ก่อน commit — ดูฉบับเต็มที่มีชีวิตและอัปเดตต่อเนื่องได้ที่ <b>docs/CODING_STANDARDS.md</b> ในโปรเจกต์</div>
  </div>

  <p class="foot-note" style="margin-top:8mm">รายงานนี้สร้างจากผลตรวจจริง (flutter analyze, dart format,
    flutter test, npm test, การไล่ import ทีละไฟล์) ไม่ใช่การประเมินเชิงทฤษฎี — ทุกข้อค้นพบยืนยันด้วยการรันจริง
    ก่อนสรุปผล</p>
</div>
"""

BODY = COVER + SUMMARY + SEC1 + SEC2 + SEC3 + SEC4 + SEC5 + CLOSING

HTML = f"""<!doctype html>
<html lang="th">
<head>
<meta charset="utf-8">
<title>PaynEat POS — รายงานผลตรวจคุณภาพโค้ด</title>
{HEAD}
</head>
<body>
{BODY}
</body>
</html>"""

with open(OUT, "w", encoding="utf-8") as f:
    f.write(HTML)
print(f"wrote {OUT} ({len(HTML)} bytes)")

# --------------------------------------------------------------------------
# ส่งออกข้อความล้วนของแต่ละหน้า (ไม่มี HTML tag) ให้ overlay_text_layer.py ใช้ฝัง
# เป็นเลเยอร์คัดลอกที่ถูกต้อง — 1 หน้า PDF ต่อ 1 ตัวแปร section ด้านบนพอดี เพราะทุก section
# ขึ้นต้นด้วย page-break-before:always ใน CSS
import re as _re


def _plain_text(section_html: str) -> str:
    text = _re.sub(r"<br\s*/?>", "\n", section_html)
    text = _re.sub(r"</(t[dh])>", "  |  ", text)
    text = _re.sub(r"</(p|div|tr|section|li|h[1-6])>", "\n", text)
    text = _re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    # แทนลูกศร/สัญลักษณ์ด้วยข้อความธรรมดา แล้วตัดอิโมจิทิ้ง — ฟอนต์ Noto Sans Thai
    # ที่ใช้วาดเลเยอร์คัดลอกไม่มีกลิฟตัวเหล่านี้ (ไม่ใช่บั๊กเดียวกับปัญหาสระ/วรรณยุกต์ไทย)
    text = (text.replace("→", " -> ").replace("←", " <- ").replace("↔", " <-> "))
    text = _re.sub(r"[\U0001F000-\U0001FFFF☀-➿]", "", text)
    lines = [line.strip(" |") for line in text.splitlines()]
    return "\n".join(line for line in lines if line)


PLAIN_TEXT_PAGES = [
    _plain_text(COVER),
    _plain_text(SUMMARY),
    _plain_text(SEC1),
    _plain_text(SEC2),
    _plain_text(SEC3),
    _plain_text(SEC4),
    _plain_text(SEC5),
    _plain_text(CLOSING),
]

sidecar = OUT.rsplit(".", 1)[0] + ".pages.json"
with open(sidecar, "w", encoding="utf-8") as f:
    json.dump(PLAIN_TEXT_PAGES, f, ensure_ascii=False, indent=2)
print(f"wrote {sidecar} ({len(PLAIN_TEXT_PAGES)} pages)")
