import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent } from '../../core/response.js';
import { tableService } from './table.service.js';

export const tableController = {
  list: asyncHandler(async (req, res) => ok(res, tableService.list(req.validated?.query ?? {}))),
  zones: asyncHandler(async (_req, res) => ok(res, tableService.zones())),
  detail: asyncHandler(async (req, res) => ok(res, tableService.getById(req.validated.params.id))),
  create: asyncHandler(async (req, res) => created(res, tableService.create(req.body))),
  update: asyncHandler(async (req, res) =>
    ok(res, tableService.update(req.validated.params.id, req.body)),
  ),
  setStatus: asyncHandler(async (req, res) =>
    ok(res, tableService.setStatus(req.validated.params.id, req.body.status)),
  ),
  remove: asyncHandler(async (req, res) => {
    tableService.remove(req.validated.params.id);
    return noContent(res);
  }),
};

export default tableController;
