// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/** Migration 0006 — `refunds.points_returned` / `refunds.points_value` (T11 #101, docs/DECISIONS.md #99) ทั้งหมดอยู่ใน .sql */

const sql = path.join(path.dirname(fileURLToPath(import.meta.url)), '0006_refund_points.sql');

export default {
  version: 6,
  name: 'refund_points',
  files: [fileURLToPath(import.meta.url), sql],
  up(db) {
    db.exec(fs.readFileSync(sql, 'utf8'));
  },
};
