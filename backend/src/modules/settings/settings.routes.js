import { Router } from 'express';
import { z } from 'zod';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { settingsController } from './settings.controller.js';

const updateSettingsSchema = z
  .object({
    storeName: z.string().min(1).max(80).optional(),
    currency: z.string().min(1).max(8).optional(),
    vatRate: z.number().min(0).max(1).optional(),
    serviceChargeRate: z.number().min(0).max(1).optional(),
    vatIncluded: z.boolean().optional(),
    storeTaxId: z.string().trim().max(20).optional(),
    storeAddress: z.string().trim().max(500).optional(),
    storeBranch: z.string().trim().max(80).optional(),
    promptPayId: z.string().trim().max(20).optional(),
    pointsEarnRateBaht: z.number().positive().optional(),
    pointsRedeemValueBaht: z.number().min(0).optional(),
    // รูปแบบฉลากตาชั่ง (EAN-13 ขึ้นต้นด้วย 2 — ดู docs/tickets/19-barcode-scale.md): prefix 1–3 หลัก
    // + PLU 4–6 หลัก + น้ำหนักกรัม (หลักที่เหลือ ต้องได้ 4–6 หลัก) + check digit — ตรวจความยาวรวมที่นี่
    scaleLabelPrefix: z
      .string()
      .trim()
      .regex(/^2\d{0,2}$/, 'prefix ของฉลากตาชั่งต้องขึ้นต้นด้วย 2 และยาว 1–3 หลัก')
      .optional(),
    scaleLabelPluDigits: z.number().int().min(4).max(6).optional(),
  })
  .refine(
    (data) => {
      if (data.scaleLabelPrefix === undefined || data.scaleLabelPluDigits === undefined)
        return true;
      const weightDigits = 12 - data.scaleLabelPrefix.length - data.scaleLabelPluDigits;
      return weightDigits >= 4 && weightDigits <= 6;
    },
    { message: 'prefix + PLU ต้องเหลือหลักน้ำหนัก 4–6 หลัก', path: ['scaleLabelPluDigits'] },
  );

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
