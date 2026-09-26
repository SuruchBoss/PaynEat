// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

import { asyncHandler } from '../../core/asyncHandler.js';
import { ok, created, noContent } from '../../core/response.js';
import { promotionService } from './promotion.service.js';

export const promotionController = {
  list: asyncHandler(async (req, res) =>
    ok(res, promotionService.list(req.validated?.query ?? {})),
  ),
  detail: asyncHandler(async (req, res) =>
    ok(res, promotionService.getById(req.validated.params.id)),
  ),
  create: asyncHandler(async (req, res) =>
    created(res, promotionService.create(req.body, req.user)),
  ),
  update: asyncHandler(async (req, res) =>
    ok(res, promotionService.update(req.validated.params.id, req.body, req.user)),
  ),
  remove: asyncHandler(async (req, res) => {
    promotionService.remove(req.validated.params.id, req.user);
    return noContent(res);
  }),
};

export default promotionController;
