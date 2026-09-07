import { toBaht } from '../../core/money.js';
import { reportRepository } from './report.repository.js';

const today = () => new Date().toISOString().slice(0, 10);

export const reportService = {
  summary({ from, to } = {}) {
    const start = from ?? today();
    const end = to ?? start;

    const summary = reportRepository.salesSummary(start, end);
    const orderCount = summary.order_count;

    return {
      range: { from: start, to: end },
      orderCount,
      guestCount: summary.guests,
      subtotal: toBaht(summary.subtotal),
      discount: toBaht(summary.discount),
      serviceCharge: toBaht(summary.service_charge),
      vat: toBaht(summary.vat),
      netSales: toBaht(summary.total),
      averagePerOrder: orderCount > 0 ? toBaht(Math.round(summary.total / orderCount)) : 0,
      averagePerGuest: summary.guests > 0 ? toBaht(Math.round(summary.total / summary.guests)) : 0,
      paymentMethods: reportRepository.byPaymentMethod(start, end).map((row) => ({
        method: row.method,
        count: row.count,
        amount: toBaht(row.amount),
      })),
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
};

export default reportService;
