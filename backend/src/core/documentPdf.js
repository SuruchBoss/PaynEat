// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import path from 'node:path';
import PDFDocument from 'pdfkit';
import { env } from '../config/env.js';
import { thaiDateTime } from './thaiFormat.js';

/**
 * สร้าง PDF เอกสารธุรกิจขนาด A4 (ใบวางบิล ใบเสร็จรับชำระ ใบลดหนี้ ใบแจ้งดอกเบี้ย) จาก "spec" ที่บอกแค่
 * เนื้อหา — หน้าตา/การตัดหน้า/หัวท้ายกระดาษอยู่ที่นี่ที่เดียว (ดู docs/DECISIONS.md #57)
 *
 * ภาษาไทยไม่มีช่องว่างระหว่างคำ ตัวตัดบรรทัดของ pdfkit (UAX #14) จึงหาจุดตัดไม่เจอและจะหั่นกลางคำ/
 * แยกสระออกจากพยัญชนะ ไฟล์นี้จึงตัดบรรทัดเองด้วย Intl.Segmenter ('th' แยกคำจากพจนานุกรมของ ICU)
 * แล้ววาดทีละบรรทัดโดยไม่ส่ง width ให้ pdfkit เลย — pdfkit จะไม่เพิ่มหน้าเองตรงไหนที่เราไม่ได้สั่ง
 *
 * ฟอนต์ Noto Sans Thai (OFL) ตัวเดียวกับที่แอปใช้ มีตัวอักษรละติน/ตัวเลข/฿ ครบในไฟล์เดียว
 */

const FONT_DIR = path.join(env.rootDir, 'assets/fonts');
const FONTS = {
  regular: path.join(FONT_DIR, 'NotoSansThai-400.ttf'),
  bold: path.join(FONT_DIR, 'NotoSansThai-700.ttf'),
};

const COLOR = {
  ink: '#1F2933',
  muted: '#6B7280',
  border: '#D1D5DB',
  fill: '#F3F4F6',
  brand: '#C2410C',
  danger: '#B91C1C',
};

const MARGIN = 42;
const FOOTER_SPACE = 28;
const LINE = 1.45;

const wordSegmenter = new Intl.Segmenter('th', { granularity: 'word' });
const graphemeSegmenter = new Intl.Segmenter('th', { granularity: 'grapheme' });

const style = (doc, { font = 'regular', size = 10, color = COLOR.ink } = {}) =>
  doc.font(font).fontSize(size).fillColor(color);

/** หั่นคำที่ยาวเกินบรรทัดตามกลุ่มตัวอักษร (grapheme) — สระ/วรรณยุกต์ไม่หลุดจากพยัญชนะ */
const splitLongWord = (doc, word, width) => {
  const lines = [];
  let current = '';
  for (const { segment } of graphemeSegmenter.segment(word)) {
    if (current && doc.widthOfString(current + segment) > width) {
      lines.push(current);
      current = segment;
    } else {
      current += segment;
    }
  }
  return { lines, rest: current };
};

/** ตัดข้อความเป็นบรรทัดที่กว้างไม่เกิน width ด้วยฟอนต์/ขนาดที่ตั้งไว้ปัจจุบัน */
export const wrapText = (doc, text, width) => {
  const result = [];
  for (const paragraph of String(text ?? '').split('\n')) {
    let line = '';
    for (const { segment } of wordSegmenter.segment(paragraph)) {
      const candidate = line + segment;
      if (doc.widthOfString(candidate) <= width) {
        line = candidate;
        continue;
      }
      if (line.trim()) result.push(line.trimEnd());
      const word = segment.trimStart();
      if (doc.widthOfString(word) > width) {
        const { lines, rest } = splitLongWord(doc, word, width);
        result.push(...lines);
        line = rest;
      } else {
        line = word;
      }
    }
    result.push(line.trimEnd());
  }
  return result;
};

/** วาดข้อความบรรทัดเดียวที่ (x, y) จัดชิดซ้าย/ขวา/กลางภายใน width เอง — ไม่ให้ pdfkit ตัดบรรทัด */
const put = (doc, text, x, y, { width, align = 'left', ...textStyle } = {}) => {
  style(doc, textStyle);
  const value = String(text ?? '');
  let left = x;
  if (width && align !== 'left') {
    const free = width - doc.widthOfString(value);
    left = align === 'right' ? x + free : x + free / 2;
  }
  doc.text(value, left, y, { lineBreak: false });
};

/** วาดข้อความหลายบรรทัด คืน y ถัดจากบรรทัดสุดท้าย */
const block = (doc, text, x, y, { width, align = 'left', ...textStyle } = {}) => {
  style(doc, textStyle);
  const size = textStyle.size ?? 10;
  let cursor = y;
  for (const line of wrapText(doc, text, width)) {
    put(doc, line, x, cursor, { width, align, ...textStyle });
    cursor += size * LINE;
  }
  return cursor;
};

const blockHeight = (doc, text, width, textStyle = {}) => {
  style(doc, textStyle);
  return wrapText(doc, text, width).length * (textStyle.size ?? 10) * LINE;
};

const pageBottom = (doc) => doc.page.height - MARGIN - FOOTER_SPACE;
const contentWidth = (doc) => doc.page.width - MARGIN * 2;

const ensureSpace = (doc, y, needed, onNewPage) => {
  if (y + needed <= pageBottom(doc)) return y;
  doc.addPage();
  return onNewPage ? onNewPage(MARGIN) : MARGIN;
};

// ------------------------------------------------------------------------------ ส่วนหัว -----

const drawHeader = (doc, spec) => {
  const width = contentWidth(doc);
  const rightWidth = 210;
  const leftWidth = width - rightWidth - 16;
  const store = spec.store ?? {};

  let left = block(doc, store.name ?? '', MARGIN, MARGIN, {
    width: leftWidth,
    font: 'bold',
    size: 15,
  });
  const storeLines = [
    store.address,
    [
      store.taxId ? `เลขประจำตัวผู้เสียภาษี ${store.taxId}` : null,
      store.branch ? `สาขา ${store.branch}` : null,
    ]
      .filter(Boolean)
      .join('  '),
  ].filter(Boolean);
  for (const line of storeLines) {
    left = block(doc, line, MARGIN, left, { width: leftWidth, size: 9, color: COLOR.muted });
  }

  const rightX = MARGIN + width - rightWidth;
  put(doc, spec.title, rightX, MARGIN - 2, {
    width: rightWidth,
    align: 'right',
    font: 'bold',
    size: 19,
    color: COLOR.brand,
  });
  let right = MARGIN + 30;
  if (spec.titleEn) {
    put(doc, spec.titleEn, rightX, right, {
      width: rightWidth,
      align: 'right',
      size: 8.5,
      color: COLOR.muted,
    });
    right += 14;
  }
  put(doc, `เลขที่ ${spec.number}`, rightX, right, {
    width: rightWidth,
    align: 'right',
    font: 'bold',
    size: 11,
  });
  right += 18;

  const y = Math.max(left, right) + 8;
  doc
    .moveTo(MARGIN, y)
    .lineTo(MARGIN + width, y)
    .lineWidth(1.2)
    .strokeColor(COLOR.brand)
    .stroke();
  return y + 12;
};

const drawVoidBanner = (doc, spec, y) => {
  if (!spec.voided) return y;
  const width = contentWidth(doc);
  const text = `เอกสารนี้ถูกยกเลิกแล้ว${spec.voided.at ? ` เมื่อ ${thaiDateTime(spec.voided.at)}` : ''}${
    spec.voided.reason ? ` — เหตุผล: ${spec.voided.reason}` : ''
  }`;
  const height = blockHeight(doc, text, width - 20, { font: 'bold', size: 10 }) + 12;
  doc.rect(MARGIN, y, width, height).fillColor('#FEE2E2').fill();
  block(doc, text, MARGIN + 10, y + 6, {
    width: width - 20,
    font: 'bold',
    size: 10,
    color: COLOR.danger,
  });
  return y + height + 12;
};

/** กล่องลูกค้า (ซ้าย) + ข้อมูลเอกสาร เช่น วันที่/วันนัดชำระ (ขวา) */
const drawParties = (doc, spec, y) => {
  const width = contentWidth(doc);
  const metaWidth = 200;
  const boxWidth = width - metaWidth - 16;
  const customer = spec.customer ?? {};
  const padding = 10;
  const inner = boxWidth - padding * 2;

  const lines = [
    customer.address,
    customer.taxId ? `เลขประจำตัวผู้เสียภาษี ${customer.taxId}` : null,
    customer.phone ? `โทร ${customer.phone}` : null,
  ].filter(Boolean);
  const nameHeight = blockHeight(doc, customer.name ?? '-', inner, { font: 'bold', size: 11 });
  const linesHeight = lines.reduce(
    (acc, line) => acc + blockHeight(doc, line, inner, { size: 9.5 }),
    0,
  );
  const boxHeight = padding * 2 + 14 + nameHeight + linesHeight;

  doc.roundedRect(MARGIN, y, boxWidth, boxHeight, 6).lineWidth(0.8).strokeColor(COLOR.border);
  doc.stroke();
  put(doc, spec.customerLabel ?? 'ลูกค้า', MARGIN + padding, y + padding - 2, {
    size: 8.5,
    color: COLOR.muted,
  });
  let cursor = block(doc, customer.name ?? '-', MARGIN + padding, y + padding + 12, {
    width: inner,
    font: 'bold',
    size: 11,
  });
  for (const line of lines) {
    cursor = block(doc, line, MARGIN + padding, cursor, { width: inner, size: 9.5 });
  }

  const metaX = MARGIN + width - metaWidth;
  let metaY = y + 2;
  for (const [label, value] of spec.meta ?? []) {
    put(doc, label, metaX, metaY, { size: 9.5, color: COLOR.muted });
    put(doc, value, metaX, metaY, { width: metaWidth, align: 'right', font: 'bold', size: 9.5 });
    metaY += 17;
  }
  return Math.max(y + boxHeight, metaY) + 14;
};

// ------------------------------------------------------------------------------- ตาราง -----

const columnLayout = (doc, columns) => {
  const width = contentWidth(doc);
  const fixed = columns.reduce((acc, column) => acc + (column.width ?? 0), 0);
  const flexible = columns.filter((column) => !column.width).length || 1;
  let x = MARGIN;
  return columns.map((column) => {
    const w = column.width ?? (width - fixed) / flexible;
    const layout = { ...column, x, w };
    x += w;
    return layout;
  });
};

const CELL_PAD = 6;

const drawTableHeader = (doc, layout, y) => {
  const height = 22;
  doc.rect(MARGIN, y, contentWidth(doc), height).fillColor(COLOR.fill).fill();
  for (const column of layout) {
    put(doc, column.label, column.x + CELL_PAD, y + 5, {
      width: column.w - CELL_PAD * 2,
      align: column.align ?? 'left',
      font: 'bold',
      size: 9,
    });
  }
  return y + height;
};

const drawTable = (doc, spec, y) => {
  const layout = columnLayout(doc, spec.columns);
  let cursor = drawTableHeader(doc, layout, y);
  const size = 9.5;

  if (!spec.rows.length) {
    put(doc, spec.emptyText ?? '-', MARGIN, cursor + 8, {
      width: contentWidth(doc),
      align: 'center',
      size,
      color: COLOR.muted,
    });
    return cursor + 34;
  }

  for (const row of spec.rows) {
    style(doc, { size });
    const cells = layout.map((column, index) =>
      wrapText(doc, row[index] ?? '', column.w - CELL_PAD * 2),
    );
    const height = Math.max(...cells.map((lines) => lines.length)) * size * LINE + 10;
    cursor = ensureSpace(doc, cursor, height, (top) => drawTableHeader(doc, layout, top));
    layout.forEach((column, index) => {
      cells[index].forEach((line, lineIndex) => {
        put(doc, line, column.x + CELL_PAD, cursor + 5 + lineIndex * size * LINE, {
          width: column.w - CELL_PAD * 2,
          align: column.align ?? 'left',
          size,
        });
      });
    });
    cursor += height;
    doc
      .moveTo(MARGIN, cursor)
      .lineTo(MARGIN + contentWidth(doc), cursor)
      .lineWidth(0.5)
      .strokeColor(COLOR.border)
      .stroke();
  }
  return cursor + 12;
};

// ---------------------------------------------------------------------- ยอดรวม/หมายเหตุ -----

const drawTotals = (doc, spec, y) => {
  const totals = spec.totals ?? [];
  if (!totals.length && !spec.amountInWords) return y;
  const width = contentWidth(doc);
  const totalsWidth = 230;
  const rowHeight = 19;
  const needed = Math.max(totals.length * rowHeight, 40) + 8;
  let cursor = ensureSpace(doc, y, needed);
  const top = cursor;

  const totalsX = MARGIN + width - totalsWidth;
  for (const { label, value, strong } of totals) {
    if (strong) {
      doc
        .moveTo(totalsX, cursor - 2)
        .lineTo(MARGIN + width, cursor - 2)
        .lineWidth(0.8)
        .strokeColor(COLOR.ink)
        .stroke();
    }
    const font = strong ? 'bold' : 'regular';
    const size = strong ? 11 : 9.5;
    put(doc, label, totalsX, cursor + 2, { font, size, color: strong ? COLOR.ink : COLOR.muted });
    put(doc, value, totalsX, cursor + 2, {
      width: totalsWidth,
      align: 'right',
      font,
      size,
      color: strong ? COLOR.brand : COLOR.ink,
    });
    cursor += rowHeight;
  }

  if (spec.amountInWords) {
    const boxWidth = width - totalsWidth - 20;
    const text = `(${spec.amountInWords})`;
    const height = blockHeight(doc, text, boxWidth - 16, { font: 'bold', size: 9.5 }) + 12;
    doc.rect(MARGIN, top, boxWidth, height).fillColor(COLOR.fill).fill();
    block(doc, text, MARGIN + 8, top + 6, { width: boxWidth - 16, font: 'bold', size: 9.5 });
    cursor = Math.max(cursor, top + height);
  }
  return cursor + 14;
};

const drawNotes = (doc, spec, y) => {
  const notes = (spec.notes ?? []).filter(Boolean);
  if (!notes.length) return y;
  const width = contentWidth(doc);
  let cursor = ensureSpace(doc, y, 40);
  put(doc, 'หมายเหตุ', MARGIN, cursor, { font: 'bold', size: 9.5 });
  cursor += 16;
  for (const note of notes) {
    const height = blockHeight(doc, note, width, { size: 9, color: COLOR.muted });
    cursor = ensureSpace(doc, cursor, height);
    cursor = block(doc, note, MARGIN, cursor, { width, size: 9, color: COLOR.muted });
  }
  return cursor + 10;
};

const drawSignatures = (doc, spec, y) => {
  const signatures = spec.signatures ?? [];
  if (!signatures.length) return y;
  const width = contentWidth(doc);
  const height = 86;
  const cursor = ensureSpace(doc, y + 10, height);
  const slot = width / signatures.length;
  signatures.forEach((label, index) => {
    const x = MARGIN + slot * index + 20;
    const w = slot - 40;
    doc
      .moveTo(x, cursor + 38)
      .lineTo(x + w, cursor + 38)
      .lineWidth(0.6)
      .strokeColor(COLOR.muted)
      .dash(2, { space: 2 })
      .stroke()
      .undash();
    put(doc, label, x, cursor + 44, { width: w, align: 'center', font: 'bold', size: 9.5 });
    put(doc, 'วันที่ ......../......../........', x, cursor + 60, {
      width: w,
      align: 'center',
      size: 8.5,
      color: COLOR.muted,
    });
  });
  return cursor + height;
};

// ------------------------------------------------------------------------ ทุกหน้า -----

const decoratePages = (doc, spec, generatedAt) => {
  const range = doc.bufferedPageRange();
  for (let index = range.start; index < range.start + range.count; index += 1) {
    doc.switchToPage(index);
    // ท้ายกระดาษอยู่นอกขอบล่าง — ปิดขอบชั่วคราวไม่ให้ pdfkit คิดว่าล้นแล้วเพิ่มหน้าใหม่
    const bottomMargin = doc.page.margins.bottom;
    doc.page.margins.bottom = 0;
    const y = doc.page.height - MARGIN + 6;
    put(doc, `${spec.number} · ออกจากระบบ PaynEat เมื่อ ${thaiDateTime(generatedAt)}`, MARGIN, y, {
      size: 7.5,
      color: COLOR.muted,
    });
    put(doc, `หน้า ${index - range.start + 1}/${range.count}`, MARGIN, y, {
      width: contentWidth(doc),
      align: 'right',
      size: 7.5,
      color: COLOR.muted,
    });
    if (spec.voided) {
      doc.save();
      doc.rotate(-30, { origin: [doc.page.width / 2, doc.page.height / 2] });
      doc.opacity(0.14);
      put(doc, 'ยกเลิก · VOID', 0, doc.page.height / 2 - 40, {
        width: doc.page.width,
        align: 'center',
        font: 'bold',
        size: 64,
        color: COLOR.danger,
      });
      doc.restore();
    }
    doc.page.margins.bottom = bottomMargin;
  }
};

/**
 * spec: { title, titleEn, number, store, customer, customerLabel, meta: [[label, value]],
 *         columns: [{ label, width?, align? }], rows: [[string]], emptyText,
 *         totals: [{ label, value, strong? }], amountInWords, notes: [string],
 *         signatures: [label], voided: { at, reason } | null }
 * คืน Buffer ของไฟล์ PDF
 */
export const renderDocumentPdf = (spec, { generatedAt = new Date() } = {}) =>
  new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      size: 'A4',
      margin: MARGIN,
      bufferPages: true,
      info: {
        Title: `${spec.title} ${spec.number}`,
        Author: spec.store?.name ?? 'PaynEat',
        Creator: 'PaynEat',
      },
    });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    try {
      doc.registerFont('regular', FONTS.regular);
      doc.registerFont('bold', FONTS.bold);

      let y = drawHeader(doc, spec);
      y = drawVoidBanner(doc, spec, y);
      y = drawParties(doc, spec, y);
      y = drawTable(doc, spec, y);
      y = drawTotals(doc, spec, y);
      y = drawNotes(doc, spec, y);
      drawSignatures(doc, spec, y);
      decoratePages(doc, spec, generatedAt);
      doc.end();
    } catch (error) {
      reject(error);
    }
  });

export default renderDocumentPdf;
