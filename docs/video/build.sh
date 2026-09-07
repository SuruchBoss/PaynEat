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
DURATION=101.5   # ความยาว timeline 100.5s + หัวท้ายเผื่อไว้
FFMPEG="${FFMPEG:-ffmpeg}"

mkdir -p "$WORK"
cp "$HERE"/build_video_html.py "$HERE"/storyboard.py "$HERE"/record.mjs "$WORK/"
mkdir -p "$WORK/fonts" "$WORK/images"
cp "$ROOT"/app/tool/fonts/*.ttf "$WORK/fonts/"
cp "$ROOT"/app/tool/screenshots/images/*.png "$WORK/images/"

for LANG in "${@:-th en}"; do
  UP=$(echo "$LANG" | tr '[:lower:]' '[:upper:]')
  ( cd "$WORK" && python3 build_video_html.py "$LANG" "presentation-$LANG.html" )

  rm -rf "$WORK/rec-$LANG"
  # รันจาก docs/video เพื่อให้ resolve node_modules/playwright เจอ
  ( cd "$HERE" && node record.mjs "$WORK/presentation-$LANG.html" "$WORK/rec-$LANG" "$DURATION" )

  # ตัดช่วงหัวที่ยังโหลดหน้าอยู่ออก เหลือจอดำสั้น ๆ ไว้เปิดเรื่อง
  LEAD=$(python3 -c "import json;print(max(0, json.load(open('$WORK/rec-$LANG/lead.json'))['leadSeconds'] - 0.35))")
  SRC=$(ls "$WORK/rec-$LANG"/*.webm | head -1)

  "$FFMPEG" -y -hide_banner -loglevel error -ss "$LEAD" -i "$SRC" -t 101.2 \
    -c:v libx264 -preset slow -crf 21 -pix_fmt yuv420p -movflags +faststart -r 25 \
    "$HERE/PaynEat-POS-Demo-$UP.mp4"
  echo "wrote docs/video/PaynEat-POS-Demo-$UP.mp4"
done
