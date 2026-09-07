import { ApiError } from '../../core/ApiError.js';
import { toSatang } from '../../core/money.js';
import { getDb } from '../../db/index.js';
import { emit, EVENTS, ROOMS } from '../../realtime/socket.js';
import { menuRepository } from '../menu/menu.repository.js';
import { tableRepository } from '../tables/table.repository.js';
import { settingsService } from '../settings/settings.service.js';
import { orderRepository } from './order.repository.js';
import { calculateBill } from './order.calculator.js';
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

/** คำนวณยอดใหม่ทั้งบิลแล้วบันทึกลงฐานข้อมูล */
const recalculate = (orderId) => {
  const order = orderRepository.findById(orderId);
  const items = orderRepository.findItems(orderId);
  const settings = settingsService.get();

  const totals = calculateBill({
    items,
    discountType: order.discount_type,
    discountValue: order.discount_value,
    vatRate: settings.vatRate,
    serviceChargeRate: settings.serviceChargeRate,
    vatIncluded: settings.vatIncluded,
  });

  orderRepository.updateTotals(orderId, totals);
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
      for (const item of itemRows) orderRepository.addItem(order.id, item);
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
    orderRepository.updateItem(itemId, {
      quantity,
      note: payload.note,
      lineTotal: (item.unit_price + item.options_price) * quantity,
    });

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

    orderRepository.removeItem(itemId);
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

    orderRepository.updateItem(itemId, { status });
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

    if (order.status === 'open') orderRepository.updateStatus(order.id, 'in_kitchen');

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
      serviceCharge: order.service_charge,
      vat: order.vat,
      total: order.total,
    });

    const dto = buildDto(recalculate(order.id));
    emit(EVENTS.ORDER_UPDATED, dto);
    return dto;
  },

  cancel(orderId, reason) {
    const order = loadOrder(orderId);
    if (order.status === 'paid') throw ApiError.conflict('ออเดอร์ที่ชำระเงินแล้วยกเลิกไม่ได้');
    if (order.status === 'cancelled') throw ApiError.conflict('ออเดอร์นี้ถูกยกเลิกไปแล้ว');

    const run = getDb().transaction(() => {
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
