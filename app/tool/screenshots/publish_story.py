#!/usr/bin/env python3
# Copyright 2026 Suruch Chakrapeesirisuk
# SPDX-License-Identifier: Apache-2.0
#
# แปลงภาพ golden ของ story_test.dart เป็น WebP ขนาดพอดีเว็บ ลง docs/landing/img/story/
# (ทั้งหน้า Landing และ README ใช้ไฟล์ชุดนี้ชุดเดียว — docs/DECISIONS.md #70)
#
#   cd app && flutter test --update-goldens --dart-define=DEMO_MODE=true tool/screenshots/story_test.dart
#   python3 tool/screenshots/publish_story.py
#
# ต้องมี Pillow ที่รองรับ WebP (pip install pillow)
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
SOURCE = HERE / 'images' / 'story'
TARGET = HERE.parents[2] / 'docs' / 'landing' / 'img' / 'story'

# ความกว้างสูงสุดที่เก็บไว้ — มือถือวางในหน้าเว็บกว้างราว 300–390px จึงเหลือ 2 เท่าไว้ให้จอ retina
# ส่วนแท็บเล็ต/จอคอมวางเต็มคอลัมน์ ~800px
MAX_WIDTH = {'portrait': 780, 'landscape': 1600}


def main() -> None:
    TARGET.mkdir(parents=True, exist_ok=True)
    sources = sorted(SOURCE.glob('*.png'))
    if not sources:
        raise SystemExit(f'ไม่พบภาพใน {SOURCE} — รัน story_test.dart ก่อน')
    total = 0
    for png in sources:
        image = Image.open(png).convert('RGB')
        width, height = image.size
        limit = MAX_WIDTH['portrait' if height > width else 'landscape']
        if width > limit:
            image = image.resize((limit, round(height * limit / width)), Image.LANCZOS)
        out = TARGET / f'{png.stem}.webp'
        image.save(out, 'WEBP', quality=82, method=6)
        total += out.stat().st_size
        print(f'{out.relative_to(TARGET.parents[3])}  {image.size[0]}x{image.size[1]}  {out.stat().st_size // 1024} KB')
    print(f'{len(sources)} ภาพ รวม {total // 1024} KB')


if __name__ == '__main__':
    main()
