// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { api, cleanup } from './helpers/testApp.js';
import { ERROR_MESSAGES, translateMessage } from '../src/i18n/errorMessages.js';

after(cleanup);

// ข้อความ error ของ backend เป็นภาษาไทยในโค้ด แล้วแปลตาม Accept-Language ที่แอปส่งมา (DECISIONS #64)
// เดิมแอปภาษาเกาหลี/อังกฤษเจอข้อความไทยทุกครั้งที่ต่อ backend จริงแล้วมีอะไรถูกปฏิเสธ

const srcDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../src');
const listJs = (dir) =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) return listJs(full);
    return e.name.endsWith('.js') ? [full] : [];
  });

const THAI = /[\u0e00-\u0e7f]/;
const LITERAL = String.raw`(?:'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|\`(?:\\.|[^\`\\])*\`)`;
const CONCAT = String.raw`(${LITERAL}(?:\s*\+\s*${LITERAL})*)`;

/** รวม literal ที่ต่อกันด้วย + ให้เป็นข้อความเดียว และแทน ${...} ด้วย {} */
const joinLiterals = (source) =>
  [...source.matchAll(new RegExp(LITERAL, 'g'))]
    .map((m) => m[0].slice(1, -1))
    .join('')
    .replace(/\$\{(?:[^{}]|\{[^{}]*\})*\}/g, '{}')
    .replace(/\\'/g, "'");

const normalize = (template) => template.replace(/\{[a-zA-Z]+\}/g, '{}').trim();

/** ข้อความทุกอันที่ส่งกลับเป็น error.message / details[].message ได้ */
const messagesInSource = () => {
  const found = new Map();
  const patterns = [
    new RegExp(String.raw`ApiError\.\w+\(\s*${CONCAT}`, 'g'),
    new RegExp(String.raw`new ApiError\(\s*\d+,\s*${CONCAT}`, 'g'),
    new RegExp(String.raw`message(?::|\s*=)\s*${CONCAT}`, 'g'),
  ];
  for (const file of listJs(srcDir)) {
    // ข้อความในแคตตาล็อกเองกับเนื้อหา PDF/อีเมล ไม่ใช่ข้อความ error
    if (file.includes(`${path.sep}i18n${path.sep}`)) continue;
    const text = fs.readFileSync(file, 'utf8');
    const rel = path.relative(srcDir, file);
    for (const pattern of patterns) {
      for (const m of text.matchAll(pattern)) {
        const message = joinLiterals(m[1]);
        if (THAI.test(message)) found.set(message.trim(), rel);
      }
    }
    // เหตุผลที่โค้ดส่วนลดใช้ไม่ได้ ถูกส่งต่อเป็นข้อความ error ตรง ๆ (order.service redeemPromotionCode)
    if (rel.endsWith('promotion.engine.js')) {
      for (const m of text.matchAll(new RegExp(String.raw`return\s+${CONCAT}`, 'g'))) {
        const message = joinLiterals(m[1]);
        if (THAI.test(message)) found.set(message.trim(), rel);
      }
    }
  }
  return found;
};

test('ทุกข้อความ error ภาษาไทยในซอร์สมีคำแปลอังกฤษ/เกาหลีในแคตตาล็อก', () => {
  const catalogue = new Set(ERROR_MESSAGES.map((e) => normalize(e.th)));
  const found = messagesInSource();
  assert.ok(found.size > 120, `สแกนเจอแค่ ${found.size} ข้อความ — ตัวสแกนน่าจะพัง`);

  const missing = [...found].filter(([message]) => !catalogue.has(message));
  assert.deepEqual(
    missing,
    [],
    'ข้อความเหล่านี้ยังไม่มีใน src/i18n/errorMessages.js — แอปภาษาอังกฤษ/เกาหลีจะเห็นเป็นภาษาไทย',
  );
});

test('ทุกรายการในแคตตาล็อกแปลครบ และช่องแทรกค่าตรงกันทุกภาษา', () => {
  const slots = (t) => [...t.matchAll(/\{([a-zA-Z]+)\}/g)].map((m) => m[1]).sort();
  for (const entry of ERROR_MESSAGES) {
    for (const lang of ['en', 'ko']) {
      assert.ok(entry[lang], `ไม่มีคำแปล ${lang}: ${entry.th}`);
      assert.doesNotMatch(entry[lang], THAI, `คำแปล ${lang} ยังมีอักษรไทย: ${entry[lang]}`);
      assert.deepEqual(slots(entry[lang]), slots(entry.th), `ช่องไม่ตรง (${lang}): ${entry.th}`);
    }
  }
});

test('แปลค่าที่แทรกไว้ด้วย — ค่าที่เป็นข้อมูลร้านคงไว้ ชื่อเอกสารแปลตามภาษา', () => {
  assert.equal(
    translateMessage('เมนู "หมูสามชั้น" ขายตามน้ำหนัก ต้องระบุน้ำหนักที่ชั่งได้', 'ko'),
    '"หมูสามชั้น"은(는) 무게로 팝니다 — 잰 무게를 입력해 주세요',
  );
  assert.equal(
    translateMessage('ใบวางบิลนี้ถูกยกเลิกแล้ว ส่งให้ลูกค้าไม่ได้', 'en'),
    "This billing note has been voided and can't be sent",
  );
  assert.equal(
    translateMessage('บาร์โค้ด 8850001 ถูกใช้กับเมนู "น้ำเปล่า" แล้ว', 'en'),
    'Barcode 8850001 is already used by "น้ำเปล่า"',
  );
  // ข้อความที่ไม่รู้จัก/ภาษาไทย/ภาษาที่ไม่รองรับ = คืนตามเดิม
  assert.equal(translateMessage('ข้อความใหม่ที่ยังไม่แปล', 'en'), 'ข้อความใหม่ที่ยังไม่แปล');
  assert.equal(translateMessage('ไม่พบออเดอร์นี้', 'th'), 'ไม่พบออเดอร์นี้');
  assert.equal(translateMessage('ไม่พบออเดอร์นี้', 'ja'), 'ไม่พบออเดอร์นี้');
});

const wrongLogin = (lang) => {
  const req = api().post('/api/v1/auth/login');
  if (lang) req.set('Accept-Language', lang);
  return req.send({ username: 'cashier', password: 'wrong-password' });
};

test('HTTP: ข้อความ error ตาม Accept-Language — ไม่ส่งมาหรือภาษาที่ไม่รองรับได้ไทยเหมือนเดิม', async () => {
  assert.equal((await wrongLogin()).body.error.message, 'username หรือรหัสผ่านไม่ถูกต้อง');
  assert.equal((await wrongLogin('th')).body.error.message, 'username หรือรหัสผ่านไม่ถูกต้อง');
  assert.equal((await wrongLogin('en')).body.error.message, 'Incorrect username or password');
  assert.equal(
    (await wrongLogin('ko')).body.error.message,
    '아이디 또는 비밀번호가 올바르지 않습니다',
  );
  assert.equal(
    (await wrongLogin('ko-KR,ko;q=0.9,en;q=0.8')).body.error.message,
    '아이디 또는 비밀번호가 올바르지 않습니다',
  );
  assert.equal((await wrongLogin('ja')).body.error.message, 'username หรือรหัสผ่านไม่ถูกต้อง');

  // รหัส error ไม่เปลี่ยนตามภาษา — แอปตัดสินใจจาก code ได้เหมือนเดิม
  assert.equal((await wrongLogin('ko')).body.error.code, (await wrongLogin()).body.error.code);
});

test('HTTP: ข้อความ validation และรายละเอียดแต่ละช่องก็แปล', async () => {
  const res = await api()
    .post('/api/v1/auth/login')
    .set('Accept-Language', 'en')
    .send({ username: '' });
  assert.equal(res.status, 422);
  assert.equal(res.body.error.message, 'Some of the information entered is invalid');
  assert.ok(Array.isArray(res.body.error.details));
});
