import { Router } from 'express';
import { z } from 'zod';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { reportController } from './report.controller.js';

const dateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'รูปแบบวันที่ต้องเป็น YYYY-MM-DD')
  .optional();

const rangeQuerySchema = z.object({ from: dateSchema, to: dateSchema });
const topItemQuerySchema = rangeQuerySchema.extend({
  limit: z.coerce.number().int().min(1).max(50).default(10),
});
const zReportDateQuerySchema = z.object({ date: dateSchema });
const shiftIdParamSchema = z.object({ shiftId: z.coerce.number().int().positive() });

const router = Router();
router.use(authenticate, authorize('admin', 'manager', 'cashier'));

router.get('/summary', validate({ query: rangeQuerySchema }), reportController.summary);

router.get('/top-items', validate({ query: topItemQuerySchema }), reportController.topItems);

router.get('/sales-by-day', validate({ query: rangeQuerySchema }), reportController.salesByDay);

router.get('/dashboard', reportController.dashboard);

// export รายงานเป็น CSV ให้ฝ่ายบัญชี (ดู docs/tickets/12-report-export.md) — reuse query schema
// เดิมของแต่ละรายงาน เพราะเนื้อหาตัวเลขต้องตรงกับที่เห็นในแอปเป๊ะ ต่างกันแค่ format ที่ตอบกลับ
router.get(
  '/export/summary',
  validate({ query: rangeQuerySchema }),
  reportController.exportSummary,
);
router.get(
  '/export/top-items',
  validate({ query: topItemQuerySchema }),
  reportController.exportTopItems,
);
router.get(
  '/export/sales-by-day',
  validate({ query: rangeQuerySchema }),
  reportController.exportSalesByDay,
);

// Z-report ปิดกะ/ปิดวัน — ต่อกะมีกระทบยอดเงินสด ต่อวันไม่มี (อาจมีหลายกะ/หลายแคชเชียร์ในวันเดียว)
router.get(
  '/z-report/by-shift/:shiftId',
  validate({ params: shiftIdParamSchema }),
  reportController.zReportByShift,
);
router.get(
  '/z-report/by-date',
  validate({ query: zReportDateQuerySchema }),
  reportController.zReportByDate,
);
router.get(
  '/z-report/by-shift/:shiftId/export',
  validate({ params: shiftIdParamSchema }),
  reportController.exportZReportByShift,
);
router.get(
  '/z-report/by-date/export',
  validate({ query: zReportDateQuerySchema }),
  reportController.exportZReportByDate,
);

export default router;
