import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent } from '../../core/response.js';
import { categoryService } from './category.service.js';

export const categoryController = {
  list: asyncHandler(async (req, res) => ok(res, categoryService.list(req.validated?.query ?? {}))),
  detail: asyncHandler(async (req, res) =>
    ok(res, categoryService.getById(req.validated.params.id)),
  ),
  create: asyncHandler(async (req, res) => created(res, categoryService.create(req.body))),
  update: asyncHandler(async (req, res) =>
    ok(res, categoryService.update(req.validated.params.id, req.body)),
  ),
  remove: asyncHandler(async (req, res) => {
    categoryService.remove(req.validated.params.id);
    return noContent(res);
  }),
};

export default categoryController;
