import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { paymentService } from './payment.service.js';

export const paymentController = {
  pay: asyncHandler(async (req, res) => created(res, paymentService.pay(req.body, req.user))),
  summary: asyncHandler(async (req, res) =>
    ok(res, paymentService.summary(req.validated.params.id)),
  ),
  receipt: asyncHandler(async (req, res) =>
    ok(res, paymentService.receipt(req.validated.params.id)),
  ),
};

export default paymentController;
