import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { customerController } from './customer.controller.js';
import { createCustomerSchema, listCustomerQuerySchema, idParamSchema } from './customer.schema.js';

const router = Router();
router.use(authenticate);

// เข้าถึงได้ทุกบทบาทที่รับออเดอร์/เก็บเงิน — ต้องค้นหา/สร้างลูกค้าได้ตอนเปิดออเดอร์หรือเช็คบิล
const service = authorize('admin', 'manager', 'waiter', 'cashier');

router.get('/', service, validate({ query: listCustomerQuerySchema }), customerController.list);
router.get('/:id', service, validate({ params: idParamSchema }), customerController.detail);
router.post('/', service, validate({ body: createCustomerSchema }), customerController.create);

export default router;
