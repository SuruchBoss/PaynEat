import { toBaht } from '../../core/money.js';

const parseConditions = (json) => {
  try {
    return JSON.parse(json || '{}');
  } catch {
    return {};
  }
};

export const toPromotionDto = (row) => {
  if (!row) return null;
  const conditions = parseConditions(row.conditions_json);
  return {
    id: row.id,
    name: row.name,
    type: row.type,
    value: row.type === 'percent' ? row.value / 100 : toBaht(row.value),
    code: row.code,
    conditions: {
      daysOfWeek: conditions.daysOfWeek ?? [],
      startTime: conditions.startTime ?? null,
      endTime: conditions.endTime ?? null,
      categoryIds: conditions.categoryIds ?? [],
      menuItemIds: conditions.menuItemIds ?? [],
      minSubtotal: conditions.minSubtotal ? toBaht(conditions.minSubtotal) : 0,
    },
    isActive: Boolean(row.is_active),
    validFrom: row.valid_from,
    validTo: row.valid_to,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export default toPromotionDto;
