// Copyright 2026 Suruch Chakrapeesirisuk
// SPDX-License-Identifier: Apache-2.0

export const toIngredientDto = (row) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    unit: row.unit,
    currentStock: row.current_stock,
    lowStockThreshold: row.low_stock_threshold,
    isLowStock: row.current_stock <= row.low_stock_threshold,
    branchId: row.branch_id ?? null,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export default toIngredientDto;
