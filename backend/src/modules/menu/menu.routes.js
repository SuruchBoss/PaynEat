import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { menuController } from './menu.controller.js';
import {
  createMenuItemSchema,
  updateMenuItemSchema,
  toggleAvailabilitySchema,
  listMenuQuerySchema,
  idParamSchema,
} from './menu.schema.js';

const router = Router();
const manager = authorize('admin', 'manager');

router.get('/', authenticate, validate({ query: listMenuQuerySchema }), menuController.list);
router.get('/:id', authenticate, validate({ params: idParamSchema }), menuController.detail);
router.post(
  '/',
  authenticate,
  manager,
  validate({ body: createMenuItemSchema }),
  menuController.create,
);
router.patch(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema, body: updateMenuItemSchema }),
  menuController.update,
);
// ครัว/พนักงานเสิร์ฟกดปิดเมนูที่ของหมดได้ทันที ไม่ต้องรอผู้จัดการ
router.patch(
  '/:id/availability',
  authenticate,
  authorize('admin', 'manager', 'kitchen', 'waiter'),
  validate({ params: idParamSchema, body: toggleAvailabilitySchema }),
  menuController.setAvailability,
);
router.delete(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema }),
  menuController.remove,
);

export default router;
