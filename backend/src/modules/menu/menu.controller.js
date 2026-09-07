import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent, paginated } from '../../core/response.js';
import { menuService } from './menu.service.js';

export const menuController = {
  list: asyncHandler(async (req, res) => {
    const query = req.validated.query;
    const { items, total } = menuService.list(query);
    return paginated(res, items, { page: query.page, limit: query.limit, total });
  }),

  detail: asyncHandler(async (req, res) => ok(res, menuService.getById(req.validated.params.id))),

  create: asyncHandler(async (req, res) => created(res, menuService.create(req.body))),

  update: asyncHandler(async (req, res) =>
    ok(res, menuService.update(req.validated.params.id, req.body)),
  ),

  setAvailability: asyncHandler(async (req, res) =>
    ok(res, menuService.setAvailability(req.validated.params.id, req.body.isAvailable)),
  ),

  remove: asyncHandler(async (req, res) => {
    menuService.remove(req.validated.params.id);
    return noContent(res);
  }),
};

export default menuController;
