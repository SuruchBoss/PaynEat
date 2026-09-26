// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { ApiError } from './ApiError.js';

/**
 * ใช้ตอนสร้าง entity ที่ผูก branch_id (dining_tables/menu_items/ingredients/orders) — ผู้ใช้ทั่วไป
 * อนุมานจาก currentBranchId (req.branchId คือสาขาที่กำลังทำงานอยู่) เสมอ ส่วน admin โหมด "ทุกสาขา"
 * (currentBranchId เป็น null) ต้องระบุ branchId เองทาง payload เพราะไม่มีสาขา "ปัจจุบัน" ให้อนุมาน
 * (ดู docs/DECISIONS.md #36)
 */
export const resolveBranchIdForWrite = (currentBranchId, payloadBranchId) => {
  const resolved = currentBranchId ?? payloadBranchId;
  if (!resolved) {
    throw ApiError.badRequest('ต้องระบุ branchId เพราะกำลังดูข้อมูลรวมทุกสาขาอยู่ (โหมดทุกสาขา)');
  }
  return resolved;
};

export default resolveBranchIdForWrite;
