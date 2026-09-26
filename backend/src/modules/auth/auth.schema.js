// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { z } from 'zod';

export const loginSchema = z.object({
  username: z.string().min(1, 'กรุณากรอก username'),
  password: z.string().min(1, 'กรุณากรอกรหัสผ่าน'),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(6, 'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร').max(72),
});

// branchId เป็น null ได้เฉพาะ admin เท่านั้น (โหมด "ทุกสาขา" ดู docs/DECISIONS.md #36) —
// ตรวจสิทธิ์จริงที่ authService.selectBranch ไม่ใช่ที่ schema นี้
export const selectBranchSchema = z.object({
  branchId: z.number().int().positive().nullable(),
});
