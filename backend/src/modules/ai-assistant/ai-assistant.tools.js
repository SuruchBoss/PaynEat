// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { z } from 'zod';
import { reportService } from '../reports/report.service.js';
import { orderService } from '../orders/order.service.js';
import { customerRepository } from '../customers/customer.repository.js';
import { auditLogService } from '../audit-logs/audit-log.service.js';

/**
 * เครื่องมือทั้งหมดที่ให้ AI เรียกได้ — ห่อ service/repository ที่มีอยู่แล้วเท่านั้น ไม่มีตัวไหน
 * เข้าถึง DB ตรงๆ หรือรับ SQL/query จาก AI (ดู docs/tickets/15-ai-ask-your-data.md: "ไม่ให้ LLM
 * เข้าถึง DB ตรงๆ และไม่ให้แต่งตัวเลขเอง") ทุก handler คืนค่าที่ service เดิมคำนวณไว้แล้วตรงๆ
 * เท่านั้น AI ไม่มีทางได้ตัวเลขจากที่อื่น
 */

const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'ต้องเป็นรูปแบบ YYYY-MM-DD')
  .optional();

const rangeInputSchema = z.object({ from: dateSchema, to: dateSchema });

const TOOL_DEFINITIONS = [
  {
    name: 'get_sales_summary',
    role: null, // ทุก role ที่เข้าถึงผู้ช่วยนี้ได้ (admin/manager) ใช้ได้
    description:
      'ดูสรุปยอดขายรวมในช่วงวันที่ที่กำหนด (ยอดขาย ส่วนลด ค่าบริการ ภาษี จำนวนออเดอร์/แขก ' +
      'สัดส่วนช่องทางชำระเงิน ยอดตามหมวดหมู่เมนู) — ถ้าไม่ระบุ from/to จะได้ของวันนี้',
    input_schema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'วันที่เริ่ม รูปแบบ YYYY-MM-DD' },
        to: { type: 'string', description: 'วันที่สิ้นสุด รูปแบบ YYYY-MM-DD' },
      },
      additionalProperties: false,
    },
    inputSchema: rangeInputSchema,
    handler: ({ from, to }) => reportService.summary({ from, to }),
  },
  {
    name: 'get_top_selling_items',
    role: null,
    description: 'ดูเมนูขายดีที่สุดในช่วงวันที่ที่กำหนด เรียงตามจำนวนที่ขายได้',
    input_schema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'วันที่เริ่ม รูปแบบ YYYY-MM-DD' },
        to: { type: 'string', description: 'วันที่สิ้นสุด รูปแบบ YYYY-MM-DD' },
        limit: {
          type: 'integer',
          description: 'จำนวนเมนูสูงสุดที่ต้องการ (1-50)',
          minimum: 1,
          maximum: 50,
        },
      },
      additionalProperties: false,
    },
    inputSchema: rangeInputSchema.extend({
      limit: z.coerce.number().int().min(1).max(50).optional(),
    }),
    handler: ({ from, to, limit }) => reportService.topItems({ from, to, limit }),
  },
  {
    name: 'get_sales_by_day',
    role: null,
    description:
      'ดูยอดขายแยกรายวันในช่วงที่กำหนด (จำนวนออเดอร์ + ยอดขายต่อวัน) เหมาะกับคำถามเชิงเปรียบเทียบ ' +
      'เช่น "อาทิตย์นี้เทียบอาทิตย์ก่อน" — เรียกสองครั้งด้วยคนละช่วงวันที่แล้วเทียบเอง',
    input_schema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'วันที่เริ่ม รูปแบบ YYYY-MM-DD' },
        to: { type: 'string', description: 'วันที่สิ้นสุด รูปแบบ YYYY-MM-DD' },
      },
      additionalProperties: false,
    },
    inputSchema: rangeInputSchema,
    handler: ({ from, to }) => reportService.salesByDay({ from, to }),
  },
  {
    name: 'list_recent_orders',
    role: null,
    description:
      'ดูรายการออเดอร์ในช่วงวันที่ที่กำหนด กรองตามสถานะได้ (open/in_kitchen/served/paid/cancelled) ' +
      'ใช้เมื่อคำถามถามถึงออเดอร์เฉพาะเจาะจง ไม่ใช่แค่ยอดรวม',
    input_schema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'วันที่เริ่ม รูปแบบ YYYY-MM-DD' },
        to: { type: 'string', description: 'วันที่สิ้นสุด รูปแบบ YYYY-MM-DD' },
        status: {
          type: 'string',
          enum: ['open', 'in_kitchen', 'served', 'paid', 'cancelled'],
        },
        limit: { type: 'integer', minimum: 1, maximum: 50 },
      },
      additionalProperties: false,
    },
    inputSchema: rangeInputSchema.extend({
      status: z.enum(['open', 'in_kitchen', 'served', 'paid', 'cancelled']).optional(),
      limit: z.coerce.number().int().min(1).max(50).optional(),
    }),
    handler: ({ from, to, status, limit }) => {
      const { orders, total } = orderService.list({
        dateFrom: from,
        dateTo: to,
        status,
        limit: limit ?? 20,
      });
      return {
        total,
        // ตัดเหลือแค่ field ที่จำเป็นสำหรับตอบคำถาม — DTO เต็มมี items/options ละเอียดเกินความจำเป็น
        // และกิน token โดยเปล่าประโยชน์
        orders: orders.map((order) => ({
          code: order.code,
          type: order.type,
          status: order.status,
          total: order.total,
          guestCount: order.guestCount,
          createdAt: order.createdAt,
        })),
      };
    },
  },
  {
    name: 'get_top_customers',
    role: null,
    description:
      'ดูลูกค้าที่สั่งบ่อยที่สุด/ใช้จ่ายมากที่สุดในช่วงวันที่ที่กำหนด (นับเฉพาะออเดอร์ที่จ่ายแล้ว) — ' +
      'ใช้ตอบคำถามประเภท "ลูกค้าคนไหนซื้อบ่อยสุด"',
    input_schema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'วันที่เริ่ม รูปแบบ YYYY-MM-DD' },
        to: { type: 'string', description: 'วันที่สิ้นสุด รูปแบบ YYYY-MM-DD' },
        limit: { type: 'integer', minimum: 1, maximum: 50 },
      },
      additionalProperties: false,
    },
    inputSchema: rangeInputSchema.extend({
      limit: z.coerce.number().int().min(1).max(50).optional(),
    }),
    handler: ({ from, to, limit }) =>
      customerRepository.topByOrders({ from, to, limit: limit ?? 10 }).map((row) => ({
        name: row.name,
        phone: row.phone,
        orderCount: row.order_count,
        totalSpentBaht: Number((row.total_spent / 100).toFixed(2)),
      })),
  },
  {
    name: 'list_audit_log_entries',
    role: 'admin', // เฉพาะ admin — สอดคล้องกับ /audit-logs ที่จำกัดเฉพาะ admin อยู่แล้ว
    description:
      'ดูประวัติการทำรายการที่เสี่ยง/กระทบบัญชี (ยกเลิกออเดอร์ ให้ส่วนลด แก้ราคาเมนู คืนเงิน ฯลฯ) — ' +
      'เฉพาะผู้ดูแลระบบเท่านั้น',
    input_schema: {
      type: 'object',
      properties: {
        action: {
          type: 'string',
          description: 'เช่น order.cancel, menu.price_change, payment.refund',
        },
        from: { type: 'string', description: 'วันที่เริ่ม รูปแบบ YYYY-MM-DD' },
        to: { type: 'string', description: 'วันที่สิ้นสุด รูปแบบ YYYY-MM-DD' },
        limit: { type: 'integer', minimum: 1, maximum: 30 },
      },
      additionalProperties: false,
    },
    inputSchema: rangeInputSchema.extend({
      action: z.string().trim().min(1).optional(),
      limit: z.coerce.number().int().min(1).max(30).optional(),
    }),
    handler: ({ from, to, action, limit }) => {
      const { items, total } = auditLogService.list({
        dateFrom: from,
        dateTo: to,
        action,
        page: 1,
        limit: limit ?? 10,
      });
      return {
        total,
        items: items.map((log) => ({
          action: log.action,
          entityType: log.entityType,
          summary: log.summary,
          actorName: log.actorName,
          createdAt: log.createdAt,
        })),
      };
    },
  },
];

/** เครื่องมือที่ role นี้เรียกได้ — จำกัดตาม role ตั้งแต่ระดับที่ยื่นให้โมเดลเลือก ไม่ใช่แค่กรองผลลัพธ์
 * ทีหลัง กัน manager เห็นข้อมูล audit log ผ่านผู้ช่วย AI ทั้งที่หน้า /audit-logs เองก็สงวนไว้เฉพาะ
 * admin อยู่แล้ว (ไม่งั้นผู้ช่วย AI จะกลายเป็นช่องทางเลี่ยงสิทธิ์ที่มีอยู่เดิมในระบบ) */
export const getToolsForRole = (role) =>
  TOOL_DEFINITIONS.filter((tool) => !tool.role || tool.role === role);

export const getToolDefinitionsForRole = (role) =>
  getToolsForRole(role).map(({ name, description, input_schema }) => ({
    name,
    description,
    input_schema,
  }));

export const getToolHandler = (role, name) =>
  getToolsForRole(role).find((tool) => tool.name === name);

export default TOOL_DEFINITIONS;
