// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { paymentService } from '../payments/payment.service.js';
import { creditNoteService } from './credit-note.service.js';
import { lateFeeService } from './late-fee.service.js';
import { documentService } from './receivable.documents.js';
import { receivableService } from './receivable.service.js';

export const receivableController = {
  listCustomers: asyncHandler(async (req, res) => ok(res, receivableService.listCustomers())),

  statement: asyncHandler(async (req, res) =>
    ok(res, receivableService.statement(req.validated.params.id)),
  ),

  createReceipt: asyncHandler(async (req, res) =>
    created(res, receivableService.createReceipt(req.body, req.user)),
  ),

  getReceipt: asyncHandler(async (req, res) =>
    ok(res, receivableService.getReceipt(req.validated.params.id)),
  ),

  voidReceipt: asyncHandler(async (req, res) =>
    ok(res, receivableService.voidReceipt(req.validated.params.id, req.body.reason, req.user)),
  ),

  createBillingNote: asyncHandler(async (req, res) =>
    created(res, receivableService.createBillingNote(req.body, req.user)),
  ),

  getBillingNote: asyncHandler(async (req, res) =>
    ok(res, receivableService.getBillingNote(req.validated.params.id)),
  ),

  voidBillingNote: asyncHandler(async (req, res) =>
    ok(res, receivableService.voidBillingNote(req.validated.params.id, req.body.reason, req.user)),
  ),

  lateFeePreview: asyncHandler(async (req, res) =>
    ok(res, lateFeeService.preview(req.validated.params.id)),
  ),

  createLateFee: asyncHandler(async (req, res) =>
    created(res, lateFeeService.create(req.body, req.user)),
  ),

  getLateFee: asyncHandler(async (req, res) =>
    ok(res, lateFeeService.get(req.validated.params.id)),
  ),

  voidLateFee: asyncHandler(async (req, res) =>
    ok(res, lateFeeService.void(req.validated.params.id, req.body.reason, req.user)),
  ),

  // ลดหนี้ = คืนเงินบิลขายเชื่อ (payment.service.js#refund ออกใบลดหนี้ให้ในทรานแซกชันเดียวกัน)
  // endpoint นี้แค่กันไม่ให้ใช้กับบิลเงินสด แล้วตอบกลับเป็นใบลดหนี้แทนรายการคืนเงิน
  createCreditNote: asyncHandler(async (req, res) => {
    const { paymentId, amount, reason } = req.body;
    creditNoteService.assertCreditPayment(paymentId);
    const refund = paymentService.refund(paymentId, { amount, reason }, req.user);
    created(res, creditNoteService.getByRefund(refund.id));
  }),

  getCreditNote: asyncHandler(async (req, res) =>
    ok(res, creditNoteService.get(req.validated.params.id)),
  ),

  /** PDF ของเอกสาร — ไม่ใช้ ok() เพราะตอบเป็นไฟล์ ไม่ใช่ JSON */
  documentPdf: (kind) =>
    asyncHandler(async (req, res) => {
      const { filename, content } = await documentService.pdf(kind, req.validated.params.id);
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `inline; filename="${filename}"`);
      // เอกสารการเงินของลูกค้า — ห้าม proxy/เบราว์เซอร์เก็บไว้
      res.setHeader('Cache-Control', 'no-store');
      res.send(content);
    }),

  emailDocument: (kind) =>
    asyncHandler(async (req, res) =>
      ok(res, await documentService.email(kind, req.validated.params.id, req.body, req.user)),
    ),
};

export default receivableController;
