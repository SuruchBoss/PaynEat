import { ApiError } from '../../core/ApiError.js';
import { menuRepository } from '../menu/menu.repository.js';
import { ingredientRepository } from './ingredient.repository.js';
import { toIngredientDto } from './ingredient.mapper.js';

/**
 * ตัดสินว่าเมนู "สั่งได้" ไหมจากวัตถุดิบที่ผูกไว้ — ต้องเหลือวัตถุดิบพอสำหรับอย่างน้อย 1 ที่
 * (current_stock >= qty_per_unit) ครบทุกตัวที่ผูกไว้ ถ้าไม่ผูกวัตถุดิบเลยถือว่าไม่เกี่ยวกับระบบนี้
 *
 * รับ ingredientId ที่เพิ่งเปลี่ยนสต๊อกมาเป็น list เพื่อ sync เฉพาะเมนูที่อาจได้รับผลกระทบจริง ๆ
 * ไม่ไล่ทุกเมนูในระบบทุกครั้งที่มีการตัด/คืนสต๊อก
 */
const syncMenuItemAvailabilityForIngredients = (ingredientIds) => {
  const menuItemIds = new Set();
  for (const ingredientId of ingredientIds) {
    for (const link of ingredientRepository.findMenuItemLinksForIngredient(ingredientId)) {
      menuItemIds.add(link.menu_item_id);
    }
  }

  for (const menuItemId of menuItemIds) {
    const links = menuRepository.findIngredientLinks(menuItemId);
    if (links.length === 0) continue;

    const ingredients = new Map(
      ingredientRepository
        .findByIds(links.map((link) => link.ingredient_id))
        .map((row) => [row.id, row]),
    );
    const isOrderable = links.every((link) => {
      const ingredient = ingredients.get(link.ingredient_id);
      return ingredient && ingredient.current_stock >= link.qty_per_unit;
    });

    const menuItem = menuRepository.findById(menuItemId);
    if (!menuItem) continue;

    if (!isOrderable && menuItem.is_available) {
      menuRepository.setStockAvailability(menuItemId, false, true);
    } else if (isOrderable && !menuItem.is_available && menuItem.auto_disabled_by_stock) {
      menuRepository.setStockAvailability(menuItemId, true, false);
    }
  }
};

/** หัก/คืนสต๊อกของวัตถุดิบที่ผูกกับเมนูของ order item นี้ ตาม factor × qty_per_unit × quantity */
const applyDeltaForOrderItem = (item, factor) => {
  if (!item.menu_item_id) return;
  const links = menuRepository.findIngredientLinks(item.menu_item_id);
  if (links.length === 0) return;

  for (const link of links) {
    ingredientRepository.adjustStock(
      link.ingredient_id,
      factor * link.qty_per_unit * item.quantity,
    );
  }
  syncMenuItemAvailabilityForIngredients(links.map((link) => link.ingredient_id));
};

export const ingredientService = {
  list(filters) {
    return ingredientRepository.findAll(filters).map(toIngredientDto);
  },

  getById(id) {
    const ingredient = ingredientRepository.findById(id);
    if (!ingredient) throw ApiError.notFound('ไม่พบวัตถุดิบนี้');
    return toIngredientDto(ingredient);
  },

  create(payload) {
    return toIngredientDto(ingredientRepository.create(payload));
  },

  update(id, payload) {
    this.getById(id);
    return toIngredientDto(ingredientRepository.update(id, payload));
  },

  adjustStock(id, delta) {
    this.getById(id);
    ingredientRepository.adjustStock(id, delta);
    syncMenuItemAvailabilityForIngredients([id]);
    return toIngredientDto(ingredientRepository.findById(id));
  },

  remove(id) {
    this.getById(id);
    if (ingredientRepository.countMenuItemLinks(id) > 0) {
      throw ApiError.conflict('ลบไม่ได้ เพราะวัตถุดิบนี้ถูกผูกกับเมนูอยู่');
    }
    ingredientRepository.remove(id);
  },

  /** ตัดสต๊อกตอนรายการอาหารถูกส่งครัว (หรือถูกเพิ่มเข้าออเดอร์ที่ส่งครัวไปแล้ว) */
  deductForOrderItem(item) {
    applyDeltaForOrderItem(item, -1);
  },

  /** คืนสต๊อกตอนยกเลิก/ลบรายการอาหารที่เคยตัดสต๊อกไปแล้ว */
  restoreForOrderItem(item) {
    applyDeltaForOrderItem(item, 1);
  },

  /** ปรับสต๊อกตามส่วนต่างจำนวนที่แก้ไข — ใช้เฉพาะรายการที่ตัดสต๊อกไปแล้วเท่านั้น */
  adjustForQuantityChange(item, oldQuantity, newQuantity) {
    if (!item.menu_item_id || oldQuantity === newQuantity) return;
    const links = menuRepository.findIngredientLinks(item.menu_item_id);
    if (links.length === 0) return;

    const deltaQty = newQuantity - oldQuantity;
    for (const link of links) {
      ingredientRepository.adjustStock(link.ingredient_id, -deltaQty * link.qty_per_unit);
    }
    syncMenuItemAvailabilityForIngredients(links.map((link) => link.ingredient_id));
  },
};

export default ingredientService;
