import { ApiError } from '../../core/ApiError.js';
import { toCsv } from '../../core/csv.js';
import { toBaht } from '../../core/money.js';
import { shiftRepository } from '../shifts/shift.repository.js';
import { toShiftDto } from '../shifts/shift.mapper.js';
import { reportRepository } from './report.repository.js';

const today = () => new Date().toISOString().slice(0, 10);

const paymentMethodsDto = (rows) =>
  rows.map((row) => ({ method: row.method, count: row.count, amount: toBaht(row.amount) }));

export const reportService = {
  summary({ from, to } = {}) {
    const start = from ?? today();
    const end = to ?? start;

    const summary = reportRepository.salesSummary(start, end);
    const orderCount = summary.order_count;
    const refundTotal = reportRepository.refundTotal(start, end);

    return {
      range: { from: start, to: end },
      orderCount,
      guestCount: summary.guests,
      subtotal: toBaht(summary.subtotal),
      // discount = ส่วนลดที่พนักงานกรอกเอง, promotionDiscount = ส่วนลดจากโปรโมชันอัตโนมัติ
      // แยกกันไว้ตั้งแต่ ticket 05 (order.discount_amount / promotion_discount_amount คนละคอลัมน์)
      // แต่ summary เดิมลืมรวม promotionDiscount เข้ามาด้วย — แก้พร้อมกับ Z-report (ticket 12)
      discount: toBaht(summary.discount),
      promotionDiscount: toBaht(summary.promotion_discount),
      totalDiscount: toBaht(summary.discount + summary.promotion_discount),
      serviceCharge: toBaht(summary.service_charge),
      vat: toBaht(summary.vat),
      refundTotal: toBaht(refundTotal),
      netSales: toBaht(summary.total - refundTotal),
      averagePerOrder: orderCount > 0 ? toBaht(Math.round(summary.total / orderCount)) : 0,
      averagePerGuest: summary.guests > 0 ? toBaht(Math.round(summary.total / summary.guests)) : 0,
      paymentMethods: paymentMethodsDto(reportRepository.byPaymentMethod(start, end)),
      categories: reportRepository.byCategory(start, end).map((row) => ({
        category: row.category,
        quantity: row.quantity,
        revenue: toBaht(row.revenue),
      })),
    };
  },

  topItems({ from, to, limit = 10 } = {}) {
    const start = from ?? today();
    const end = to ?? start;
    return reportRepository.topItems(start, end, limit).map((row) => ({
      menuItemId: row.menu_item_id,
      name: row.name,
      quantity: row.quantity,
      revenue: toBaht(row.revenue),
    }));
  },

  salesByDay({ from, to } = {}) {
    const start = from ?? today();
    const end = to ?? start;
    return reportRepository.salesByDay(start, end).map((row) => ({
      day: row.day,
      orderCount: row.order_count,
      total: toBaht(row.total),
    }));
  },

  /** ข้อมูลชุดเดียวสำหรับหน้า Dashboard ของแอดมิน */
  dashboard() {
    const day = today();
    return {
      today: this.summary({ from: day, to: day }),
      hourly: reportRepository.salesByHour(day).map((row) => ({
        hour: Number(row.hour),
        orderCount: row.order_count,
        total: toBaht(row.total),
      })),
      topItems: this.topItems({ from: day, to: day, limit: 5 }),
      live: reportRepository.liveCounters(),
    };
  },

  /** สรุปยอด/ภาษี/ส่วนลด/ช่องทางชำระเงินปิดท้ายกะเดียว พร้อมกระทบยอดเงินสด (ดู
   * docs/tickets/12-report-export.md, docs/tickets/01-shift-cash-reconciliation.md) — คิดจาก
   * ออเดอร์ที่ถูกจ่ายจริงในกะนี้เท่านั้น (ผ่าน payments.shift_id ไม่ใช่วันที่เปิดออเดอร์ เพราะ
   * ออเดอร์อาจเปิดไว้ข้ามกะได้) */
  zReportByShift(shiftId) {
    const shift = shiftRepository.findById(shiftId);
    if (!shift) throw ApiError.notFound('ไม่พบกะนี้');

    const orders = reportRepository.shiftOrdersSummary(shiftId);
    const refundTotal = reportRepository.shiftRefundTotal(shiftId);

    return {
      type: 'shift',
      shift: toShiftDto(shift),
      orderCount: orders.order_count,
      guestCount: orders.guests,
      subtotal: toBaht(orders.subtotal),
      discount: toBaht(orders.discount),
      promotionDiscount: toBaht(orders.promotion_discount),
      totalDiscount: toBaht(orders.discount + orders.promotion_discount),
      serviceCharge: toBaht(orders.service_charge),
      vat: toBaht(orders.vat),
      refundTotal: toBaht(refundTotal),
      netSales: toBaht(orders.total - refundTotal),
      paymentMethods: paymentMethodsDto(reportRepository.byShiftPaymentMethod(shiftId)),
    };
  },

  /** Z-report แบบต่อวัน (รวมทุกกะของวันนั้น) — ไม่มีส่วนกระทบยอดเงินสดเพราะอาจมีหลายกะ/หลาย
   * แคชเชียร์ปะปนกัน (กระทบยอดเงินสดทำได้เฉพาะระดับกะเดียวเท่านั้น ดู zReportByShift) */
  zReportByDate(date) {
    const day = date ?? today();
    return { type: 'date', date: day, ...this.summary({ from: day, to: day }) };
  },

  exportSummaryCsv({ from, to } = {}) {
    const summary = this.summary({ from, to });
    const rows = [
      { label: 'ช่วงวันที่', value: `${summary.range.from} ถึง ${summary.range.to}` },
      { label: 'จำนวนออเดอร์', value: summary.orderCount },
      { label: 'จำนวนลูกค้า', value: summary.guestCount },
      { label: 'ยอดขายก่อนหักส่วนลด (บาท)', value: summary.subtotal },
      { label: 'ส่วนลดที่กรอกเอง (บาท)', value: summary.discount },
      { label: 'ส่วนลดจากโปรโมชัน (บาท)', value: summary.promotionDiscount },
      { label: 'ส่วนลดรวม (บาท)', value: summary.totalDiscount },
      { label: 'ค่าบริการ Service Charge (บาท)', value: summary.serviceCharge },
      { label: 'ภาษีมูลค่าเพิ่ม VAT (บาท)', value: summary.vat },
      { label: 'ยอดคืนเงิน (บาท)', value: summary.refundTotal },
      { label: 'ยอดขายสุทธิ (บาท)', value: summary.netSales },
      ...summary.paymentMethods.map((p) => ({
        label: `ช่องทาง: ${p.method} (${p.count} รายการ, บาท)`,
        value: p.amount,
      })),
    ];
    return toCsv(rows, [
      { label: 'รายการ', value: (r) => r.label },
      { label: 'มูลค่า', value: (r) => r.value },
    ]);
  },

  exportTopItemsCsv({ from, to, limit } = {}) {
    return toCsv(this.topItems({ from, to, limit }), [
      { label: 'เมนู', value: (r) => r.name },
      { label: 'จำนวนที่ขายได้', value: (r) => r.quantity },
      { label: 'รายได้ (บาท)', value: (r) => r.revenue },
    ]);
  },

  exportSalesByDayCsv({ from, to } = {}) {
    return toCsv(this.salesByDay({ from, to }), [
      { label: 'วันที่', value: (r) => r.day },
      { label: 'จำนวนออเดอร์', value: (r) => r.orderCount },
      { label: 'ยอดขายรวม (บาท)', value: (r) => r.total },
    ]);
  },

  _zReportRows(z) {
    const rows = [
      { label: 'ประเภท', value: z.type === 'shift' ? 'รายกะ' : 'รายวัน' },
      z.type === 'shift'
        ? { label: 'กะที่', value: z.shift.id }
        : { label: 'วันที่', value: z.date },
      z.type === 'shift'
        ? { label: 'เปิดกะโดย', value: `${z.shift.openedByName} (${z.shift.openedAt})` }
        : null,
      z.type === 'shift' && z.shift.closedAt
        ? { label: 'ปิดกะโดย', value: `${z.shift.closedByName} (${z.shift.closedAt})` }
        : null,
      { label: 'จำนวนออเดอร์', value: z.orderCount },
      { label: 'จำนวนลูกค้า', value: z.guestCount },
      { label: 'ยอดขายก่อนหักส่วนลด (บาท)', value: z.subtotal },
      { label: 'ส่วนลดที่กรอกเอง (บาท)', value: z.discount },
      { label: 'ส่วนลดจากโปรโมชัน (บาท)', value: z.promotionDiscount },
      { label: 'ส่วนลดรวม (บาท)', value: z.totalDiscount },
      { label: 'ค่าบริการ Service Charge (บาท)', value: z.serviceCharge },
      { label: 'ภาษีมูลค่าเพิ่ม VAT (บาท)', value: z.vat },
      { label: 'ยอดคืนเงิน (บาท)', value: z.refundTotal },
      { label: 'ยอดขายสุทธิ (บาท)', value: z.netSales },
      ...z.paymentMethods.map((p) => ({
        label: `ช่องทาง: ${p.method} (${p.count} รายการ, บาท)`,
        value: p.amount,
      })),
    ];
    if (z.type === 'shift') {
      rows.push(
        { label: 'เงินสดตั้งต้น (บาท)', value: z.shift.openingCash },
        { label: 'เงินสดที่คาดไว้ (บาท)', value: z.shift.expectedCash },
        { label: 'เงินสดที่นับได้จริง (บาท)', value: z.shift.countedCash },
        { label: 'ส่วนต่างเงินสด (บาท)', value: z.shift.variance },
      );
    }
    return rows.filter(Boolean);
  },

  exportZReportCsv(z) {
    return toCsv(this._zReportRows(z), [
      { label: 'รายการ', value: (r) => r.label },
      { label: 'มูลค่า', value: (r) => r.value },
    ]);
  },
};

export default reportService;
