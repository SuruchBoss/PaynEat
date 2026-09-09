import { ApiError } from '../../core/ApiError.js';
import { toSatang } from '../../core/money.js';
import { emit, EVENTS } from '../../realtime/socket.js';
import { shiftRepository } from './shift.repository.js';
import { toShiftDto } from './shift.mapper.js';

export const shiftService = {
  current() {
    return toShiftDto(shiftRepository.findOpen());
  },

  getById(id) {
    const shift = shiftRepository.findById(id);
    if (!shift) throw ApiError.notFound('ไม่พบกะนี้');
    return toShiftDto(shift);
  },

  list(query) {
    return shiftRepository.list(query).map(toShiftDto);
  },

  open({ openingCash }, user) {
    if (shiftRepository.findOpen()) {
      throw ApiError.conflict('มีกะที่เปิดอยู่แล้ว ต้องปิดกะเดิมก่อนเปิดกะใหม่');
    }
    const shift = shiftRepository.open({ openedBy: user.id, openingCash: toSatang(openingCash) });
    const dto = toShiftDto(shift);
    emit(EVENTS.SHIFT_OPENED, dto);
    return dto;
  },

  close(id, { countedCash, note }, user) {
    const shift = shiftRepository.findById(id);
    if (!shift) throw ApiError.notFound('ไม่พบกะนี้');
    if (shift.status !== 'open') throw ApiError.conflict('กะนี้ปิดไปแล้ว');

    const expectedCash = shift.opening_cash + shiftRepository.cashInDuring(id);
    const counted = toSatang(countedCash);

    const closed = shiftRepository.close(id, {
      closedBy: user.id,
      expectedCash,
      countedCash: counted,
      variance: counted - expectedCash,
      note,
    });
    const dto = toShiftDto(closed);
    emit(EVENTS.SHIFT_CLOSED, dto);
    return dto;
  },
};

export default shiftService;
