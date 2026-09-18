import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { branchController } from './branch.controller.js';
import { createBranchSchema, updateBranchSchema, idParamSchema } from './branch.schema.js';

const router = Router();
const admin = authorize('admin');

// สาขาที่ user คนนี้เข้าถึงได้ — ใช้ตอน login (เลือกสาขา) และหน้าสลับสาขา ไม่จำกัด role
// (ทุกคนต้องเรียกได้ ไม่ใช่แค่ admin) และไม่ต้องพึ่ง branchId ของ token (เรียกได้แม้ยังไม่ได้เลือก
// สาขาเลย — ดู docs/DECISIONS.md #36)
router.get('/mine', authenticate, branchController.mine);

// จัดการสาขา — admin เท่านั้น (ดู docs/DECISIONS.md #36: ยังไม่มีหน้าจัดการสาขาใน Flutter ตอนนี้
// endpoint พวกนี้เผื่อไว้สำหรับอนาคต ข้อมูลจริงตอนนี้มาจาก seed เท่านั้น)
router.get('/', authenticate, admin, branchController.list);
router.get('/:id', authenticate, admin, validate({ params: idParamSchema }), branchController.detail);
router.post('/', authenticate, admin, validate({ body: createBranchSchema }), branchController.create);
router.patch(
  '/:id',
  authenticate,
  admin,
  validate({ params: idParamSchema, body: updateBranchSchema }),
  branchController.update,
);

export default router;
