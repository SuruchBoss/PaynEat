import { ApiError } from '../../core/ApiError.js';
import { toSatang, toBaht } from '../../core/money.js';
import { getDb } from '../../db/index.js';
import { emit, EVENTS } from '../../realtime/socket.js';
import { orderRepository } from '../orders/order.repository.js';
import { orderService } from '../orders/order.service.js';
import { calculateItemsShare } from '../orders/order.calculator.js';
import { tableRepository } from '../tables/table.repository.js';
import { settingsService } from '../settings/settings.service.js';
import { shiftRepository } from '../shifts/shift.repository.js';
import { paymentRepository } from './payment.repository.js';
import { refundRepository } from './refund.repository.js';
import { toPaymentDto } from './payment.mapper.js';
import { toRefundDto } from './refund.mapper.js';

/** ตรวจว่ารายการที่เลือกแยกบิลถูกต้อง — อยู่ในออเดอร์จริง ยังไม่ถูกยกเลิก และยังไม่ถูกจ่ายไปก่อนหน้า */
const assertItemsSelectable = (items, itemIds) => {
  const missing = itemIds.find((id) => !items.some((item) => item.id === id));
  if (missing) throw ApiError.badRequest('มีรายการที่ไม่ได้อยู่ในออเดอร์นี้');

  const targeted = items.filter((item) => itemIds.includes(item.id));
  const paidPick = targeted.find((item) => item.is_paid);
  if (paidPick) throw ApiError.conflict(`"${paidPick.name_snapshot}" ถูกจ่ายไปแล้ว`);
  const cancelledPick = targeted.find((item) => item.status === 'cancelled');
  if (cancelledPick) {
    throw ApiError.badRequest(`"${cancelledPick.name_snapshot}" ถูกยกเลิกไปแล้ว เลือกจ่ายไม่ได้`);
  }
};

/** คำนวณยอดที่ต้องจ่ายจากรายการที่เลือก — บังคับให้เท่ายอดคงเหลือพอดีถ้าเป็นรอบสุดท้าย กันเศษสตางค์ตกหล่น */
const computeItemsAmount = (order, items, itemIds, remaining) => {
  const settings = settingsService.get();
  const share = calculateItemsShare({
    items,
    selectedIds: itemIds,
    discountType: order.discount_type,
    discountValue: order.discount_value,
    vatRate: settings.vatRate,
    serviceChargeRate: settings.serviceChargeRate,
    vatIncluded: settings.vatIncluded,
  });
  return {
    amount: share.isLastBatch ? remaining : Math.min(share.total, remaining),
    share,
  };
};

export const paymentService = {
  listByOrder(orderId) {
    return paymentRepository.findByOrder(orderId).map(toPaymentDto);
  },

  /** สรุปยอดค้างชำระของออเดอร์ ใช้เปิดหน้าจ่ายเงิน */
  summary(orderId) {
    const order = orderRepository.findById(orderId);
    if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
    const paid = paymentRepository.totalPaid(orderId);
    return {
      orderId,
      total: toBaht(order.total),
      paid: toBaht(paid),
      remaining: toBaht(Math.max(order.total - paid, 0)),
      payments: this.listByOrder(orderId),
    };
  },

  /** ดูยอดที่ต้องจ่ายล่วงหน้าก่อนแยกบิล โดยยังไม่ตัดจ่ายจริง */
  splitPreview(orderId, itemIds) {
    const order = orderRepository.findById(orderId);
    if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
    if (order.status === 'cancelled') throw ApiError.conflict('ออเดอร์นี้ถูกยกเลิกแล้ว');
    if (order.status === 'paid') throw ApiError.conflict('ออเดอร์นี้ชำระเงินครบแล้ว');

    const items = orderRepository.findItems(order.id);
    assertItemsSelectable(items, itemIds);

    const alreadyPaid = paymentRepository.totalPaid(order.id);
    const remaining = Math.max(order.total - alreadyPaid, 0);
    const { amount, share } = computeItemsAmount(order, items, itemIds, remaining);

    return {
      orderId: order.id,
      itemIds,
      subtotal: toBaht(share.subtotal),
      discountAmount: toBaht(share.discountAmount),
      serviceCharge: toBaht(share.serviceCharge),
      vat: toBaht(share.vat),
      total: toBaht(amount),
      remaining: toBaht(remaining),
      isLastBatch: share.isLastBatch,
    };
  },

  pay(payload, user) {
    const shift = shiftRepository.findOpen();
    if (!shift) throw ApiError.conflict('ต้องเปิดกะก่อนจึงจะรับชำระเงินได้');

    const order = orderRepository.findById(payload.orderId);
    if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
    if (order.status === 'cancelled') throw ApiError.conflict('ออเดอร์นี้ถูกยกเลิกแล้ว');
    if (order.status === 'paid') throw ApiError.conflict('ออเดอร์นี้ชำระเงินครบแล้ว');

    const allItems = orderRepository.findItems(order.id);
    const activeItems = allItems.filter((item) => item.status !== 'cancelled');
    if (activeItems.length === 0) throw ApiError.badRequest('ออเดอร์ยังไม่มีรายการอาหาร');

    const alreadyPaid = paymentRepository.totalPaid(order.id);
    const remaining = order.total - alreadyPaid;

    const itemIds = payload.itemIds?.length ? payload.itemIds : null;
    let amount;
    if (itemIds) {
      assertItemsSelectable(allItems, itemIds);
      amount = computeItemsAmount(order, allItems, itemIds, remaining).amount;
    } else {
      amount = toSatang(payload.amount);
    }

    if (amount > remaining) {
      throw ApiError.badRequest(`ยอดชำระเกินยอดคงเหลือ (คงเหลือ ${toBaht(remaining)} บาท)`);
    }

    const receivedBaht = payload.received ?? toBaht(amount);
    if (payload.method === 'cash' && toSatang(receivedBaht) < amount) {
      throw ApiError.badRequest('เงินที่รับมาต้องไม่น้อยกว่ายอดที่ชำระ');
    }
    const received = payload.method === 'cash' ? toSatang(receivedBaht) : amount;
    const changeAmount = payload.method === 'cash' ? Math.max(received - amount, 0) : 0;
    const isFullyPaid = alreadyPaid + amount >= order.total;

    const run = getDb().transaction(() => {
      const payment = paymentRepository.create({
        orderId: order.id,
        shiftId: shift.id,
        method: payload.method,
        amount,
        received,
        changeAmount,
        reference: payload.reference,
        cashierId: user?.id,
      });

      if (itemIds) orderRepository.markItemsPaid(itemIds);

      if (isFullyPaid) {
        orderRepository.updateStatus(order.id, 'paid', { closedAt: new Date().toISOString() });
        if (order.table_id) tableRepository.setStatus(order.table_id, 'available');
      }
      return payment.id;
    });

    const paymentId = run();
    const result = {
      payment: toPaymentDto(paymentRepository.findById(paymentId)),
      order: orderService.getById(order.id),
      isFullyPaid,
      remaining: toBaht(Math.max(order.total - (alreadyPaid + amount), 0)),
    };

    if (isFullyPaid) {
      emit(EVENTS.ORDER_PAID, result.order);
      if (order.table_id) emit(EVENTS.TABLE_UPDATED, { id: order.table_id, status: 'available' });
    }
    emit(EVENTS.ORDER_UPDATED, result.order);
    return result;
  },

  /** ข้อมูลสำหรับพิมพ์ใบเสร็จ */
  receipt(orderId) {
    const order = orderService.getById(orderId);
    const settings = settingsService.get();
    const payments = this.listByOrder(orderId);
    const refunds = refundRepository.findByOrder(orderId).map(toRefundDto);

    return {
      store: {
        name: settings.storeName,
        currency: settings.currency,
        vatRate: settings.vatRate,
        serviceChargeRate: settings.serviceChargeRate,
      },
      order,
      payments,
      refunds,
      refundedTotal: refunds.reduce((acc, refund) => acc + refund.amount, 0),
      paidAt: order.closedAt,
      changeTotal: payments.reduce((acc, payment) => acc + payment.change, 0),
    };
  },

  /**
   * คืนเงินหลังชำระเงินแล้ว (เต็มจำนวน/บางส่วน) — ผูกกับ payment โดยตรงเพราะออเดอร์
   * เดียวอาจมีหลาย payment (แยกจ่าย) แยกเป็น record ใหม่เสมอเพื่อเก็บ audit trail
   * ไม่แก้ payment เดิมหรือสถานะออเดอร์ — ยอดขายสุทธิหักออกตอนทำรายงานแทน
   */
  refund(paymentId, { amount, reason }, user) {
    const payment = paymentRepository.findById(paymentId);
    if (!payment) throw ApiError.notFound('ไม่พบรายการชำระเงินนี้');

    const amountSatang = toSatang(amount);
    const alreadyRefunded = refundRepository.totalByPayment(paymentId);
    const refundable = payment.amount - alreadyRefunded;
    if (amountSatang > refundable) {
      throw ApiError.badRequest(`คืนเงินเกินยอดที่คืนได้ (คืนได้สูงสุด ${toBaht(refundable)} บาท)`);
    }

    const refund = refundRepository.create({
      paymentId,
      orderId: payment.order_id,
      amount: amountSatang,
      reason,
      refundedBy: user.id,
    });
    const dto = toRefundDto(refund);
    emit(EVENTS.REFUND_CREATED, dto);
    return dto;
  },
};

export default paymentService;
