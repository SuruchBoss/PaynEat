// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { Router } from 'express';
import { authenticate, authorize } from '../../middlewares/auth.js';
import { validate } from '../../middlewares/validate.js';
import { aiAssistantController } from './ai-assistant.controller.js';
import { askQuestionSchema } from './ai-assistant.schema.js';

const router = Router();
router.use(authenticate, authorize('admin', 'manager'));

router.post('/ask', validate({ body: askQuestionSchema }), aiAssistantController.ask);

export default router;
