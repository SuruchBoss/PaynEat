import { Router } from 'express';
import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/users/user.routes.js';
import categoryRoutes from './modules/categories/category.routes.js';
import menuRoutes from './modules/menu/menu.routes.js';
import tableRoutes from './modules/tables/table.routes.js';
import orderRoutes from './modules/orders/order.routes.js';
import paymentRoutes from './modules/payments/payment.routes.js';
import reportRoutes from './modules/reports/report.routes.js';
import settingsRoutes from './modules/settings/settings.routes.js';
import shiftRoutes from './modules/shifts/shift.routes.js';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/categories', categoryRoutes);
router.use('/menu-items', menuRoutes);
router.use('/tables', tableRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/reports', reportRoutes);
router.use('/settings', settingsRoutes);
router.use('/shifts', shiftRoutes);

export default router;
