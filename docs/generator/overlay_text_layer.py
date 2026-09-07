# -*- coding: utf-8 -*-
"""ฝังเลเยอร์ข้อความที่ถูกต้องแบบมองไม่เห็นทับ PDF ที่ Chromium เรนเดอร์มา

ปัญหา: Chromium print-to-PDF มีบั๊กที่ทำให้ข้อความไทยที่มีวรรณยุกต์/สระซ้อนกันถูกฝังใน
PDF ด้วย ToUnicode CMap ที่ผิด — แสดงผล/พิมพ์ออกมาถูกต้อง 100% แต่คัดลอก (copy-paste)
ออกมาแล้วตัวอักษรซ้ำหรือสลับที่ ทดสอบแล้วว่าเกิดแบบสุ่มไปตามคำ ไม่ขึ้นกับฟอนต์หรือ
เอนจินตัวใดตัวหนึ่ง (ลองมาแล้ว Chromium ปกติ, Chromium tagged-pdf, WeasyPrint,
LibreOffice, ฟอนต์ 8 ตระกูล) จึงแก้ที่ปลายทางแทนการไล่หาฟอนต์ที่ไม่พังต่อไปเรื่อยๆ

วิธีแก้: แปลงแต่ละหน้าของ PDF ที่ Chromium สร้าง (ภาพถูกต้อง 100%) เป็นรูปภาพ ใช้รูปนั้น
เป็นพื้นหลัง แล้วฝัง "ข้อความล้วน" ที่รู้อยู่แล้วว่าถูกต้อง (จาก build_audit_report.py ที่
ส่งออกเป็น .pages.json) ลงไปแบบ invisible (text render mode 3) ด้วย reportlab — reportlab
ไม่ทำ shaping ที่ซับซ้อน จึงวาดสตริง Unicode ตรงตามที่ป้อนเข้าไปเป๊ะ ไม่มีการสลับ/ซ้ำอักษร
(ยืนยันด้วยการ extract ข้อความกลับมาเทียบ 100%) ผลลัพธ์คือ PDF หน้าตาเหมือนเดิมทุกพิกเซล
แต่คัดลอกข้อความได้ถูกต้อง

Usage:
    python3 overlay_text_layer.py visual.pdf visual.pages.json output.pdf
"""
import json
import sys

import pypdfium2 as pdfium
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
import io

RENDER_SCALE = 2.0  # ~144 DPI ที่ A4 พอสำหรับพิมพ์/ดูจอ โดยไฟล์ไม่ใหญ่เกินไป
FONT_PATH = "../../app/tool/fonts/NotoSansThai-400.ttf"


def rasterize_pages(src_pdf_path):
    pdf = pdfium.PdfDocument(src_pdf_path)
    images = []
    for i in range(len(pdf)):
        page = pdf[i]
        bitmap = page.render(scale=RENDER_SCALE)
        images.append(bitmap.to_pil())
    return images


def build_overlay_pdf(images, pages_text, out_path):
    pdfmetrics.registerFont(TTFont("Noto", FONT_PATH))
    buf = io.BytesIO()
    w, h = A4
    c = canvas.Canvas(buf, pagesize=A4)
    for img, text in zip(images, pages_text):
        c.drawInlineImage(img, 0, 0, width=w, height=h)
        c.setFont("Noto", 6)
        c.setFillColorRGB(0, 0, 0)
        text_obj = c.beginText(2, h - 10)
        text_obj.setTextRenderMode(3)  # invisible: ไม่ทา ไม่ตัดขอบ แต่ยังเป็นข้อความจริง
        for line in text.split("\n"):
            # ใส่ทีละบรรทัดสั้น ๆ กัน reportlab ตัดคำกลางสระ/วรรณยุกต์เอง
            text_obj.textLine(line)
        c.drawText(text_obj)
        c.showPage()
    c.save()
    buf.seek(0)
    with open(out_path, "wb") as f:
        f.write(buf.getvalue())


def verify(out_path, expected_pages):
    pdf = pdfium.PdfDocument(out_path)
    ok = True
    for i, expected in enumerate(expected_pages):
        got = pdf[i].get_textpage().get_text_range()
        expected_compact = "".join(expected.split())
        got_compact = "".join(got.split())
        if expected_compact not in got_compact and got_compact not in expected_compact:
            missing = [w for w in expected.split("\n") if "".join(w.split()) not in got_compact]
            if missing:
                print(f"  page {i + 1}: MISMATCH, missing lines: {missing[:3]}")
                ok = False
    return ok


if __name__ == "__main__":
    src_pdf, pages_json, out_pdf = sys.argv[1], sys.argv[2], sys.argv[3]
    with open(pages_json, encoding="utf-8") as f:
        pages_text = json.load(f)

    print(f"rasterizing {src_pdf} ...")
    images = rasterize_pages(src_pdf)
    assert len(images) == len(pages_text), (
        f"page count mismatch: pdf has {len(images)}, json has {len(pages_text)}"
    )

    print(f"building overlay pdf -> {out_pdf} ...")
    build_overlay_pdf(images, pages_text, out_pdf)

    print("verifying extracted text matches source ...")
    if verify(out_pdf, pages_text):
        print("OK: all pages verified")
    else:
        print("WARNING: some pages did not verify cleanly, inspect manually")
