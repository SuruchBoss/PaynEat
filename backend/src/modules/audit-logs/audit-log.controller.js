import { asyncHandler } from '../../core/asyncHandler.js';
import { paginated } from '../../core/response.js';
import { auditLogService } from './audit-log.service.js';

export const auditLogController = {
  list: asyncHandler(async (req, res) => {
    const query = req.validated.query;
    const { items, total } = auditLogService.list(query);
    return paginated(res, items, { page: query.page, limit: query.limit, total });
  }),
};

export default auditLogController;
