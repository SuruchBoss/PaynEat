# -*- coding: utf-8 -*-
"""สร้างไฟล์ HTML สำหรับเรนเดอร์เป็น PDF เอกสารนำเสนอผลงาน"""
import html
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# เลือกไฟล์เนื้อหาตามภาษา: `python3 build.py out.html content_en`
CONTENT_MODULE = sys.argv[2] if len(sys.argv) > 2 else "content"
_c = __import__(CONTENT_MODULE)
TITLE, SUBTITLE, TAGLINE = _c.TITLE, _c.SUBTITLE, _c.TAGLINE
INTRO, SECTIONS, CLOSING, L = _c.INTRO, _c.SECTIONS, _c.CLOSING, _c.LABELS

IMG_DIR = "images"
FONT_DIR = "fonts"


def esc(text):
    return html.escape(str(text))


CSS = """
@page { size: A4; margin: 14mm 13mm 16mm 13mm; }
@page :first { margin: 0; }

@font-face { font-family: 'Noto'; src: url('FONTDIR/FONTFAM-400.ttf'); font-weight: 400; }
@font-face { font-family: 'Noto'; src: url('FONTDIR/FONTFAM-500.ttf'); font-weight: 500; }
@font-face { font-family: 'Noto'; src: url('FONTDIR/FONTFAM-700.ttf'); font-weight: 700; }
@font-face { font-family: 'Noto'; src: url('FONTDIR/FONTFAM-800.ttf'); font-weight: 800; }

:root {
  --primary: #FF6B2C;
  --primary-dark: #E2551A;
  --soft: #FFF1EA;
  --ink: #1A1D21;
  --muted: #6B7280;
  --line: #E5E7EB;
  --bg: #F6F7F9;
  --green: #2F9E44;
  --blue: #1971C2;
}

* { box-sizing: border-box; }
body { font-family: 'Noto', sans-serif; color: var(--ink); margin: 0; font-size: 9.6pt; line-height: 1.62; }

/* ---------- ปก ---------- */
.cover {
  height: 285mm; width: 210mm; page-break-after: always;
  background: linear-gradient(150deg, #FF6B2C 0%, #E2551A 55%, #C2440F 100%);
  color: #fff; padding: 24mm 22mm; display: flex; flex-direction: column;
}
.cover .mark { width: 17mm; height: 17mm; border-radius: 5mm; background: rgba(255,255,255,.2);
  display: flex; align-items: center; justify-content: center; font-size: 22pt; }
.cover h1 { font-size: 40pt; font-weight: 800; margin: 12mm 0 0; letter-spacing: -1px; line-height: 1.05; }
.cover .sub { font-size: 17pt; font-weight: 500; margin-top: 3mm; opacity: .95; }
.cover .tagline { font-size: 9.5pt; margin-top: 6mm; opacity: .82; line-height: 1.7; max-width: 130mm; }
.cover .spacer { flex: 1; }
.cover .stats { display: flex; flex-wrap: wrap; gap: 4mm 7mm; margin-bottom: 9mm; }
.cover .stat .n { font-size: 19pt; font-weight: 800; line-height: 1.1; }
.cover .stat .l { font-size: 8pt; opacity: .8; }
.cover .foot { border-top: 1px solid rgba(255,255,255,.3); padding-top: 5mm;
  font-size: 8.5pt; opacity: .85; display: flex; justify-content: space-between; }

/* ---------- ทั่วไป ---------- */
h2.section { font-size: 19pt; font-weight: 800; margin: 0 0 1mm; letter-spacing: -.4px; }
.section-no { font-size: 8pt; font-weight: 800; color: var(--primary); letter-spacing: 2px; }
.section-lead { color: var(--muted); font-size: 10pt; margin: 0 0 7mm; max-width: 150mm; }
.section-head { border-bottom: 2px solid var(--primary); padding-bottom: 3mm; margin-bottom: 6mm; }

h3.page-title { font-size: 12.5pt; font-weight: 800; margin: 0 0 1mm; }
.page-lead { color: var(--primary-dark); font-size: 9.2pt; font-weight: 500; margin: 0 0 3mm; }

ul.points { margin: 0; padding: 0; list-style: none; }
ul.points li { position: relative; padding-left: 5mm; margin-bottom: 1.6mm; font-size: 9.2pt; }
ul.points li::before { content: ''; position: absolute; left: 0; top: 2.1mm;
  width: 2.1mm; height: 2.1mm; border-radius: 50%; background: var(--primary); }

.tech { margin-top: 3.5mm; background: var(--bg); border-left: 2.6px solid var(--primary);
  padding: 3mm 4mm; font-size: 8.6pt; color: #374151; border-radius: 0 2mm 2mm 0; }
.tech b { color: var(--primary-dark); font-weight: 700; }

.shot { break-inside: avoid; page-break-inside: avoid; margin-bottom: 8mm; }
.shot img { display: block; border: 1px solid var(--line); border-radius: 2.5mm; background: #fff; }

/* หน้าจอมือถือ: ภาพซ้าย เนื้อหาขวา */
.shot.phone { display: flex; gap: 7mm; align-items: flex-start; }
.shot.phone img { width: 52mm; flex: none; }
.shot.phone .body { flex: 1; padding-top: 1mm; }

/* หน้าจอกว้าง: ภาพเต็มความกว้าง เนื้อหาอยู่ใต้ภาพ */
.shot.wide img { width: 100%; margin-bottom: 4mm; }

.cols { display: flex; gap: 6mm; }
.cols > div { flex: 1; }

table.matrix { width: 100%; border-collapse: collapse; font-size: 8.8pt; }
table.matrix th, table.matrix td { border: 1px solid var(--line); padding: 1.9mm 3mm; text-align: left; }
table.matrix th { background: var(--soft); font-weight: 700; }
table.matrix td.tick { text-align: center; color: var(--green); font-weight: 800; }
table.matrix td.no { text-align: center; color: #C9CDD3; }

.callout { background: var(--soft); border-radius: 3mm; padding: 4mm 5mm; margin-bottom: 5mm; }
.callout h4 { margin: 0 0 2mm; font-size: 10.5pt; font-weight: 800; }
.callout p { margin: 0; font-size: 9.2pt; color: #374151; }

.bugs li { margin-bottom: 3mm; }
.bugs b { display: block; font-size: 9.4pt; }
.bugs span { color: var(--muted); font-size: 8.8pt; }

.page-break { page-break-before: always; }
.note { font-size: 8.2pt; color: var(--muted); font-style: italic; }
"""


def cover():
    stats = "".join(
        f'<div class="stat"><div class="n">{esc(n)}</div><div class="l">{esc(l)}</div></div>'
        for n, l in INTRO["stats"]
    )
    return f"""
<div class="cover">
  <div class="mark">🍽</div>
  <h1>{esc(TITLE)}</h1>
  <div class="sub">{esc(SUBTITLE)}</div>
  <div class="tagline">{esc(TAGLINE)}</div>
  <div class="spacer"></div>
  <div class="stats">{stats}</div>
  <div class="foot">
    <span>{esc(L['cover_foot_left'])}</span>
    <span>{esc(L['cover_foot_right'])}</span>
  </div>
</div>
"""


def overview():
    why = "".join(
        f'<li><b>{esc(t)}</b><br><span style="color:#374151">{esc(d)}</span></li>'
        for t, d in INTRO["why"]
    )
    roles = "".join(
        f"<tr><td><b>{esc(r)}</b></td><td>{esc(d)}</td><td>{esc(w)}</td></tr>"
        for r, d, w in INTRO["roles"]
    )
    toc = "".join(
        f'<tr><td style="width:14mm"><b style="color:var(--primary)">{esc(s["no"])}</b></td>'
        f'<td><b>{esc(s["title"])}</b><br><span style="color:var(--muted);font-size:8.6pt">'
        f'{esc(s["lead"])}</span></td>'
        f'<td style="width:22mm;text-align:right">{len(s["screens"])} {esc(L["screens_suffix"])}</td></tr>'
        for s in SECTIONS
    )
    return f"""
<div class="section-head">
  <div class="section-no">{esc(L['overview_kicker'])}</div>
  <h2 class="section">{esc(L['overview_title'])}</h2>
</div>

<div class="callout">
  <h4>{esc(L['problem_title'])}</h4>
  <p>{esc(L['problem_body'])}</p>
</div>

<ul class="points" style="margin-bottom:5mm">{why}</ul>

<h3 class="page-title">{esc(L['roles_title'])}</h3>
<table class="matrix" style="margin-bottom:5mm">
  <tr><th style="width:42mm">{esc(L['roles_headers'][0])}</th>
      <th style="width:42mm">{esc(L['roles_headers'][1])}</th>
      <th>{esc(L['roles_headers'][2])}</th></tr>
  {roles}
</table>

<h3 class="page-title">{esc(L['toc_title'])}</h3>
<table class="matrix">{toc}</table>

<p class="note" style="margin-top:4mm">{L['shots_note']}</p>
"""


def screen_block(screen, device):
    points = "".join(f"<li>{esc(p)}</li>" for p in screen["points"])
    cls = "phone" if device == "phone" else "wide"
    return f"""
<div class="shot {cls}">
  <img src="{IMG_DIR}/{screen['img']}" alt="{esc(screen['name'])}">
  <div class="body">
    <h3 class="page-title">{esc(screen['name'])}</h3>
    <p class="page-lead">{esc(screen['lead'])}</p>
    <ul class="points">{points}</ul>
    <div class="tech"><b>{esc(L['tech_label'])}</b> — {esc(screen['tech'])}</div>
  </div>
</div>
"""


def section_html(section):
    parts = [f"""
<div class="page-break"></div>
<div class="section-head">
  <div class="section-no">{esc(L['section_prefix'])} {esc(section['no'])}</div>
  <h2 class="section">{esc(section['title'])}</h2>
  <p class="section-lead" style="margin-bottom:0">{esc(section['lead'])}</p>
</div>
"""]
    for screen in section["screens"]:
        device = "phone" if screen["img"].startswith("phone") else "wide"
        parts.append(screen_block(screen, device))
    return "".join(parts)


def closing():
    bugs = "".join(
        f"<li><b>{esc(t)}</b><span>{esc(d)}</span></li>" for t, d in CLOSING["found_bugs"]
    )
    nxt = "".join(f"<li>{esc(x)}</li>" for x in CLOSING["next"])
    rows = "".join(
        f"<tr><td>{esc(a)}</td><td>{esc(b)}</td><td>{esc(c)}</td></tr>"
        for a, b, c in L["tests_rows"]
    )
    return f"""
<div class="page-break"></div>
<div class="section-head">
  <div class="section-no">{esc(L['section_prefix'])} {esc(L['closing_no'])}</div>
  <h2 class="section">{esc(L['closing_title'])}</h2>
  <p class="section-lead" style="margin-bottom:0">{esc(L['closing_lead'])}</p>
</div>

<div class="callout">
  <h4>{esc(L['closing_callout_title'])}</h4>
  <p>{esc(L['closing_callout_body'])}</p>
</div>

<ul class="points bugs" style="margin-bottom:7mm">{bugs}</ul>

<h3 class="page-title">{esc(L['tests_title'])}</h3>
<table class="matrix" style="margin-bottom:7mm">
  <tr><th style="width:34mm">{esc(L['tests_headers'][0])}</th>
      <th style="width:24mm">{esc(L['tests_headers'][1])}</th>
      <th>{esc(L['tests_headers'][2])}</th></tr>
  {rows}
</table>

<h3 class="page-title">{esc(L['next_title'])}</h3>
<ul class="points">{nxt}</ul>

<p class="note" style="margin-top:8mm">{esc(L['closing_note'])}</p>
"""


def build():
    body = [cover(), overview()]
    body += [section_html(s) for s in SECTIONS]
    body.append(closing())
    css = CSS.replace("FONTDIR", FONT_DIR).replace("FONTFAM", L["font"])
    return (
        "<!doctype html><html lang='th'><head><meta charset='utf-8'>"
        f"<title>{esc(TITLE)} — {esc(SUBTITLE)}</title>"
        f"<style>{css}</style></head><body>{''.join(body)}</body></html>"
    )


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "document.html"
    with open(out, "w", encoding="utf-8") as f:
        f.write(build())
    print(f"wrote {out}")
