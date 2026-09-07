import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { reportService } from './report.service.js';

export const reportController = {
  summary: asyncHandler(async (req, res) => ok(res, reportService.summary(req.validated.query))),
  topItems: asyncHandler(async (req, res) => ok(res, reportService.topItems(req.validated.query))),
  salesByDay: asyncHandler(async (req, res) => ok(res, reportService.salesByDay(req.validated.query))),
  dashboard: asyncHandler(async (_req, res) => ok(res, reportService.dashboard())),
};

export default reportController;
