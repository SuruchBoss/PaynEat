import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { reportService } from './report.service.js';

const sendCsv = (res, filename, csv) => {
  res.set('Content-Type', 'text/csv; charset=utf-8');
  res.set('Content-Disposition', `attachment; filename="${filename}"`);
  res.send(csv);
};

export const reportController = {
  summary: asyncHandler(async (req, res) => ok(res, reportService.summary(req.validated.query))),
  topItems: asyncHandler(async (req, res) => ok(res, reportService.topItems(req.validated.query))),
  salesByDay: asyncHandler(async (req, res) =>
    ok(res, reportService.salesByDay(req.validated.query)),
  ),
  dashboard: asyncHandler(async (_req, res) => ok(res, reportService.dashboard())),

  exportSummary: asyncHandler(async (req, res) =>
    sendCsv(res, 'sales-summary.csv', reportService.exportSummaryCsv(req.validated.query)),
  ),
  exportTopItems: asyncHandler(async (req, res) =>
    sendCsv(res, 'top-items.csv', reportService.exportTopItemsCsv(req.validated.query)),
  ),
  exportSalesByDay: asyncHandler(async (req, res) =>
    sendCsv(res, 'sales-by-day.csv', reportService.exportSalesByDayCsv(req.validated.query)),
  ),

  zReportByShift: asyncHandler(async (req, res) =>
    ok(res, reportService.zReportByShift(req.validated.params.shiftId)),
  ),
  zReportByDate: asyncHandler(async (req, res) =>
    ok(res, reportService.zReportByDate(req.validated.query.date)),
  ),
  exportZReportByShift: asyncHandler(async (req, res) => {
    const z = reportService.zReportByShift(req.validated.params.shiftId);
    sendCsv(res, `z-report-shift-${z.shift.id}.csv`, reportService.exportZReportCsv(z));
  }),
  exportZReportByDate: asyncHandler(async (req, res) => {
    const z = reportService.zReportByDate(req.validated.query.date);
    sendCsv(res, `z-report-${z.date}.csv`, reportService.exportZReportCsv(z));
  }),
};

export default reportController;
