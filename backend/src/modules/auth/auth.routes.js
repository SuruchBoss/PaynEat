import { Router } from 'express';
import { authenticate, authenticateForBranchSelection } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { authController } from './auth.controller.js';
import { loginSchema, changePasswordSchema, selectBranchSchema } from './auth.schema.js';

const router = Router();

router.post('/login', validate({ body: loginSchema }), authController.login);
// รับได้ทั้ง pendingToken (แลก token ปกติครั้งแรกตอนมีหลายสาขา) และ token ปกติที่ login แล้ว
// (สลับสาขาภายหลัง) — ดู middlewares/auth.js#authenticateForBranchSelection
router.post(
  '/select-branch',
  authenticateForBranchSelection,
  validate({ body: selectBranchSchema }),
  authController.selectBranch,
);
router.get('/me', authenticate, authController.me);
router.post(
  '/change-password',
  authenticate,
  validate({ body: changePasswordSchema }),
  authController.changePassword,
);

export default router;
