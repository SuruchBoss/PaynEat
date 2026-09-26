// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { paymentService } from './payment.service.js';

export const paymentController = {
  pay: asyncHandler(async (req, res) => created(res, paymentService.pay(req.body, req.user))),
  summary: asyncHandler(async (req, res) =>
    ok(res, paymentService.summary(req.validated.params.id)),
  ),
  splitPreview: asyncHandler(async (req, res) =>
    ok(res, paymentService.splitPreview(req.validated.params.id, req.body.itemIds)),
  ),
  receipt: asyncHandler(async (req, res) =>
    ok(res, paymentService.receipt(req.validated.params.id)),
  ),
  promptPayQr: asyncHandler(async (req, res) =>
    ok(res, paymentService.promptPayQr(req.validated.query.amount)),
  ),
  refund: asyncHandler(async (req, res) =>
    created(res, paymentService.refund(req.validated.params.id, req.body, req.user)),
  ),
};

export default paymentController;
