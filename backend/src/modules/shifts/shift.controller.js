import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { shiftService } from './shift.service.js';

export const shiftController = {
  current: asyncHandler(async (req, res) => ok(res, shiftService.current())),
  detail: asyncHandler(async (req, res) => ok(res, shiftService.getById(req.validated.params.id))),
  list: asyncHandler(async (req, res) => ok(res, shiftService.list(req.validated?.query ?? {}))),
  open: asyncHandler(async (req, res) => created(res, shiftService.open(req.body, req.user))),
  close: asyncHandler(async (req, res) =>
    ok(res, shiftService.close(req.validated.params.id, req.body, req.user)),
  ),
};

export default shiftController;
