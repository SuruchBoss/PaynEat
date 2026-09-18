import { asyncHandler } from '../../core/asyncHandler.js';
import { ok } from '../../core/response.js';
import { aiAssistantService } from './ai-assistant.service.js';

export const aiAssistantController = {
  ask: asyncHandler(async (req, res) => {
    const { question } = req.validated.body;
    const result = await aiAssistantService.ask(req.user, question);
    return ok(res, result);
  }),
};

export default aiAssistantController;
