import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { authService } from './auth.service.js';

export const authController = {
  login: asyncHandler(async (req, res) => ok(res, authService.login(req.body))),

  me: asyncHandler(async (req, res) => ok(res, authService.me(req.user.id))),

  changePassword: asyncHandler(async (req, res) => {
    authService.changePassword(req.user.id, req.body);
    return ok(res, { message: 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว' });
  }),
};

export default authController;
