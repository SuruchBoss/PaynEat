export const toBranchDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    code: row.code,
    address: row.address,
    isActive: Boolean(row.is_active),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export default toBranchDto;
