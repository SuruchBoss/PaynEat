import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, paginated } from '../../core/response.js';
import { orderService } from './order.service.js';

export const orderController = {
  list: asyncHandler(async (req, res) => {
    const query = req.validated.query;
    const { orders, total } = orderService.list(query);
    return paginated(res, orders, { page: query.page, limit: query.limit, total });
  }),

  detail: asyncHandler(async (req, res) => ok(res, orderService.getById(req.validated.params.id))),

  byCode: asyncHandler(async (req, res) => ok(res, orderService.getByCode(req.params.code))),

  openByTable: asyncHandler(async (req, res) =>
    ok(res, orderService.getOpenByTable(req.validated.params.id)),
  ),

  create: asyncHandler(async (req, res) => created(res, orderService.create(req.body, req.user))),

  update: asyncHandler(async (req, res) =>
    ok(res, orderService.updateMeta(req.validated.params.id, req.body)),
  ),

  addItems: asyncHandler(async (req, res) =>
    created(res, orderService.addItems(req.validated.params.id, req.body.items)),
  ),

  updateItem: asyncHandler(async (req, res) =>
    ok(
      res,
      orderService.updateItem(req.validated.params.id, req.validated.params.itemId, req.body),
    ),
  ),

  removeItem: asyncHandler(async (req, res) =>
    ok(res, orderService.removeItem(req.validated.params.id, req.validated.params.itemId)),
  ),

  updateItemStatus: asyncHandler(async (req, res) =>
    ok(
      res,
      orderService.updateItemStatus(
        req.validated.params.id,
        req.validated.params.itemId,
        req.body.status,
        req.user,
      ),
    ),
  ),

  sendToKitchen: asyncHandler(async (req, res) =>
    ok(res, orderService.sendToKitchen(req.validated.params.id)),
  ),

  applyDiscount: asyncHandler(async (req, res) =>
    ok(res, orderService.applyDiscount(req.validated.params.id, req.body)),
  ),

  cancel: asyncHandler(async (req, res) =>
    ok(res, orderService.cancel(req.validated.params.id, req.body.reason)),
  ),

  kitchenQueue: asyncHandler(async (req, res) => {
    const statuses = req.query.status
      ? String(req.query.status)
          .split(',')
          .map((value) => value.trim())
      : undefined;
    return ok(res, orderService.kitchenQueue(statuses));
  }),
};

export default orderController;
