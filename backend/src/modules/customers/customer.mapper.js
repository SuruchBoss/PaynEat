export const toCustomerDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    phone: row.phone,
    email: row.email,
    pointsBalance: row.points_balance,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export default toCustomerDto;
