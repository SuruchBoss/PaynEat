// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { env } from '../../config/env.js';
import { emit, EVENTS, ROOMS } from '../../realtime/socket.js';
import { createDriver } from './scale.drivers.js';
import { parseScaleLine } from './scale.parser.js';

/**
 * สะพานตาชั่ง (ดู docs/tickets/22-live-scale-camera-scan.md, docs/DECISIONS.md #54)
 *
 * แท็บเล็ต/มือถือ/เบราว์เซอร์ต่อพอร์ตตาชั่งเองไม่ได้ (Web Serial มีแค่ Chrome เดสก์ท็อป ไม่มีบน iPad/
 * Android) เซิร์ฟเวอร์ร้านที่ตั้งอยู่หน้าเคาน์เตอร์จึงเป็นคนอ่านตาชั่งแทน แล้วกระจายน้ำหนักล่าสุดให้ทุกเครื่อง
 * ผ่าน socket.io (event scale:reading) — แอปแค่ฟัง ไม่ต้องรู้ว่าตาชั่งยี่ห้ออะไรต่อแบบไหน
 *
 * น้ำหนักที่เก่ากว่า STALE_MS ไม่ถูกส่งออกไป (ตาชั่งหลุด/ปิดไปแล้ว ตัวเลขค้างบนจอจะหลอกให้ขายผิด)
 */

const STALE_MS = 3000;
const HEARTBEAT_MS = 1000;

const state = {
  driver: 'off',
  connected: false,
  error: null,
  reading: null,
  readAt: 0,
};

let driver = null;
let pollTimer = null;
let lastKey = null;
let lastEmitAt = 0;

const snapshot = () => {
  const fresh = state.reading && Date.now() - state.readAt <= STALE_MS;
  return {
    enabled: state.driver !== 'off',
    driver: state.driver,
    connected: state.connected,
    error: state.error,
    reading: fresh ? { ...state.reading, at: new Date(state.readAt).toISOString() } : null,
  };
};

const broadcast = () => {
  lastEmitAt = Date.now();
  emit(EVENTS.SCALE_READING, snapshot(), [ROOMS.SERVICE, ROOMS.MANAGEMENT]);
};

const ingest = (line) => {
  const reading = parseScaleLine(line);
  if (!reading) return;
  state.reading = reading;
  state.readAt = Date.now();
  // ตาชั่งส่งถี่ 5–20 ครั้ง/วินาที — ส่งต่อเฉพาะตอนค่าเปลี่ยน กับ heartbeat ทุกวินาทีให้แอปรู้ว่ายังสด
  const key = `${reading.grams}:${reading.stable}:${reading.overload}`;
  if (key !== lastKey || Date.now() - lastEmitAt >= HEARTBEAT_MS) {
    lastKey = key;
    broadcast();
  }
};

const onStatus = ({ connected, error }) => {
  const changed = connected !== state.connected || (error !== undefined && error !== state.error);
  state.connected = connected;
  if (error !== undefined) state.error = error;
  if (!connected) state.reading = null;
  if (changed) broadcast();
};

export const scaleService = {
  start(config = env.scale) {
    this.stop();
    state.driver = config.driver;
    driver = createDriver(config);
    if (!driver) return;
    driver.start({ onLine: ingest, onStatus });
    if (config.pollCommand) {
      pollTimer = setInterval(() => driver?.write(`${config.pollCommand}\r\n`), config.pollMs);
    }
  },

  stop() {
    clearInterval(pollTimer);
    pollTimer = null;
    driver?.stop();
    driver = null;
    Object.assign(state, {
      driver: 'off',
      connected: false,
      error: null,
      reading: null,
      readAt: 0,
    });
    lastKey = null;
  },

  status() {
    return snapshot();
  },

  /** ให้เทสต์ป้อนบรรทัดจากตาชั่งตรง ๆ โดยไม่ต้องเปิด socket */
  ingestLine: ingest,
};

export default scaleService;
