import { ApiError } from '../../core/ApiError.js';
import { toSatang, toBaht } from '../../core/money.js';
import { getDb } from '../../db/index.js';
import { emit, EVENTS } from '../../realtime/socket.js';
import { orderRepository } from '../orders/order.repository.js';
import { orderService } from '../orders/order.service.js';
import { tableRepository } from '../tables/table.repository.js';
import { settingsService } from '../settings/settings.service.js';
import { paymentRepository } from './payment.repository.js';
import { toPaymentDto } from './payment.mapper.js';

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

  pay(payload, user) {
    const order = orderRepository.findById(payload.orderId);
    if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
    if (order.status === 'cancelled') throw ApiError.conflict('ออเดอร์นี้ถูกยกเลิกแล้ว');
    if (order.status === 'paid') throw ApiError.conflict('ออเดอร์นี้ชำระเงินครบแล้ว');

    const items = orderRepository.findItems(order.id).filter((item) => item.status !== 'cancelled');
    if (items.length === 0) throw ApiError.badRequest('ออเดอร์ยังไม่มีรายการอาหาร');

    const alreadyPaid = paymentRepository.totalPaid(order.id);
    const remaining = order.total - alreadyPaid;
    const amount = toSatang(payload.amount);

    if (amount > remaining) {
      throw ApiError.badRequest(`ยอดชำระเกินยอดคงเหลือ (คงเหลือ ${toBaht(remaining)} บาท)`);
    }

    const received =
      payload.method === 'cash' ? toSatang(payload.received ?? payload.amount) : amount;
    const changeAmount = payload.method === 'cash' ? Math.max(received - amount, 0) : 0;
    const isFullyPaid = alreadyPaid + amount >= order.total;

    const run = getDb().transaction(() => {
      const payment = paymentRepository.create({
        orderId: order.id,
        method: payload.method,
        amount,
        received,
        changeAmount,
        reference: payload.reference,
        cashierId: user?.id,
      });

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

    return {
      store: {
        name: settings.storeName,
        currency: settings.currency,
        vatRate: settings.vatRate,
        serviceChargeRate: settings.serviceChargeRate,
      },
      order,
      payments,
      paidAt: order.closedAt,
      changeTotal: payments.reduce((acc, payment) => acc + payment.change, 0),
    };
  },
};

export default paymentService;
