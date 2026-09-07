import { ApiError } from '../../core/ApiError.js';
import { toSatang } from '../../core/money.js';
import { getDb } from '../../db/index.js';
import { categoryRepository } from '../categories/category.repository.js';
import { menuRepository } from './menu.repository.js';
import { toMenuItemDto } from './menu.mapper.js';

const assertCategoryExists = (categoryId) => {
  if (categoryId === undefined) return;
  if (!categoryRepository.findById(categoryId)) {
    throw ApiError.badRequest('ไม่พบหมวดหมู่ที่ระบุ');
  }
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
    return {
      items: items.map((item) => toMenuItemDto(item, groupsByItem.get(item.id) ?? [])),
      total,
    };
  },

  getById(id) {
    const item = menuRepository.findById(id);
    if (!item) throw ApiError.notFound('ไม่พบเมนูนี้');
    return toMenuItemDto(item, menuRepository.findOptionGroups(id));
  },

  create(payload) {
    assertCategoryExists(payload.categoryId);
    const run = getDb().transaction(() => {
      const created = menuRepository.create({
        ...payload,
        price: toSatang(payload.price),
        imageUrl: payload.imageUrl || null,
      });
      if (payload.optionGroups?.length) {
        saveOptionGroups(created.id, payload.optionGroups);
      }
      return created.id;
    });
    return this.getById(run());
  },

  update(id, payload) {
    this.getById(id);
    assertCategoryExists(payload.categoryId);

    const run = getDb().transaction(() => {
      menuRepository.update(id, {
        ...payload,
        price: payload.price === undefined ? undefined : toSatang(payload.price),
        imageUrl: payload.imageUrl === '' ? null : payload.imageUrl,
      });
      if (payload.optionGroups) {
        saveOptionGroups(id, payload.optionGroups);
      }
    });
    run();
    return this.getById(id);
  },

  setAvailability(id, isAvailable) {
    this.getById(id);
    menuRepository.update(id, { isAvailable });
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
