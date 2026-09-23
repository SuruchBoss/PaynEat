import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { receivableController } from './receivable.controller.js';
import {
  createReceiptSchema,
  createBillingNoteSchema,
  voidSchema,
  idParamSchema,
} from './receivable.schema.js';

const router = Router();
router.use(authenticate);

// ลูกหนี้เป็นเรื่องเงิน — พนักงานเสิร์ฟ/ครัวไม่เกี่ยว แคชเชียร์ดู/รับชำระ/วางบิลได้ ส่วนยกเลิกเอกสาร
// ต้องผู้จัดการขึ้นไป (หลักเดียวกับคืนเงินและยกเลิกใบกำกับภาษี) ดู docs/tickets/20-b2b-credit.md
const cashier = authorize('admin', 'manager', 'cashier');
const manager = authorize('admin', 'manager');

router.get('/customers', cashier, receivableController.listCustomers);
router.get(
  '/customers/:id',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.statement,
);

router.post(
  '/receipts',
  cashier,
  validate({ body: createReceiptSchema }),
  receivableController.createReceipt,
);
router.get(
  '/receipts/:id',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.getReceipt,
);
router.post(
  '/receipts/:id/void',
  manager,
  validate({ params: idParamSchema, body: voidSchema }),
  receivableController.voidReceipt,
);

router.post(
  '/billing-notes',
  cashier,
  validate({ body: createBillingNoteSchema }),
  receivableController.createBillingNote,
);
router.get(
  '/billing-notes/:id',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.getBillingNote,
);
router.post(
  '/billing-notes/:id/void',
  manager,
  validate({ params: idParamSchema, body: voidSchema }),
  receivableController.voidBillingNote,
);

export default router;
