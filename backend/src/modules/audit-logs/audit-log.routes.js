import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { auditLogController } from './audit-log.controller.js';
import { listAuditLogQuerySchema } from './audit-log.schema.js';

const router = Router();
router.use(authenticate);
router.use(authorize('admin'));

router.get('/', validate({ query: listAuditLogQuerySchema }), auditLogController.list);

export default router;
