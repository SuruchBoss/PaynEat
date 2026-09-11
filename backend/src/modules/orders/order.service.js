import { ApiError } from '../../core/ApiError.js';
import { toSatang, toBaht } from '../../core/money.js';
import { getDb } from '../../db/index.js';
import { emit, EVENTS, ROOMS } from '../../realtime/socket.js';
import { menuRepository } from '../menu/menu.repository.js';
import { tableRepository } from '../tables/table.repository.js';
import { settingsService } from '../settings/settings.service.js';
import { promotionRepository } from '../promotions/promotion.repository.js';
import { ingredientService } from '../ingredients/ingredient.service.js';
import { orderRepository } from './order.repository.js';
import { calculateBill } from './order.calculator.js';
import {
  evaluatePromotion,
  findBestAutoPromotion,
  describeIneligibility,
} from './promotion.engine.js';
import { toOrderDto, toOrderItemDto } from './order.mapper.js';

const ITEM_TRANSITIONS = {
  pending: ['cooking', 'ready', 'cancelled'],
  cooking: ['ready', 'cancelled'],
  ready: ['served', 'cancelled'],
  served: [],
  cancelled: [],
};

const MUTABLE_ORDER_STATUSES = ['open', 'in_kitchen', 'served'];

const assertOrderMutable = (order) => {
  if (!MUTABLE_ORDER_STATUSES.includes(order.status)) {
    throw ApiError.conflict('ออเดอร์นี้ปิดแล้ว ไม่สามารถแก้ไขได้');
  }
};

/**
 * แปลง input ของรายการอาหาร → แถวที่พร้อมบันทึก
 * ตรวจว่าเมนูมีอยู่จริง / เปิดขาย / ตัวเลือกเป็นของเมนูนั้นจริง / ครบตามกลุ่มที่บังคับ
 */
const buildItemRow = (input) => {
  const menuItem = menuRepository.findById(input.menuItemId);
  if (!menuItem) throw ApiError.badRequest(`ไม่พบเมนู id=${input.menuItemId}`);
  if (!menuItem.is_available) throw ApiError.conflict(`เมนู "${menuItem.name}" ปิดการขายอยู่`);

  const groups = menuRepository.findOptionGroups(menuItem.id);
  const optionById = new Map();
  for (const group of groups) {
    for (const option of group.options) optionById.set(option.id, { ...option, group });
  }

  const selected = [];
  for (const optionId of input.optionIds ?? []) {
    const option = optionById.get(optionId);
    if (!option) {
      throw ApiError.badRequest(`ตัวเลือก id=${optionId} ไม่ใช่ตัวเลือกของเมนู "${menuItem.name}"`);
    }
    selected.push(option);
  }

  for (const group of groups) {
    const chosen = selected.filter((option) => option.group_id === group.id);
    if (group.is_required && chosen.length < Math.max(group.min_select, 1)) {
      throw ApiError.badRequest(`กรุณาเลือก "${group.name}" ของเมนู "${menuItem.name}"`);
    }
    if (chosen.length > group.max_select) {
      throw ApiError.badRequest(`"${group.name}" เลือกได้สูงสุด ${group.max_select} รายการ`);
    }
  }

  const optionsPrice = selected.reduce((acc, option) => acc + option.price_delta, 0);

  return {
    menuItemId: menuItem.id,
    nameSnapshot: menuItem.name,
    unitPrice: menuItem.price,
    quantity: input.quantity,
    options: selected.map((option) => ({
      id: option.id,
      groupName: option.group.name,
      name: option.name,
      priceDelta: option.price_delta,
    })),
    optionsPrice,
    lineTotal: (menuItem.price + optionsPrice) * input.quantity,
    note: input.note,
  };
};

/**
 * หาโปรโมชันที่ควรใช้กับออเดอร์นี้ตอนนี้ — ประเมินใหม่ทุกครั้งที่ recalculate
 * (ไม่ค้างค่าเดิมไว้) เพื่อไม่ให้โปรโมชันที่หมดเงื่อนไขแล้ว (เช่นลบรายการจนต่ำกว่ายอดขั้นต่ำ)
 * ค้างอยู่ในออเดอร์
 *
 * ถ้าออเดอร์นี้เคยใส่ "โค้ด" ไว้ (promotion_code_snapshot ไม่ว่าง) จะยึดโค้ดนั้นเป็นหลัก
 * ไม่สลับไปใช้โปรโมชันอื่นอัตโนมัติแม้จะให้ส่วนลดมากกว่า — ถ้าโค้ดนั้นหมดเงื่อนไขแล้วจะถูกถอด
 * ออกเฉย ๆ ไม่ auto-fallback ไปใช้ตัวอื่นแทน (ลูกค้าต้องกรอกโค้ดใหม่เอง)
 *
 * ถ้าไม่มีโค้ดผูกไว้ จะหาโปรโมชันแบบไม่ใช้โค้อดที่ให้ส่วนลดมากที่สุดให้อัตโนมัติทุกครั้ง
 */
const resolvePromotionForOrder = (order, items) => {
  const ctx = { items, now: new Date() };

  if (order.promotion_code_snapshot) {
    const promotion = order.promotion_id ? promotionRepository.findById(order.promotion_id) : null;
    const result = promotion ? evaluatePromotion(promotion, ctx) : null;
    if (result) {
      return {
        promotionId: result.promotionId,
        name: result.name,
        code: order.promotion_code_snapshot,
        discountAmount: result.discountAmount,
      };
    }
    return { promotionId: null, name: null, code: null, discountAmount: 0 };
  }

  const best = findBestAutoPromotion(promotionRepository.findActiveForEngine(), ctx);
  return best
    ? {
        promotionId: best.promotionId,
        name: best.name,
        code: null,
        discountAmount: best.discountAmount,
      }
    : { promotionId: null, name: null, code: null, discountAmount: 0 };
};

/** คำนวณยอดใหม่ทั้งบิล (รวมประเมินโปรโมชันใหม่) แล้วบันทึกลงฐานข้อมูล */
const recalculate = (orderId) => {
  const order = orderRepository.findById(orderId);
  const items = orderRepository.findItems(orderId);
  const settings = settingsService.get();
  const promo = resolvePromotionForOrder(order, items);

  const totals = calculateBill({
    items,
    discountType: order.discount_type,
    discountValue: order.discount_value,
    promotionDiscountAmount: promo.discountAmount,
    vatRate: settings.vatRate,
    serviceChargeRate: settings.serviceChargeRate,
    vatIncluded: settings.vatIncluded,
  });

  orderRepository.updateTotals(orderId, {
    ...totals,
    promotionId: promo.promotionId,
    promotionName: promo.name,
    promotionCode: promo.code,
  });
  return orderRepository.findById(orderId);
};

const loadOrder = (id) => {
  const order = orderRepository.findById(id);
  if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
  return order;
};

const buildDto = (orderRow) => toOrderDto(orderRow, orderRepository.findItems(orderRow.id));

export const orderService = {
  list(filters) {
    const query = { ...filters };
    if (query.activeOnly) {
      query.statuses = ['open', 'in_kitchen', 'served'];
      delete query.activeOnly;
    }
    const { rows, total } = orderRepository.findAll(query);
    return { orders: rows.map((row) => buildDto(row)), total };
  },

  getById(id) {
    return buildDto(loadOrder(id));
  },

  getByCode(code) {
    const order = orderRepository.findByCode(code);
    if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
    return buildDto(order);
  },

  getOpenByTable(tableId) {
    const order = orderRepository.findOpenByTable(tableId);
    return order ? buildDto(order) : null;
  },

  create(payload, user) {
    if (payload.tableId) {
      const table = tableRepository.findById(payload.tableId);
      if (!table) throw ApiError.badRequest('ไม่พบโต๊ะที่ระบุ');
      if (orderRepository.findOpenByTable(payload.tableId)) {
        throw ApiError.conflict('โต๊ะนี้มีออเดอร์ที่เปิดอยู่แล้ว กรุณาเพิ่มรายการเข้าออเดอร์เดิม');
      }
    }

    const itemRows = (payload.items ?? []).map(buildItemRow);

    const run = getDb().transaction(() => {
      const order = orderRepository.create({
        code: orderRepository.nextCode(),
        type: payload.type,
        tableId: payload.tableId,
        waiterId: user?.id,
        guestCount: payload.guestCount,
        note: payload.note,
      });
      for (const item of itemRows) orderRepository.addItem(order.id, item);
      if (payload.tableId) tableRepository.setStatus(payload.tableId, 'occupied');
      return order.id;
    });

    const orderId = run();
    const dto = buildDto(recalculate(orderId));
    emit(EVENTS.ORDER_CREATED, dto);
    if (dto.tableId) emit(EVENTS.TABLE_UPDATED, { id: dto.tableId, status: 'occupied' });
    return dto;
  },

  addItems(orderId, items) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    const itemRows = items.map(buildItemRow);
    const run = getDb().transaction(() => {
      for (const item of itemRows) {
        const created = orderRepository.addItem(order.id, item);
        // ออเดอร์ที่ส่งครัวไปแล้ว รายการที่เพิ่มใหม่ถือว่า "ส่งครัว" ทันทีโดยไม่ต้องกดส่งซ้ำ
        // (ดู docs/tickets/06-inventory-stock.md) จึงตัดสต๊อกทันทีตรงนี้ ไม่ต้องรอ sendToKitchen
        if (order.status !== 'open') {
          ingredientService.deductForOrderItem(created);
          orderRepository.updateItem(created.id, { stockDeducted: true });
        }
      }
    });
    run();

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    // ถ้าออเดอร์ถูกส่งครัวไปแล้ว รายการที่เพิ่มใหม่ต้องเด้งเข้าครัวทันที
    if (order.status !== 'open') emit(EVENTS.KITCHEN_TICKET, dto, [ROOMS.KITCHEN]);
    return dto;
  },

  updateItem(orderId, itemId, payload) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    const item = orderRepository.findItemById(itemId);
    if (!item || item.order_id !== order.id) throw ApiError.notFound('ไม่พบรายการนี้ในออเดอร์');
    if (item.status !== 'pending') {
      throw ApiError.conflict('แก้ไขไม่ได้ เพราะครัวเริ่มทำรายการนี้แล้ว');
    }

    const quantity = payload.quantity ?? item.quantity;
    const run = getDb().transaction(() => {
      orderRepository.updateItem(itemId, {
        quantity,
        note: payload.note,
        lineTotal: (item.unit_price + item.options_price) * quantity,
      });
      if (item.stock_deducted) {
        ingredientService.adjustForQuantityChange(item, item.quantity, quantity);
      }
    });
    run();

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  removeItem(orderId, itemId) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    const item = orderRepository.findItemById(itemId);
    if (!item || item.order_id !== order.id) throw ApiError.notFound('ไม่พบรายการนี้ในออเดอร์');
    if (item.status !== 'pending') {
      throw ApiError.conflict('ลบไม่ได้ เพราะครัวเริ่มทำรายการนี้แล้ว กรุณาใช้การยกเลิกรายการแทน');
    }

    const run = getDb().transaction(() => {
      if (item.stock_deducted) ingredientService.restoreForOrderItem(item);
      orderRepository.removeItem(itemId);
    });
    run();
    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  updateItemStatus(orderId, itemId, status, user) {
    const order = loadOrder(orderId);
    const item = orderRepository.findItemById(itemId);
    if (!item || item.order_id !== order.id) throw ApiError.notFound('ไม่พบรายการนี้ในออเดอร์');

    if (!ITEM_TRANSITIONS[item.status].includes(status)) {
      throw ApiError.conflict(`เปลี่ยนสถานะจาก "${item.status}" เป็น "${status}" ไม่ได้`);
    }
    // ยกเลิกรายการที่ครัวลงมือทำแล้ว ต้องเป็นผู้จัดการขึ้นไป (void)
    if (
      status === 'cancelled' &&
      item.status !== 'pending' &&
      !['admin', 'manager'].includes(user.role)
    ) {
      throw ApiError.forbidden('ยกเลิกรายการที่ครัวทำแล้วต้องใช้สิทธิ์ผู้จัดการ');
    }

    const run = getDb().transaction(() => {
      orderRepository.updateItem(itemId, { status });
      if (status === 'cancelled' && item.stock_deducted) {
        ingredientService.restoreForOrderItem(item);
      }
    });
    run();
    recalculate(order.id);

    // ถ้าเสิร์ฟครบทุกรายการแล้ว ให้ออเดอร์ขึ้นสถานะ "เสิร์ฟครบ" อัตโนมัติ
    const items = orderRepository.findItems(order.id);
    const active = items.filter((row) => row.status !== 'cancelled');
    if (
      active.length > 0 &&
      active.every((row) => row.status === 'served') &&
      order.status === 'in_kitchen'
    ) {
      orderRepository.updateStatus(order.id, 'served');
    }

    const dto = buildDto(orderRepository.findById(order.id));
    emit(EVENTS.ORDER_ITEM_UPDATED, {
      orderId: order.id,
      item: toOrderItemDto(orderRepository.findItemById(itemId)),
      order: dto,
    });
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  sendToKitchen(orderId) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    const items = orderRepository.findItems(order.id).filter((item) => item.status !== 'cancelled');
    if (items.length === 0) throw ApiError.badRequest('ออเดอร์ยังไม่มีรายการอาหาร');

    const run = getDb().transaction(() => {
      if (order.status === 'open') orderRepository.updateStatus(order.id, 'in_kitchen');
      // ตัดสต๊อกเฉพาะรายการที่ยังไม่เคยตัด กัน sendToKitchen ที่ถูกเรียกซ้ำ (เช่น มีรายการเพิ่มมาใหม่)
      // ไม่ตัดซ้ำรายการเดิมที่ตัดไปแล้วตั้งแต่รอบก่อน
      for (const item of items) {
        if (!item.stock_deducted) {
          ingredientService.deductForOrderItem(item);
          orderRepository.updateItem(item.id, { stockDeducted: true });
        }
      }
    });
    run();

    const dto = buildDto(orderRepository.findById(order.id));
    emit(EVENTS.KITCHEN_TICKET, dto, [ROOMS.KITCHEN]);
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  updateMeta(orderId, payload) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);
    const dto = buildDto(orderRepository.updateMeta(order.id, payload));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  applyDiscount(orderId, { type, value }) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    // เก็บส่วนลดแบบบาท → สตางค์, แบบเปอร์เซ็นต์ → basis point (5.5% = 550)
    const storedValue = type === 'percent' ? Math.round(value * 100) : toSatang(value);
    if (type === 'percent' && value > 100) throw ApiError.badRequest('ส่วนลดเกิน 100% ไม่ได้');

    orderRepository.updateTotals(order.id, {
      subtotal: order.subtotal,
      discountType: type,
      discountValue: type === 'none' ? 0 : storedValue,
      discountAmount: order.discount_amount,
      promotionId: order.promotion_id,
      promotionName: order.promotion_name_snapshot,
      promotionCode: order.promotion_code_snapshot,
      promotionDiscountAmount: order.promotion_discount_amount,
      serviceCharge: order.service_charge,
      vat: order.vat,
      total: order.total,
    });

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  /** กรอกโค้ดส่วนลด — ถ้าเข้าเงื่อนไขจะผูกไว้กับออเดอร์และคำนวณใหม่ทันที */
  redeemPromotionCode(orderId, code) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    const promotion = promotionRepository.findByCode(code);
    if (!promotion) throw ApiError.notFound('ไม่พบโค้ดส่วนลดนี้');

    const items = orderRepository.findItems(orderId);
    const reason = describeIneligibility(promotion, { items, now: new Date() });
    if (reason) throw ApiError.badRequest(reason);

    orderRepository.updateTotals(order.id, {
      subtotal: order.subtotal,
      discountType: order.discount_type,
      discountValue: order.discount_value,
      discountAmount: order.discount_amount,
      promotionId: promotion.id,
      promotionName: promotion.name,
      promotionCode: promotion.code,
      promotionDiscountAmount: order.promotion_discount_amount,
      serviceCharge: order.service_charge,
      vat: order.vat,
      total: order.total,
    });

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  /** เอาโปรโมชันที่ผูกด้วยโค้ดออก — ถ้ายังเข้าเงื่อนไขโปรโมชันแบบ auto อื่นอยู่ ระบบจะใส่ให้ใหม่เอง */
  removePromotion(orderId) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);

    orderRepository.updateTotals(order.id, {
      subtotal: order.subtotal,
      discountType: order.discount_type,
      discountValue: order.discount_value,
      discountAmount: order.discount_amount,
      promotionId: null,
      promotionName: null,
      promotionCode: null,
      promotionDiscountAmount: 0,
      serviceCharge: order.service_charge,
      vat: order.vat,
      total: order.total,
    });

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  /** โปรโมชันทั้งหมดที่เข้าเงื่อนไขกับบิลนี้ตอนนี้ — ให้ UI แสดง "โปรโมชันที่ใช้ได้ตอนนี้" */
  listEligiblePromotions(orderId) {
    const order = loadOrder(orderId);
    const items = orderRepository.findItems(orderId);
    const ctx = { items, now: new Date() };

    return promotionRepository
      .findActiveForEngine()
      .map((promotion) => {
        const result = evaluatePromotion(promotion, ctx);
        return {
          promotionId: promotion.id,
          name: promotion.name,
          type: promotion.type,
          requiresCode: Boolean(promotion.code),
          isEligibleNow: Boolean(result),
          discountAmountIfApplied: result ? toBaht(result.discountAmount) : 0,
          isCurrentlyApplied: order.promotion_id === promotion.id,
        };
      })
      .filter((entry) => entry.isEligibleNow || entry.isCurrentlyApplied);
  },

  /** ย้ายออเดอร์ (ที่ยังไม่ปิดบิล) ไปโต๊ะอื่น เช่น ลูกค้าขอย้ายที่นั่ง */
  moveTable(orderId, tableId) {
    const order = loadOrder(orderId);
    assertOrderMutable(order);
    if (!order.table_id) throw ApiError.badRequest('ออเดอร์นี้ไม่ได้ผูกกับโต๊ะ ย้ายโต๊ะไม่ได้');
    if (tableId === order.table_id) throw ApiError.badRequest('เลือกโต๊ะเดิม ไม่ต้องย้าย');

    const table = tableRepository.findById(tableId);
    if (!table) throw ApiError.badRequest('ไม่พบโต๊ะที่ระบุ');
    if (orderRepository.findOpenByTable(tableId)) {
      throw ApiError.conflict('โต๊ะปลายทางมีออเดอร์ที่เปิดอยู่แล้ว');
    }

    const oldTableId = order.table_id;
    const run = getDb().transaction(() => {
      orderRepository.updateTable(order.id, tableId);
      tableRepository.setStatus(tableId, 'occupied');
      tableRepository.setStatus(oldTableId, 'available');
    });
    run();

    const dto = buildDto(loadOrder(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    emit(EVENTS.TABLE_UPDATED, { id: tableId, status: 'occupied' });
    emit(EVENTS.TABLE_UPDATED, { id: oldTableId, status: 'available' });
    return dto;
  },

  /** รวมออเดอร์ต้นทางเข้ากับออเดอร์ปลายทาง — ใช้ตอนลูกค้าขอรวมโต๊ะ/รวมบิล */
  mergeOrders(targetOrderId, sourceOrderId) {
    if (targetOrderId === sourceOrderId) {
      throw ApiError.badRequest('เลือกออเดอร์ปลายทางเดียวกับต้นทางไม่ได้');
    }
    const target = loadOrder(targetOrderId);
    const source = loadOrder(sourceOrderId);
    assertOrderMutable(target);
    assertOrderMutable(source);

    const sourceTableId = source.table_id;
    const run = getDb().transaction(() => {
      orderRepository.reassignItems(source.id, target.id);
      orderRepository.updateStatus(source.id, 'cancelled', {
        closedAt: new Date().toISOString(),
        cancelledReason: `รวมเข้ากับบิล #${target.code}`,
      });
      if (sourceTableId) tableRepository.setStatus(sourceTableId, 'available');
    });
    run();

    const dto = buildDto(recalculate(target.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    emit(EVENTS.ORDER_UPDATED, buildDto(loadOrder(source.id)));
    if (sourceTableId) emit(EVENTS.TABLE_UPDATED, { id: sourceTableId, status: 'available' });
    return dto;
  },

  cancel(orderId, reason) {
    const order = loadOrder(orderId);
    if (order.status === 'paid') throw ApiError.conflict('ออเดอร์ที่ชำระเงินแล้วยกเลิกไม่ได้');
    if (order.status === 'cancelled') throw ApiError.conflict('ออเดอร์นี้ถูกยกเลิกไปแล้ว');

    const run = getDb().transaction(() => {
      const items = orderRepository.findItems(order.id);
      for (const item of items) {
        if (item.status !== 'cancelled' && item.stock_deducted) {
          ingredientService.restoreForOrderItem(item);
        }
      }
      for (const status of ['pending', 'cooking', 'ready']) {
        orderRepository.markItemsStatus(order.id, status, 'cancelled');
      }
      orderRepository.updateStatus(order.id, 'cancelled', {
        closedAt: new Date().toISOString(),
        cancelledReason: reason,
      });
      if (order.table_id) tableRepository.setStatus(order.table_id, 'available');
    });
    run();

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    if (order.table_id) emit(EVENTS.TABLE_UPDATED, { id: order.table_id, status: 'available' });
    return dto;
  },

  /** คิวครัว (KDS) — รายการที่ถูกส่งครัวแล้วและยังไม่เสิร์ฟ */
  kitchenQueue(statuses = ['pending', 'cooking', 'ready']) {
    return orderRepository.findItemsByStatuses(statuses).map(toOrderItemDto);
  },

  recalculate,
};

export default orderService;
