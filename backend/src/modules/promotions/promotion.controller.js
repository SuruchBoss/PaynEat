import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent } from '../../core/response.js';
import { promotionService } from './promotion.service.js';

export const promotionController = {
  list: asyncHandler(async (req, res) =>
    ok(res, promotionService.list(req.validated?.query ?? {})),
  ),
  detail: asyncHandler(async (req, res) =>
    ok(res, promotionService.getById(req.validated.params.id)),
  ),
  create: asyncHandler(async (req, res) => created(res, promotionService.create(req.body))),
  update: asyncHandler(async (req, res) =>
    ok(res, promotionService.update(req.validated.params.id, req.body)),
  ),
  remove: asyncHandler(async (req, res) => {
    promotionService.remove(req.validated.params.id);
    return noContent(res);
  }),
};

export default promotionController;
