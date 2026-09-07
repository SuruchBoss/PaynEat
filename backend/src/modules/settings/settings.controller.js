import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { settingsService } from './settings.service.js';

export const settingsController = {
  get: asyncHandler(async (_req, res) => ok(res, settingsService.get())),
  update: asyncHandler(async (req, res) => ok(res, settingsService.update(req.body))),
};

export default settingsController;
