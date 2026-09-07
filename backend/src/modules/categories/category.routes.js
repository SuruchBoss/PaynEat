import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { categoryController } from './category.controller.js';
import {
  createCategorySchema,
  updateCategorySchema,
  listCategoryQuerySchema,
  idParamSchema,
} from './category.schema.js';

const router = Router();
const manager = authorize('admin', 'manager');

router.get('/', authenticate, validate({ query: listCategoryQuerySchema }), categoryController.list);
router.get('/:id', authenticate, validate({ params: idParamSchema }), categoryController.detail);
router.post('/', authenticate, manager, validate({ body: createCategorySchema }), categoryController.create);
router.patch(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema, body: updateCategorySchema }),
  categoryController.update,
);
router.delete('/:id', authenticate, manager, validate({ params: idParamSchema }), categoryController.remove);

export default router;
