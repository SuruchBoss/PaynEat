import { toBaht } from '../../core/money.js';

export const toShiftDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    status: row.status,
    openedBy: row.opened_by,
    openedByName: row.opened_by_name,
    openedAt: row.opened_at,
    openingCash: toBaht(row.opening_cash),
    closedBy: row.closed_by,
    closedByName: row.closed_by_name,
    closedAt: row.closed_at,
    expectedCash: row.expected_cash === null ? null : toBaht(row.expected_cash),
    countedCash: row.counted_cash === null ? null : toBaht(row.counted_cash),
    variance: row.variance === null ? null : toBaht(row.variance),
    note: row.note,
  };
};

export default toShiftDto;
