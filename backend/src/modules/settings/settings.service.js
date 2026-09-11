import { env } from '../../config/env.js';
import { settingsRepository } from './settings.repository.js';

const NUMBER_KEYS = new Set(['vat_rate', 'service_charge_rate']);
const BOOLEAN_KEYS = new Set(['vat_included']);

export const settingsService = {
  /** โครงสร้างที่ฝั่ง client ใช้ได้ทันที (ค่า default มาจาก .env ถ้ายังไม่เคยตั้ง) */
  get() {
    const raw = Object.fromEntries(settingsRepository.all().map((row) => [row.key, row.value]));
    return {
      storeName: raw.store_name ?? env.store.name,
      currency: raw.currency ?? env.store.currency,
      vatRate: Number(raw.vat_rate ?? env.store.vatRate),
      serviceChargeRate: Number(raw.service_charge_rate ?? env.store.serviceChargeRate),
      vatIncluded: (raw.vat_included ?? String(env.store.vatIncluded)) === 'true',
      // ข้อมูลร้านสำหรับออกใบกำกับภาษี (ดู docs/tickets/07-tax-invoice.md) — ไม่มีค่า default
      // จาก .env เพราะร้านที่ไม่ได้จด VAT ไม่จำเป็นต้องมี ปล่อยว่างได้จนกว่าจะตั้งค่าเอง
      storeTaxId: raw.store_tax_id ?? null,
      storeAddress: raw.store_address ?? null,
      storeBranch: raw.store_branch ?? null,
    };
  },

  update(payload) {
    const map = {
      storeName: 'store_name',
      currency: 'currency',
      vatRate: 'vat_rate',
      serviceChargeRate: 'service_charge_rate',
      vatIncluded: 'vat_included',
      storeTaxId: 'store_tax_id',
      storeAddress: 'store_address',
      storeBranch: 'store_branch',
    };
    for (const [field, key] of Object.entries(map)) {
      if (payload[field] === undefined) continue;
      const value =
        NUMBER_KEYS.has(key) || BOOLEAN_KEYS.has(key) ? String(payload[field]) : payload[field];
      settingsRepository.set(key, value);
    }
    return this.get();
  },
};

export default settingsService;
