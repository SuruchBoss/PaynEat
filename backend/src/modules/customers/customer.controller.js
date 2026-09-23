import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, paginated } from '../../core/response.js';
import { customerService } from './customer.service.js';

export const customerController = {
  list: asyncHandler(async (req, res) => {
    const query = req.validated.query;
    const { customers, total } = customerService.list(query);
    return paginated(res, customers, { page: query.page, limit: query.limit, total });
  }),

  detail: asyncHandler(async (req, res) =>
    ok(res, customerService.getById(req.validated.params.id)),
  ),

  create: asyncHandler(async (req, res) => created(res, customerService.create(req.body))),

  updateCredit: asyncHandler(async (req, res) =>
    ok(res, customerService.updateCredit(req.validated.params.id, req.body, req.user)),
  ),
};

export default customerController;
