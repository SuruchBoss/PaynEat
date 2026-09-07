# -*- coding: utf-8 -*-
"""สร้างหน้า HTML ที่เล่นเป็นวิดีโอแนะนำระบบ แล้วให้ Chromium อัดหน้าจอออกมาเป็นไฟล์วิดีโอ

ใช้ไทม์ไลน์ของ CSS animation ล้วน ๆ ไม่มี JavaScript ควบคุมจังหวะ
ทำให้ผลลัพธ์เหมือนกันทุกครั้งที่เรนเดอร์
"""
import html
import sys

sys.path.insert(0, ".")
from storyboard import STORYBOARD_TH, STORYBOARD_EN  # noqa: E402

W, H = 1920, 1080
FONT_DIR = "fonts"
IMG_DIR = "images"
FADE = 0.5  # เวลาเฟดเข้า-ออกของแต่ละฉาก (วินาที)


def esc(t):
    return html.escape(str(t))


CSS_HEAD = f"""
@font-face {{ font-family:'Noto'; src:url('{FONT_DIR}/NotoSansThai-400.ttf'); font-weight:400; }}
@font-face {{ font-family:'Noto'; src:url('{FONT_DIR}/NotoSansThai-500.ttf'); font-weight:500; }}
@font-face {{ font-family:'Noto'; src:url('{FONT_DIR}/NotoSansThai-700.ttf'); font-weight:700; }}
@font-face {{ font-family:'Noto'; src:url('{FONT_DIR}/NotoSansThai-800.ttf'); font-weight:800; }}

:root {{
  --primary:#FF6B2C; --primary-dark:#E2551A; --ink:#12151A; --ink-2:#1C2027;
  --muted:#8A93A0; --line:rgba(255,255,255,.10); --soft:rgba(255,107,44,.14);
}}
* {{ box-sizing:border-box; margin:0; padding:0; }}
html, body {{ width:{W}px; height:{H}px; overflow:hidden; background:var(--ink); }}
body {{ font-family:'Noto',sans-serif; color:#fff; -webkit-font-smoothing:antialiased; }}

.stage {{ position:relative; width:{W}px; height:{H}px; }}
.scene {{ position:absolute; inset:0; opacity:0; display:flex; }}
/* เนื้อหาต้องอยู่เหนือชั้นแสงพื้นหลังเสมอ */
.scene > *:not(.bg-glow) {{ position:relative; z-index:1; }}

@keyframes sceneShow {{
  0%   {{ opacity:0; }}
  100% {{ opacity:1; }}
}}
@keyframes sceneHide {{
  0%   {{ opacity:1; }}
  100% {{ opacity:0; }}
}}
@keyframes riseIn {{
  0%   {{ opacity:0; transform:translateY(26px); }}
  100% {{ opacity:1; transform:translateY(0); }}
}}
@keyframes slideIn {{
  0%   {{ opacity:0; transform:translateX(-34px); }}
  100% {{ opacity:1; transform:translateX(0); }}
}}
@keyframes kenBurns {{
  0%   {{ transform:scale(1) translateY(0); }}
  100% {{ transform:scale(1.045) translateY(-10px); }}
}}
@keyframes barGrow {{
  0%   {{ transform:scaleX(0); }}
  100% {{ transform:scaleX(1); }}
}}
@keyframes popIn {{
  0%   {{ opacity:0; transform:scale(.86); }}
  70%  {{ opacity:1; transform:scale(1.04); }}
  100% {{ opacity:1; transform:scale(1); }}
}}

/* ---------- พื้นหลัง ---------- */
.bg-glow {{ position:absolute; inset:-22%; z-index:0; filter:blur(130px); opacity:.72;
  background:
    radial-gradient(closest-side, rgba(255,107,44,.85), rgba(255,107,44,0) 100%)
      76% 14% / 760px 620px no-repeat,
    radial-gradient(closest-side, rgba(255,107,44,.42), rgba(255,107,44,0) 100%)
      6% 92% / 700px 560px no-repeat; }}

/* ---------- ฉากเปิด ---------- */
.title-scene {{ flex-direction:column; justify-content:center; padding:0 150px; }}
.mark {{ width:108px; height:108px; border-radius:30px; background:var(--soft);
  border:1px solid rgba(255,107,44,.34); display:flex; align-items:center; justify-content:center;
  font-size:52px; margin-bottom:44px; }}
.title-scene h1 {{ font-size:118px; font-weight:800; letter-spacing:-3px; line-height:1; }}
.title-scene .sub {{ font-size:44px; font-weight:500; color:#E9ECF1; margin-top:22px; }}
.title-scene .note {{ font-size:23px; color:var(--muted); margin-top:38px; letter-spacing:.3px; }}
.rule {{ width:118px; height:6px; background:var(--primary); border-radius:3px; margin-top:44px;
  transform-origin:left center; }}

/* ---------- ฉากข้อความ ---------- */
.text-scene {{ flex-direction:column; justify-content:center; padding:0 150px; }}
.kicker {{ font-size:21px; font-weight:800; letter-spacing:5px; color:var(--primary); }}
.text-scene h2 {{ font-size:70px; font-weight:800; margin-top:16px; letter-spacing:-1.4px; }}
.items {{ margin-top:62px; display:flex; flex-direction:column; gap:34px; max-width:1320px; }}
.item {{ display:flex; gap:26px; align-items:flex-start; }}
.item .dot {{ width:15px; height:15px; border-radius:50%; background:var(--primary); margin-top:16px;
  flex:none; }}
.item .h {{ font-size:38px; font-weight:700; }}
.item .p {{ font-size:26px; color:var(--muted); margin-top:8px; line-height:1.5; }}

/* ---------- การ์ดบทบาท ---------- */
.cards {{ display:flex; gap:26px; margin-top:64px; }}
.card {{ flex:1; background:var(--ink-2); border:1px solid var(--line); border-radius:22px;
  padding:38px 32px; }}
.card .n {{ font-size:34px; font-weight:800; }}
.card .d {{ font-size:22px; color:var(--muted); margin-top:12px; }}
.card .bar {{ height:5px; width:64px; background:var(--primary); border-radius:3px; margin-bottom:26px;
  transform-origin:left center; }}

/* ---------- ตัวเลขสรุป ---------- */
.stats {{ display:flex; gap:30px; margin-top:64px; }}
.stat {{ flex:1; background:var(--ink-2); border:1px solid var(--line); border-radius:22px;
  padding:40px 34px; }}
.stat .n {{ font-size:64px; font-weight:800; color:var(--primary); line-height:1; }}
.stat .l {{ font-size:22px; color:var(--muted); margin-top:16px; }}
.foot-note {{ font-size:24px; color:var(--muted); margin-top:52px; }}

/* ---------- ฉากภาพหน้าจอ ---------- */
.shot-scene {{ align-items:center; }}
.shot-copy {{ width:640px; padding-left:132px; flex:none; }}
.step {{ display:inline-flex; align-items:center; gap:14px; font-size:20px; font-weight:800;
  letter-spacing:3px; color:var(--primary); }}
.step .line {{ width:52px; height:2px; background:var(--primary); opacity:.55; }}
.shot-copy h2 {{ font-size:62px; font-weight:800; margin-top:20px; line-height:1.12;
  letter-spacing:-1.2px; }}
.shot-copy .cap {{ font-size:27px; color:#C3CAD4; margin-top:26px; line-height:1.62; }}
.badge {{ display:inline-flex; align-items:center; gap:12px; margin-top:38px; padding:14px 22px;
  background:var(--soft); border:1px solid rgba(255,107,44,.36); border-radius:14px;
  font-size:22px; font-weight:700; color:#FFB58C; }}
.badge .tick {{ width:9px; height:9px; border-radius:50%; background:var(--primary); }}

.shot-media {{ flex:1; display:flex; align-items:center; justify-content:center; padding-right:110px; }}
.phone-frame {{ border:11px solid #23272F; border-radius:46px; overflow:hidden; height:830px;
  box-shadow:0 40px 90px rgba(0,0,0,.55); background:#000; }}
.phone-frame img {{ display:block; height:100%; }}
.screen-frame {{ border:9px solid #23272F; border-radius:20px; overflow:hidden; width:1000px;
  box-shadow:0 40px 90px rgba(0,0,0,.55); background:#000; }}
.screen-frame img {{ display:block; width:100%; }}
.browser-frame {{ border-radius:16px; overflow:hidden; width:1030px; background:#23272F;
  box-shadow:0 40px 90px rgba(0,0,0,.55); }}
.browser-bar {{ height:40px; display:flex; align-items:center; gap:9px; padding:0 18px; }}
.browser-bar i {{ width:12px; height:12px; border-radius:50%; background:#454B55; }}
.browser-frame img {{ display:block; width:100%; }}

/* ---------- ฉากปิด ---------- */
.outro {{ flex-direction:column; justify-content:center; align-items:center; text-align:center; }}
.outro h2 {{ font-size:82px; font-weight:800; letter-spacing:-1.6px; }}
.cmd {{ margin-top:44px; display:flex; flex-direction:column; gap:18px; align-items:center; }}
.cmd code {{ font-family:'Noto',monospace; font-size:28px; background:var(--ink-2);
  border:1px solid var(--line); border-radius:14px; padding:20px 34px; color:#E9ECF1; }}
.outro .link {{ font-size:26px; color:var(--primary); margin-top:46px; font-weight:700; }}
.outro .tiny {{ font-size:21px; color:var(--muted); margin-top:18px; }}

/* ---------- แถบความคืบหน้าและโลโก้มุมจอ ---------- */
.progress {{ position:absolute; left:0; bottom:0; height:6px; background:var(--primary);
  width:100%; transform-origin:left center; z-index:5; }}
.corner {{ position:absolute; right:56px; top:46px; font-size:21px; font-weight:800;
  letter-spacing:1px; color:rgba(255,255,255,.42); z-index:5; }}
"""


def anim(name, dur, delay, easing="cubic-bezier(.22,.61,.36,1)", fill="both"):
    return f"animation:{name} {dur}s {easing} {delay}s {fill};"


def scene_open(start, duration, extra_class="", extra_style=""):
    """ฉากจะเฟดเข้าตอนเริ่ม และเฟดออกก่อนจบพอดี"""
    # sceneHide ต้องใช้ forwards ไม่ใช่ both
    # ถ้าใช้ both ฉากที่ยังไม่ถึงคิวจะถูกบังคับ opacity:1 ตั้งแต่วินาทีแรก (คีย์เฟรม 0% ของ sceneHide)
    # ทำให้แสงพื้นหลังของทุกฉากข้างหน้าซ้อนทับฉากปัจจุบัน
    show = (f"animation:sceneShow {FADE}s ease {start}s both,"
            f" sceneHide {FADE}s ease {start + duration - FADE}s forwards;")
    return f'<section class="scene {extra_class}" style="{show}{extra_style}">'


def title_scene(s, t):
    d = s["duration"]
    return f"""{scene_open(t, d, 'title-scene')}
  <div class="bg-glow"></div>
  <div class="mark" style="{anim('popIn', .8, t + .25)}">🍽</div>
  <h1 style="{anim('riseIn', .9, t + .45)}">{esc(s['title'])}</h1>
  <div class="sub" style="{anim('riseIn', .9, t + .70)}">{esc(s['subtitle'])}</div>
  <div class="rule" style="{anim('barGrow', .7, t + .95)}"></div>
  <div class="note" style="{anim('riseIn', .9, t + 1.15)}">{esc(s['note'])}</div>
</section>"""


def bullets_scene(s, t):
    items = "".join(
        f"""<div class="item" style="{anim('slideIn', .7, t + .6 + i * .45)}">
              <div class="dot"></div>
              <div><div class="h">{esc(h)}</div><div class="p">{esc(p)}</div></div>
            </div>"""
        for i, (h, p) in enumerate(s["items"])
    )
    return f"""{scene_open(t, s['duration'], 'text-scene')}
  <div class="bg-glow"></div>
  <div class="kicker" style="{anim('riseIn', .7, t + .2)}">{esc(s['kicker'])}</div>
  <h2 style="{anim('riseIn', .8, t + .35)}">{esc(s['title'])}</h2>
  <div class="items">{items}</div>
</section>"""


def roles_scene(s, t):
    cards = "".join(
        f"""<div class="card" style="{anim('riseIn', .7, t + .55 + i * .18)}">
              <div class="bar" style="{anim('barGrow', .5, t + .75 + i * .18)}"></div>
              <div class="n">{esc(n)}</div><div class="d">{esc(d)}</div>
            </div>"""
        for i, (n, d) in enumerate(s["items"])
    )
    return f"""{scene_open(t, s['duration'], 'text-scene')}
  <div class="bg-glow"></div>
  <div class="kicker" style="{anim('riseIn', .7, t + .2)}">{esc(s['kicker'])}</div>
  <h2 style="{anim('riseIn', .8, t + .35)}">{esc(s['title'])}</h2>
  <div class="cards">{cards}</div>
</section>"""


def stats_scene(s, t):
    cards = "".join(
        f"""<div class="stat" style="{anim('riseIn', .7, t + .55 + i * .16)}">
              <div class="n">{esc(n)}</div><div class="l">{esc(l)}</div>
            </div>"""
        for i, (n, l) in enumerate(s["items"])
    )
    return f"""{scene_open(t, s['duration'], 'text-scene')}
  <div class="bg-glow"></div>
  <div class="kicker" style="{anim('riseIn', .7, t + .2)}">{esc(s['kicker'])}</div>
  <h2 style="{anim('riseIn', .8, t + .35)}">{esc(s['title'])}</h2>
  <div class="stats">{cards}</div>
  <div class="foot-note" style="{anim('riseIn', .8, t + 1.5)}">{esc(s['note'])}</div>
</section>"""


def shot_scene(s, t):
    d = s["duration"]
    if s["frame"] == "phone":
        media = f'<div class="phone-frame"><img src="{IMG_DIR}/{s["image"]}"></div>'
    elif s["frame"] == "browser":
        media = (f'<div class="browser-frame"><div class="browser-bar"><i></i><i></i><i></i></div>'
                 f'<img src="{IMG_DIR}/{s["image"]}"></div>')
    else:
        media = f'<div class="screen-frame"><img src="{IMG_DIR}/{s["image"]}"></div>'

    badge = ""
    if s.get("badge"):
        badge = (f'<div class="badge" style="{anim("popIn", .6, t + 1.35)}">'
                 f'<span class="tick"></span>{esc(s["badge"])}</div>')

    return f"""{scene_open(t, d, 'shot-scene')}
  <div class="bg-glow"></div>
  <div class="shot-copy">
    <div class="step" style="{anim('riseIn', .6, t + .30)}">
      <span class="line"></span>{esc(s['step'])}
    </div>
    <h2 style="{anim('riseIn', .8, t + .45)}">{esc(s['title'])}</h2>
    <div class="cap" style="{anim('riseIn', .8, t + .70)}">{esc(s['caption'])}</div>
    {badge}
  </div>
  <div class="shot-media" style="{anim('riseIn', .9, t + .35)}">
    <div style="{anim('kenBurns', d, t, 'linear')}">{media}</div>
  </div>
</section>"""


def outro_scene(s, t):
    lines = "".join(f"<code>{esc(x)}</code>" for x in s["lines"])
    return f"""{scene_open(t, s['duration'], 'outro')}
  <div class="bg-glow"></div>
  <h2 style="{anim('riseIn', .8, t + .3)}">{esc(s['title'])}</h2>
  <div class="cmd" style="{anim('riseIn', .8, t + .6)}">{lines}</div>
  <div class="link" style="{anim('riseIn', .8, t + .95)}">{esc(s['note'])}</div>
  <div class="tiny" style="{anim('riseIn', .8, t + 1.2)}">{esc(OUTRO_NOTE)}</div>
</section>"""


BUILDERS = {
    "title": title_scene,
    "bullets": bullets_scene,
    "roles": roles_scene,
    "stats": stats_scene,
    "shot": shot_scene,
    "outro": outro_scene,
}

OUTRO_NOTE = ""


def build(storyboard):
    global OUTRO_NOTE
    OUTRO_NOTE = storyboard["outro_note"]

    total = sum(s["duration"] for s in storyboard["scenes"])
    parts, t = [], 0.0
    for scene in storyboard["scenes"]:
        parts.append(BUILDERS[scene["type"]](scene, round(t, 2)))
        t += scene["duration"]

    progress = f'<div class="progress" style="animation:barGrow {total}s linear 0s both;"></div>'
    corner = f'<div class="corner">{esc(storyboard["brand"])}</div>'

    return (
        "<!doctype html><html><head><meta charset='utf-8'>"
        f"<style>{CSS_HEAD}</style></head><body>"
        f'<div class="stage">{corner}{"".join(parts)}{progress}</div>'
        "</body></html>"
    ), total


if __name__ == "__main__":
    lang = sys.argv[1] if len(sys.argv) > 1 else "th"
    out = sys.argv[2] if len(sys.argv) > 2 else f"presentation-{lang}.html"
    sb = STORYBOARD_TH if lang == "th" else STORYBOARD_EN
    markup, total = build(sb)
    with open(out, "w", encoding="utf-8") as f:
        f.write(markup)
    print(f"{out}  ({total:.1f}s)")
