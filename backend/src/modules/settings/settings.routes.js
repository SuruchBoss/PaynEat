import { Router } from 'express';
import { z } from 'zod';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { settingsController } from './settings.controller.js';

const updateSettingsSchema = z.object({
  storeName: z.string().min(1).max(80).optional(),
  currency: z.string().min(1).max(8).optional(),
  vatRate: z.number().min(0).max(1).optional(),
  serviceChargeRate: z.number().min(0).max(1).optional(),
  vatIncluded: z.boolean().optional(),
});

const router = Router();

router.get('/', authenticate, settingsController.get);
router.patch(
  '/',
  authenticate,
  authorize('admin', 'manager'),
  validate({ body: updateSettingsSchema }),
  settingsController.update,
);

export default router;
