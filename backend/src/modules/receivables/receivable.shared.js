import { ApiError } from '../../core/ApiError.js';
import { customerRepository } from '../customers/customer.repository.js';
import { toCustomerDto } from '../customers/customer.mapper.js';
import { settingsService } from '../settings/settings.service.js';
import { documentEmailRepository } from './document-email.repository.js';
import { toDocumentEmailDto } from './receivable.mapper.js';
import { receivableRepository } from './receivable.repository.js';

/**
 * ตัวช่วยที่เอกสารลูกหนี้ทุกชนิดใช้ร่วมกัน (ใบวางบิล ใบเสร็จรับชำระ ใบลดหนี้ ใบแจ้งดอกเบี้ย)
 * แยกออกจาก receivable.service.js ให้ service ของเอกสารแต่ละชนิดใช้ได้โดยไม่ต้อง import กันไปมา
 */

/** เลขที่เอกสารรูปแบบเดียวกับใบกำกับภาษี: <prefix><ปี พ.ศ. 2 หลัก>-<เลขรัน 6 หลัก> รีเซ็ตทุกปี
 * นับรวมใบที่ถูกยกเลิก เลขที่ที่เคยออกจึงไม่ถูกใช้ซ้ำ (ดู tax-invoice.service.js) */
export const nextDocumentNo = (table, column, code) => {
  const buddhistYear = new Date().getFullYear() + 543;
  const prefix = `${code}${String(buddhistYear).slice(-2)}-`;
  const count = receivableRepository.countByPrefix(table, column, prefix);
  return `${prefix}${String(count + 1).padStart(6, '0')}`;
};

export const loadCustomer = (customerId) => {
  const customer = customerRepository.findById(customerId);
  if (!customer) throw ApiError.notFound('ไม่พบลูกค้านี้');
  return customer;
};

/** หัวเอกสารใช้ข้อมูลร้าน ณ ตอนพิมพ์ — ต่างจากใบกำกับภาษีที่กฎหมายบังคับ snapshot */
export const storeInfo = () => {
  const settings = settingsService.get();
  return {
    name: settings.storeName,
    taxId: settings.storeTaxId,
    address: settings.storeAddress,
    branch: settings.storeBranch,
  };
};

export const customerInfo = (customerId) => toCustomerDto(customerRepository.findById(customerId));

/** ประวัติการส่งอีเมลของเอกสาร — แนบไปกับ DTO ตัวเต็มของเอกสารทุกชนิด (ไม่แนบในรายการของ statement) */
export const emailHistory = (kind, documentId) =>
  documentEmailRepository.byDocument(kind, documentId).map(toDocumentEmailDto);
