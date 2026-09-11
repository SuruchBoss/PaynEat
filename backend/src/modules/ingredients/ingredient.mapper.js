export const toIngredientDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    unit: row.unit,
    currentStock: row.current_stock,
    lowStockThreshold: row.low_stock_threshold,
    isLowStock: row.current_stock <= row.low_stock_threshold,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export default toIngredientDto;
