import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
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
};

export default receivableController;
