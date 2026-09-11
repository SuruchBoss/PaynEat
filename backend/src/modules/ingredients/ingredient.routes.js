import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { ingredientController } from './ingredient.controller.js';
import {
  createIngredientSchema,
  updateIngredientSchema,
  adjustStockSchema,
  listIngredientQuerySchema,
  idParamSchema,
} from './ingredient.schema.js';

const router = Router();
const manager = authorize('admin', 'manager');

router.get(
  '/',
  authenticate,
  validate({ query: listIngredientQuerySchema }),
  ingredientController.list,
);
router.get('/:id', authenticate, validate({ params: idParamSchema }), ingredientController.detail);
router.post(
  '/',
  authenticate,
  manager,
  validate({ body: createIngredientSchema }),
  ingredientController.create,
);
router.patch(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema, body: updateIngredientSchema }),
  ingredientController.update,
);
router.post(
  '/:id/adjust-stock',
  authenticate,
  manager,
  validate({ params: idParamSchema, body: adjustStockSchema }),
  ingredientController.adjustStock,
);
router.delete(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema }),
  ingredientController.remove,
);

export default router;
