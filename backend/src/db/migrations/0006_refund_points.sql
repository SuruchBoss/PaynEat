-- Copyright 2026 Suruch Chakrapeesirisuk
-- SPDX-License-Identifier: Apache-2.0

-- Migration 0006 — แยกการคืนเงินเป็นเงินจริงกับแต้มที่คืนให้ลูกค้า (T11 #101, docs/DECISIONS.md #100)
-- refunds.amount ยังเป็นยอดที่คืนตามมูลค่าบิล (เงิน + มูลค่าแต้ม) เหมือนเดิม ยอดจ่ายแล้วของบิล (netPaid) จึงไม่เปลี่ยน
-- points_returned = จำนวนแต้มที่คืนให้ลูกค้า, points_value = มูลค่าของแต้มเหล่านั้นเป็นสตางค์ เงินที่ออกจากช่องทางจริง = amount − points_value
-- การคืนเงินก่อน migration นี้คืนเป็นเงินทั้งก้อน (ไม่มีการคืนแต้ม) จึงเป็น 0 ตามจริง
ALTER TABLE refunds ADD COLUMN points_returned INTEGER NOT NULL DEFAULT 0 CHECK (points_returned >= 0);
ALTER TABLE refunds ADD COLUMN points_value INTEGER NOT NULL DEFAULT 0 CHECK (points_value >= 0);
