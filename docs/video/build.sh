#!/usr/bin/env bash
# สร้างวิดีโอ demo presentation จากภาพหน้าจอจริงของแอป
#
#   ./docs/video/build.sh          # สร้างทั้ง TH และ EN
#   ./docs/video/build.sh th       # เฉพาะภาษาไทย
#
# ต้องมี: python3, ffmpeg และ playwright  (cd docs/video && npm install)
# ภาพหน้าจอสร้างจาก  cd app && flutter test --update-goldens tool/screenshots/capture_test.dart
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WORK="${WORK:-$HERE/.build}"
FFMPEG="${FFMPEG:-ffmpeg}"

mkdir -p "$WORK"
cp "$HERE"/build_video_html.py "$HERE"/storyboard.py "$HERE"/record.mjs "$WORK/"
mkdir -p "$WORK/fonts" "$WORK/images"
# ฟอนต์อยู่ที่ assets/fonts (ที่เดียวกับที่ screenshot_harness.dart โหลด) — เดิมสคริปต์นี้ชี้ไป
# app/tool/fonts ซึ่งมีแต่ README เหลืออยู่ ทำให้ build พังทันทีบนเครื่องที่ clone ใหม่
cp "$ROOT"/app/assets/fonts/*.ttf "$WORK/fonts/"
cp "$ROOT"/app/tool/screenshots/images/*.png "$WORK/images/"

# ความยาว timeline คำนวณจาก storyboard.py ตรง ๆ ห้าม hardcode เลขไว้ในสคริปต์นี้
# เพราะทุกครั้งที่มีคนเพิ่ม/ลดฉากใน storyboard.py แล้วลืมแก้เลขตรงนี้ วิดีโอจะโดนตัดจบก่อนถึงฉากปิด
TOTAL=$(cd "$WORK" && python3 -c "from storyboard import STORYBOARD_TH; print(sum(s['duration'] for s in STORYBOARD_TH['scenes']))")

# ฉากที่มี backdrop-filter:blur() หนักทุกฉากทำให้ Chromium ตอนอัดวิดีโอ (headless, ไม่มี GPU)
# วาดตามจังหวะ CSS animation จริงไม่ทัน วัดจริงพบว่าช้ากว่า timeline ได้ถึง ~20%
# ถ้าอัดแค่ความยาว timeline พอดี ฉากท้าย (สถิติ/ปิดท้าย) จะโดนตัดหายไปเงียบ ๆ
# จึงอัดยาวเผื่อไว้มาก ๆ แล้วค่อยหาจุดจบจริงด้วย freezedetect (ฉากสุดท้ายค้างนิ่งเมื่อเล่นจบ)
# แทนที่จะเดาตัวเลขคงที่ ซึ่งจะพังอีกถ้าเครื่องที่รันช้า/เร็วกว่านี้ หรือ storyboard ยาวขึ้นอีก
RECORD_SECONDS=$(python3 -c "print($TOTAL + 60)")

for LANG in ${@:-th en}; do
  UP=$(echo "$LANG" | tr '[:lower:]' '[:upper:]')
  ( cd "$WORK" && python3 build_video_html.py "$LANG" "presentation-$LANG.html" )

  rm -rf "$WORK/rec-$LANG"
  # รันจาก docs/video เพื่อให้ resolve node_modules/playwright เจอ
  ( cd "$HERE" && node record.mjs "$WORK/presentation-$LANG.html" "$WORK/rec-$LANG" "$RECORD_SECONDS" )

  # ตัดช่วงหัวที่ยังโหลดหน้าอยู่ออก เหลือจอดำสั้น ๆ ไว้เปิดเรื่อง
  LEAD=$(python3 -c "import json;print(max(0, json.load(open('$WORK/rec-$LANG/lead.json'))['leadSeconds'] - 0.35))")
  SRC=$(ls "$WORK/rec-$LANG"/*.webm | head -1)

  # หาจุดที่ภาพนิ่งค้างยาว ๆ ครั้งสุดท้าย (freeze_start ที่ไม่มี freeze_end คู่กัน แปลว่านิ่งไปจนจบไฟล์)
  # นั่นคือจุดที่ฉากปิดเล่นจบจริง ๆ (progress bar ขึ้นเต็ม + ข้อความโผล่ครบ ไม่มีอะไรขยับอีก)
  # freezedetect ตัดช่วงนิ่งท้ายวิดีโอเป็นหลายท่อนได้ (เฟรมเดียวต่างกันนิดเดียวก็ตัดแล้ว) การหยิบ
  # freeze_start ตัวสุดท้ายตรง ๆ จึงได้จุดกลางของช่วงนิ่ง ไม่ใช่จุดที่เนื้อหาจบ — ภาษาอังกฤษเคยได้
  # วิดีโอ 2:50 ทั้งที่ timeline ยาว 2:00 (ท้ายคลิปเป็นภาพนิ่ง 50 วินาที) จึงต้องรวมช่วงนิ่งที่ต่อกัน
  # ให้เป็นท่อนเดียวก่อน แล้วค่อยเอาจุดเริ่มของท่อนสุดท้าย
  FREEZE_START=$("$FFMPEG" -v info -i "$SRC" -vf "freezedetect=n=-40dB:d=1.5" -an -f null - 2>&1 \
    | python3 -c "
import re, sys
events = []
for line in sys.stdin:
    for kind, value in re.findall(r'freeze_(start|end): ([0-9.]+)', line):
        events.append((kind, float(value)))
segments = []
for kind, value in events:
    if kind == 'start':
        segments.append([value, None])
    elif segments:
        segments[-1][1] = value
merged = []
for start, end in segments:
    if merged and merged[-1][1] is not None and start - merged[-1][1] <= 0.6:
        merged[-1][1] = end
    else:
        merged.append([start, end])
print(merged[-1][0] if merged else '')
" || true)

  if [ -n "$FREEZE_START" ]; then
    FINAL_DURATION=$(python3 -c "print(max($TOTAL * 0.9, $FREEZE_START - $LEAD + 0.4))")
  else
    # ไม่เจอฉากนิ่งท้ายวิดีโอ (เครื่องช้ากว่าที่เผื่อไว้ หรือ freezedetect ตรวจไม่เจอ)
    # ใช้ความยาวที่อัดมาทั้งหมดแทน ดีกว่าตัดวิดีโอให้สั้นเกินไปแล้วเนื้อหาขาดหาย
    echo "warning: freezedetect ไม่เจอฉากปิดที่นิ่งค้าง ใช้ความยาวที่อัดมาทั้งหมดแทน" >&2
    FINAL_DURATION=$(python3 -c "print($RECORD_SECONDS + $LEAD)")
  fi

  "$FFMPEG" -y -hide_banner -loglevel error -ss "$LEAD" -i "$SRC" -t "$FINAL_DURATION" \
    -c:v libx264 -preset slow -crf 21 -pix_fmt yuv420p -movflags +faststart -r 25 \
    "$HERE/PaynEat-POS-Demo-$UP.mp4"
  echo "wrote docs/video/PaynEat-POS-Demo-$UP.mp4 (${FINAL_DURATION}s)"
done
