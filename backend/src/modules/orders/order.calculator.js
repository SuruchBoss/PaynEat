import { percentOf } from '../../core/money.js';

/**
 * คำนวณยอดบิล — ฟังก์ชันบริสุทธิ์ (pure) เพื่อให้เทสต์ได้ง่ายและใช้ซ้ำได้ทั้ง preview/บันทึกจริง
 * ทุกค่าเป็น "สตางค์" (integer)
 *
 * ลำดับการคำนวณตามธรรมเนียมร้านอาหารไทย:
 *   1) ยอดรวมอาหาร (subtotal)
 *   2) หักส่วนลด
 *   3) บวก Service Charge จากยอดหลังหักส่วนลด
 *   4) บวก VAT จาก (ยอดหลังหักส่วนลด + Service Charge)
 *
 * ถ้า vatIncluded = true จะถือว่าราคาที่ตั้งไว้รวม VAT แล้ว
 * ระบบจะแยกส่วน VAT ออกมาแสดงเท่านั้น ไม่บวกเพิ่ม
 */
export const calculateBill = ({
  items = [],
  discountType = 'none',
  discountValue = 0,
  vatRate = 0.07,
  serviceChargeRate = 0.1,
  vatIncluded = false,
}) => {
  const activeItems = items.filter((item) => item.status !== 'cancelled');
  const subtotal = activeItems.reduce(
    (acc, item) => acc + Number(item.line_total ?? item.lineTotal ?? 0),
    0,
  );

  let discountAmount = 0;
  if (discountType === 'amount') {
    discountAmount = Math.min(Math.max(Number(discountValue), 0), subtotal);
  } else if (discountType === 'percent') {
    const percent = Math.min(Math.max(Number(discountValue), 0), 10000); // เก็บเป็น basis point ของ % * 100
    discountAmount = Math.min(Math.round((subtotal * percent) / 10000), subtotal);
  }

  const afterDiscount = subtotal - discountAmount;
  const serviceCharge = percentOf(afterDiscount, serviceChargeRate);

  let vat;
  let total;
  if (vatIncluded) {
    // ราคารวม VAT แล้ว → ถอด VAT ออกมาแสดง (base = total / (1 + rate))
    const gross = afterDiscount + serviceCharge;
    vat = gross - Math.round(gross / (1 + vatRate));
    total = gross;
  } else {
    vat = percentOf(afterDiscount + serviceCharge, vatRate);
    total = afterDiscount + serviceCharge + vat;
  }

  return {
    subtotal,
    discountType,
    discountValue: Number(discountValue) || 0,
    discountAmount,
    serviceCharge,
    vat,
    total,
  };
};

export default calculateBill;
