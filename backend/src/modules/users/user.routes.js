import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { userController } from './user.controller.js';
import {
  createUserSchema,
  updateUserSchema,
  resetPasswordSchema,
  listUserQuerySchema,
  idParamSchema,
} from './user.schema.js';

const router = Router();

// จัดการพนักงานทั้งหมดสงวนไว้สำหรับ admin/manager
router.use(authenticate, authorize('admin', 'manager'));

router.get('/', validate({ query: listUserQuerySchema }), userController.list);
router.post('/', validate({ body: createUserSchema }), userController.create);
router.get('/:id', validate({ params: idParamSchema }), userController.detail);
router.patch(
  '/:id',
  validate({ params: idParamSchema, body: updateUserSchema }),
  userController.update,
);
router.post(
  '/:id/reset-password',
  validate({ params: idParamSchema, body: resetPasswordSchema }),
  userController.resetPassword,
);
router.delete(
  '/:id',
  authorize('admin'),
  validate({ params: idParamSchema }),
  userController.remove,
);

export default router;
