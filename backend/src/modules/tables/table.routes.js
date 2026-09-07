import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { tableController } from './table.controller.js';
import {
  createTableSchema,
  updateTableSchema,
  setStatusSchema,
  listTableQuerySchema,
  idParamSchema,
} from './table.schema.js';

const router = Router();
const manager = authorize('admin', 'manager');

router.get('/', authenticate, validate({ query: listTableQuerySchema }), tableController.list);
router.get('/zones', authenticate, tableController.zones);
router.get('/:id', authenticate, validate({ params: idParamSchema }), tableController.detail);
router.post('/', authenticate, manager, validate({ body: createTableSchema }), tableController.create);
router.patch(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema, body: updateTableSchema }),
  tableController.update,
);
router.patch(
  '/:id/status',
  authenticate,
  validate({ params: idParamSchema, body: setStatusSchema }),
  tableController.setStatus,
);
router.delete('/:id', authenticate, manager, validate({ params: idParamSchema }), tableController.remove);

export default router;
