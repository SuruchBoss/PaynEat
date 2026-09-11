import { ApiError } from '../../core/ApiError.js';
import { toSatang } from '../../core/money.js';
import { getDb } from '../../db/index.js';
import { categoryRepository } from '../categories/category.repository.js';
import { ingredientRepository } from '../ingredients/ingredient.repository.js';
import { menuRepository } from './menu.repository.js';
import { toMenuItemDto } from './menu.mapper.js';

const assertCategoryExists = (categoryId) => {
  if (categoryId === undefined) return;
  if (!categoryRepository.findById(categoryId)) {
    throw ApiError.badRequest('ไม่พบหมวดหมู่ที่ระบุ');
  }
};

const assertIngredientsExist = (ingredients) => {
  if (!ingredients?.length) return;
  for (const link of ingredients) {
    if (!ingredientRepository.findById(link.ingredientId)) {
      throw ApiError.badRequest(`ไม่พบวัตถุดิบ id=${link.ingredientId}`);
    }
  }
};

const saveIngredientLinks = (menuItemId, ingredients) => {
  menuRepository.removeIngredientLinks(menuItemId);
  ingredients.forEach((link) => {
    menuRepository.createIngredientLink(menuItemId, {
      ingredientId: link.ingredientId,
      qtyPerUnit: link.qtyPerUnit,
    });
  });
};

const saveOptionGroups = (menuItemId, optionGroups) => {
  menuRepository.removeOptionGroups(menuItemId);
  optionGroups.forEach((group, groupIndex) => {
    const groupId = menuRepository.createOptionGroup(menuItemId, {
      name: group.name,
      minSelect: group.minSelect,
      maxSelect: group.maxSelect,
      isRequired: group.isRequired,
      sortOrder: groupIndex,
    });
    group.options.forEach((option, optionIndex) => {
      menuRepository.createOption(groupId, {
        name: option.name,
        priceDelta: toSatang(option.priceDelta ?? 0),
        isDefault: option.isDefault,
        sortOrder: optionIndex,
      });
    });
  });
};

export const menuService = {
  list(filters) {
    const { items, total } = menuRepository.findAll(filters);
    const groupsByItem = menuRepository.findOptionGroupsForItems(items.map((item) => item.id));
    const ingredientsByItem = menuRepository.findIngredientLinksForItems(
      items.map((item) => item.id),
    );
    return {
      items: items.map((item) =>
        toMenuItemDto(item, groupsByItem.get(item.id) ?? [], ingredientsByItem.get(item.id) ?? []),
      ),
      total,
    };
  },

  getById(id) {
    const item = menuRepository.findById(id);
    if (!item) throw ApiError.notFound('ไม่พบเมนูนี้');
    return toMenuItemDto(
      item,
      menuRepository.findOptionGroups(id),
      menuRepository.findIngredientLinks(id),
    );
  },

  create(payload) {
    assertCategoryExists(payload.categoryId);
    assertIngredientsExist(payload.ingredients);
    const run = getDb().transaction(() => {
      const created = menuRepository.create({
        ...payload,
        price: toSatang(payload.price),
        imageUrl: payload.imageUrl || null,
      });
      if (payload.optionGroups?.length) {
        saveOptionGroups(created.id, payload.optionGroups);
      }
      if (payload.ingredients?.length) {
        saveIngredientLinks(created.id, payload.ingredients);
      }
      return created.id;
    });
    return this.getById(run());
  },

  update(id, payload) {
    this.getById(id);
    assertCategoryExists(payload.categoryId);
    assertIngredientsExist(payload.ingredients);

    const run = getDb().transaction(() => {
      menuRepository.update(id, {
        ...payload,
        price: payload.price === undefined ? undefined : toSatang(payload.price),
        imageUrl: payload.imageUrl === '' ? null : payload.imageUrl,
        // แก้ isAvailable ผ่านฟอร์มแก้ไขปกติ = พนักงานตั้งใจ override เอง เลยล้างสถานะ
        // "ปิดขายอัตโนมัติเพราะสต๊อกหมด" ทิ้งเหมือนกับตอนกดสลับผ่าน setAvailability
        autoDisabledByStock: payload.isAvailable === undefined ? undefined : false,
      });
      if (payload.optionGroups) {
        saveOptionGroups(id, payload.optionGroups);
      }
      if (payload.ingredients) {
        saveIngredientLinks(id, payload.ingredients);
      }
    });
    run();
    return this.getById(id);
  },

  setAvailability(id, isAvailable) {
    this.getById(id);
    menuRepository.setStockAvailability(id, isAvailable, false);
    return this.getById(id);
  },

  remove(id) {
    this.getById(id);
    const inUse = getDb()
      .prepare(
        `
        SELECT COUNT(*) AS c
          FROM order_items oi
          JOIN orders o ON o.id = oi.order_id
         WHERE oi.menu_item_id = ? AND o.status NOT IN ('paid', 'cancelled')
      `,
      )
      .get(id).c;
    if (inUse > 0) {
      throw ApiError.conflict('ลบไม่ได้ เพราะเมนูนี้อยู่ในออเดอร์ที่ยังไม่ปิด');
    }
    menuRepository.remove(id);
  },
};

export default menuService;
