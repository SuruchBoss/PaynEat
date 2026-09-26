// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { toBaht } from '../../core/money.js';

export const toTableDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    zone: row.zone,
    seats: row.seats,
    status: row.status,
    isActive: Boolean(row.is_active),
    branchId: row.branch_id ?? null,
    // token สุ่มสำหรับ URL สั่งอาหารเอง (ดู docs/tickets/17-qr-self-order.md) — เห็นได้ทุก role ที่
    // เข้าถึงหน้าผังโต๊ะ เพราะเป็นแค่ capability token ไว้ให้พนักงานดู/พิมพ์ QR ไม่ใช่ความลับระดับสิทธิ์
    qrToken: row.qr_token ?? null,
    currentOrder: row.order_id
      ? {
          id: row.order_id,
          code: row.order_code,
          status: row.order_status,
          total: toBaht(row.order_total),
          guestCount: row.order_guest_count,
          createdAt: row.order_created_at,
        }
      : null,
  };
};

export default toTableDto;
