import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { promotionController } from './promotion.controller.js';
import {
  createPromotionSchema,
  updatePromotionSchema,
  listPromotionQuerySchema,
  idParamSchema,
} from './promotion.schema.js';

const router = Router();
const manager = authorize('admin', 'manager');

router.get(
  '/',
  authenticate,
  validate({ query: listPromotionQuerySchema }),
  promotionController.list,
);
router.get('/:id', authenticate, validate({ params: idParamSchema }), promotionController.detail);
router.post(
  '/',
  authenticate,
  manager,
  validate({ body: createPromotionSchema }),
  promotionController.create,
);
router.patch(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema, body: updatePromotionSchema }),
  promotionController.update,
);
router.delete(
  '/:id',
  authenticate,
  manager,
  validate({ params: idParamSchema }),
  promotionController.remove,
);

export default router;
