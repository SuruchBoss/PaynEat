import { ApiError } from '../../core/ApiError.js';
import { toSatang } from '../../core/money.js';
import { promotionRepository } from './promotion.repository.js';
import { toPromotionDto } from './promotion.mapper.js';

/** แปลงเงื่อนไข input (บาท) → เก็บเป็นสตางค์ก่อนบันทึกเป็น JSON */
const toConditionsJson = (conditions = {}) =>
  JSON.stringify({
    ...conditions,
    minSubtotal: conditions.minSubtotal ? toSatang(conditions.minSubtotal) : undefined,
  });

/** แปลงค่าส่วนลด input → หน่วยเก็บจริง (percent: basis point, amount: สตางค์, bogo: ไม่ใช้) */
const toStoredValue = (type, value) => {
  if (type === 'percent') return Math.round((value ?? 0) * 100);
  if (type === 'amount') return toSatang(value ?? 0);
  return 0;
};

const assertCodeAvailable = (code, excludeId) => {
  if (!code) return;
  const existing = promotionRepository.findByCode(code);
  if (existing && existing.id !== excludeId) {
    throw ApiError.conflict(`โค้ด "${code}" มีโปรโมชันอื่นใช้อยู่แล้ว`);
  }
};

export const promotionService = {
  list(filters) {
    return promotionRepository.findAll(filters).map(toPromotionDto);
  },

  getById(id) {
    const promotion = promotionRepository.findById(id);
    if (!promotion) throw ApiError.notFound('ไม่พบโปรโมชันนี้');
    return toPromotionDto(promotion);
  },

  create(payload) {
    assertCodeAvailable(payload.code, undefined);
    const created = promotionRepository.create({
      name: payload.name,
      type: payload.type,
      value: toStoredValue(payload.type, payload.value),
      code: payload.code ?? null,
      conditionsJson: toConditionsJson(payload.conditions),
      isActive: payload.isActive,
      validFrom: payload.validFrom ?? null,
      validTo: payload.validTo ?? null,
    });
    return toPromotionDto(created);
  },

  update(id, payload) {
    const existing = promotionRepository.findById(id);
    if (!existing) throw ApiError.notFound('ไม่พบโปรโมชันนี้');

    if (payload.code !== undefined) assertCodeAvailable(payload.code, id);
    const type = payload.type ?? existing.type;

    const updated = promotionRepository.update(id, {
      name: payload.name,
      type: payload.type,
      value: payload.value === undefined ? undefined : toStoredValue(type, payload.value),
      code: payload.code,
      conditionsJson: payload.conditions ? toConditionsJson(payload.conditions) : undefined,
      isActive: payload.isActive,
      validFrom: payload.validFrom,
      validTo: payload.validTo,
    });
    return toPromotionDto(updated);
  },

  remove(id) {
    const existing = promotionRepository.findById(id);
    if (!existing) throw ApiError.notFound('ไม่พบโปรโมชันนี้');
    promotionRepository.remove(id);
  },
};

export default promotionService;
