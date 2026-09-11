import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { taxInvoiceService } from './tax-invoice.service.js';

export const taxInvoiceController = {
  detail: asyncHandler(async (req, res) =>
    ok(res, taxInvoiceService.getActiveByOrder(req.validated.params.id)),
  ),

  issue: asyncHandler(async (req, res) =>
    created(res, taxInvoiceService.issue(req.validated.params.id, req.body, req.user)),
  ),

  void: asyncHandler(async (req, res) =>
    ok(res, taxInvoiceService.void(req.validated.params.id, req.body, req.user)),
  ),
};

export default taxInvoiceController;
