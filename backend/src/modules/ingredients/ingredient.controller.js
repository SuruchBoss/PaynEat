import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent } from '../../core/response.js';
import { ingredientService } from './ingredient.service.js';

export const ingredientController = {
  list: asyncHandler(async (req, res) => ok(res, ingredientService.list(req.validated.query))),

  detail: asyncHandler(async (req, res) =>
    ok(res, ingredientService.getById(req.validated.params.id)),
  ),

  create: asyncHandler(async (req, res) => created(res, ingredientService.create(req.body))),

  update: asyncHandler(async (req, res) =>
    ok(res, ingredientService.update(req.validated.params.id, req.body)),
  ),

  adjustStock: asyncHandler(async (req, res) =>
    ok(res, ingredientService.adjustStock(req.validated.params.id, req.body.delta)),
  ),

  remove: asyncHandler(async (req, res) => {
    ingredientService.remove(req.validated.params.id);
    return noContent(res);
  }),
};

export default ingredientController;
