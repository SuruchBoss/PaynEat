import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { shiftController } from './shift.controller.js';
import {
  openShiftSchema,
  closeShiftSchema,
  listShiftQuerySchema,
  idParamSchema,
} from './shift.schema.js';

const router = Router();
router.use(authenticate);
const cashRole = authorize('admin', 'manager', 'cashier');

router.get('/current', cashRole, shiftController.current);
router.get('/', cashRole, validate({ query: listShiftQuerySchema }), shiftController.list);
router.get('/:id', cashRole, validate({ params: idParamSchema }), shiftController.detail);
router.post('/', cashRole, validate({ body: openShiftSchema }), shiftController.open);
router.patch(
  '/:id/close',
  cashRole,
  validate({ params: idParamSchema, body: closeShiftSchema }),
  shiftController.close,
);

export default router;
