import { toBaht } from '../../core/money.js';

export const toCustomerDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    phone: row.phone,
    email: row.email,
    pointsBalance: row.points_balance,
    // ลูกค้าเครดิต (ดู docs/tickets/20-b2b-credit.md) — creditLimit 0 = ขายเชื่อไม่ได้
    creditLimit: toBaht(row.credit_limit ?? 0),
    creditTermDays: row.credit_term_days ?? 30,
    taxId: row.tax_id ?? null,
    address: row.address ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export default toCustomerDto;
