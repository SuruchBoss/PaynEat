import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created } from '../../core/response.js';
import { branchService } from './branch.service.js';

export const branchController = {
  list: asyncHandler(async (req, res) => ok(res, branchService.list())),

  mine: asyncHandler(async (req, res) => ok(res, branchService.listForUser(req.user))),

  detail: asyncHandler(async (req, res) => ok(res, branchService.getById(req.validated.params.id))),

  create: asyncHandler(async (req, res) => created(res, branchService.create(req.body))),

  update: asyncHandler(async (req, res) =>
    ok(res, branchService.update(req.validated.params.id, req.body)),
  ),
};

export default branchController;
