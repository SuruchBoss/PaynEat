import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { receivableController } from './receivable.controller.js';
import {
  createReceiptSchema,
  createBillingNoteSchema,
  createLateFeeSchema,
  createCreditNoteSchema,
  emailDocumentSchema,
  voidSchema,
  idParamSchema,
} from './receivable.schema.js';

const router = Router();
router.use(authenticate);

// ลูกหนี้เป็นเรื่องเงิน — พนักงานเสิร์ฟ/ครัวไม่เกี่ยว แคชเชียร์ดู/รับชำระ/วางบิลได้ ส่วนยกเลิกเอกสาร
// คิดดอกเบี้ย และลดหนี้ ต้องผู้จัดการขึ้นไป (หลักเดียวกับคืนเงินและยกเลิกใบกำกับภาษี — เปลี่ยนยอดหนี้
// ของลูกค้า) ดู docs/tickets/20-b2b-credit.md, docs/tickets/21-late-fees-credit-notes.md
const cashier = authorize('admin', 'manager', 'cashier');
const manager = authorize('admin', 'manager');

router.get('/customers', cashier, receivableController.listCustomers);
router.get(
  '/customers/:id',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.statement,
);
router.get(
  '/customers/:id/late-fee-preview',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.lateFeePreview,
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

router.post(
  '/late-fees',
  manager,
  validate({ body: createLateFeeSchema }),
  receivableController.createLateFee,
);
router.get(
  '/late-fees/:id',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.getLateFee,
);
router.post(
  '/late-fees/:id/void',
  manager,
  validate({ params: idParamSchema, body: voidSchema }),
  receivableController.voidLateFee,
);

router.post(
  '/credit-notes',
  manager,
  validate({ body: createCreditNoteSchema }),
  receivableController.createCreditNote,
);
router.get(
  '/credit-notes/:id',
  cashier,
  validate({ params: idParamSchema }),
  receivableController.getCreditNote,
);

// PDF + ส่งอีเมลของเอกสารลูกหนี้ทุกชนิด (docs/tickets/23-document-pdf-email.md) — ใครดูเอกสารได้ก็
// ดาวน์โหลด/ส่งให้ลูกค้าได้ (ทุกครั้งที่ส่งถูก audit log พร้อมอีเมลผู้รับ)
const DOCUMENT_PATHS = [
  ['billing-notes', 'billing_note'],
  ['receipts', 'receipt'],
  ['credit-notes', 'credit_note'],
  ['late-fees', 'late_fee'],
];
for (const [path, kind] of DOCUMENT_PATHS) {
  router.get(
    `/${path}/:id/pdf`,
    cashier,
    validate({ params: idParamSchema }),
    receivableController.documentPdf(kind),
  );
  router.post(
    `/${path}/:id/email`,
    cashier,
    validate({ params: idParamSchema, body: emailDocumentSchema }),
    receivableController.emailDocument(kind),
  );
}

export default router;
