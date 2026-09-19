import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { publicOrderService } from './public-order.service.js';

export const publicOrderController = {
  getTable: asyncHandler(async (req, res) =>
    ok(res, publicOrderService.getTable(req.validated.params.qrToken)),
  ),
  getMenu: asyncHandler(async (req, res) =>
    ok(res, publicOrderService.getMenu(req.validated.params.qrToken)),
  ),
  addItems: asyncHandler(async (req, res) =>
    ok(res, publicOrderService.addItems(req.validated.params.qrToken, req.validated.body.items)),
  ),
};

export default publicOrderController;
