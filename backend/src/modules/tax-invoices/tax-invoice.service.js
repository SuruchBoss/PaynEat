import { ApiError } from '../../core/ApiError.js';
import { getDb } from '../../db/index.js';
import { orderRepository } from '../orders/order.repository.js';
import { settingsService } from '../settings/settings.service.js';
import { taxInvoiceRepository } from './tax-invoice.repository.js';
import { toTaxInvoiceDto } from './tax-invoice.mapper.js';

/**
 * เลขที่ใบกำกับภาษีรูปแบบ INV<ปีพ.ศ. 2 หลัก>-<เลขรัน 6 หลัก> รีเซ็ตทุกปีปฏิทินไทย (พ.ศ.)
 * นับจากใบที่เคยออกทั้งหมดในปีนั้นรวมใบที่ถูกยกเลิกด้วย เพื่อไม่ให้เลขที่ที่เคยออกไปแล้วถูกใช้ซ้ำ
 * (ดู docs/DECISIONS.md #19 — การแบ่งหมวดเลขที่ตามช่วงเวลาทำได้ตามแนวทางกรมสรรพากร ขอแค่ในหมวด
 * เรียงต่อเนื่องไม่ข้าม/ไม่ซ้ำ)
 */
const nextRunningNumber = () => {
  const buddhistYear = new Date().getFullYear() + 543;
  const prefix = `INV${String(buddhistYear).slice(-2)}-`;
  const count = taxInvoiceRepository.countByRunningNumberPrefix(prefix);
  return `${prefix}${String(count + 1).padStart(6, '0')}`;
};

const loadOrder = (orderId) => {
  const order = orderRepository.findById(orderId);
  if (!order) throw ApiError.notFound('ไม่พบออเดอร์นี้');
  return order;
};

export const taxInvoiceService = {
  getActiveByOrder(orderId) {
    loadOrder(orderId);
    const invoice = taxInvoiceRepository.findActiveByOrder(orderId);
    if (!invoice) throw ApiError.notFound('ออเดอร์นี้ยังไม่มีใบกำกับภาษี');
    return toTaxInvoiceDto(invoice);
  },

  issue(orderId, payload, user) {
    const order = loadOrder(orderId);
    if (order.status !== 'paid') {
      throw ApiError.conflict('ออกใบกำกับภาษีได้ก็ต่อเมื่อออเดอร์นี้ชำระเงินครบแล้ว');
    }
    if (taxInvoiceRepository.findActiveByOrder(orderId)) {
      throw ApiError.conflict('ออเดอร์นี้มีใบกำกับภาษีที่ยังไม่ถูกยกเลิกอยู่แล้ว');
    }

    const settings = settingsService.get();
    if (!settings.storeTaxId || !settings.storeAddress) {
      throw ApiError.badRequest(
        'ร้านยังไม่ได้ตั้งค่าเลขประจำตัวผู้เสียภาษี/ที่อยู่ร้าน กรุณาตั้งค่าในหน้า Settings ก่อน',
      );
    }

    const run = getDb().transaction(() =>
      taxInvoiceRepository.create({
        orderId: order.id,
        runningNumber: nextRunningNumber(),
        invoiceType: payload.invoiceType,
        customerName: payload.customerName,
        customerAddress: payload.customerAddress,
        customerTaxId: payload.customerTaxId,
        storeName: settings.storeName,
        storeTaxId: settings.storeTaxId,
        storeAddress: settings.storeAddress,
        storeBranch: settings.storeBranch,
        subtotal: order.subtotal,
        vat: order.vat,
        total: order.total,
        issuedBy: user.id,
      }),
    );
    return toTaxInvoiceDto(run());
  },

  void(orderId, { reason }, user) {
    loadOrder(orderId);
    const invoice = taxInvoiceRepository.findActiveByOrder(orderId);
    if (!invoice) throw ApiError.notFound('ออเดอร์นี้ยังไม่มีใบกำกับภาษีที่ยกเลิกได้');

    return toTaxInvoiceDto(taxInvoiceRepository.void(invoice.id, { reason, voidedBy: user.id }));
  },
};

export default taxInvoiceService;
