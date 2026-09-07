import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent } from '../../core/response.js';
import { userService } from './user.service.js';

export const userController = {
  list: asyncHandler(async (req, res) => ok(res, userService.list(req.validated?.query ?? {}))),

  detail: asyncHandler(async (req, res) => ok(res, userService.getById(req.validated.params.id))),

  create: asyncHandler(async (req, res) => created(res, userService.create(req.body))),

  update: asyncHandler(async (req, res) =>
    ok(res, userService.update(req.validated.params.id, req.body)),
  ),

  resetPassword: asyncHandler(async (req, res) =>
    ok(res, userService.resetPassword(req.validated.params.id, req.body.password)),
  ),

  remove: asyncHandler(async (req, res) => {
    userService.remove(req.validated.params.id, req.user.id);
    return noContent(res);
  }),
};

export default userController;
