import { ApiError } from '../../core/ApiError.js';
import { resolveBranchIdForWrite } from '../../core/branchScope.js';
import { tableRepository } from './table.repository.js';
import { toTableDto } from './table.mapper.js';
import { emit, EVENTS } from '../../realtime/socket.js';

export const tableService = {
  list(filters, currentBranchId) {
    return tableRepository.findAll({ ...filters, branchId: currentBranchId }).map(toTableDto);
  },

  zones() {
    return tableRepository.zones();
  },

  getById(id) {
    const table = tableRepository.findById(id);
    if (!table) throw ApiError.notFound('ไม่พบโต๊ะนี้');
    return toTableDto(table);
  },

  // ชื่อโต๊ะต้องไม่ซ้ำกันทั้งเชน ไม่ใช่แค่ในสาขาเดียวกัน (name UNIQUE ระดับ SQL คอลัมน์เดียว ยังไม่ได้
  // ทำ composite UNIQUE(name, branch_id) เพราะ SQLite ต้อง recreate ตารางถึงจะแก้ constraint ได้ —
  // ตั้งใจเลื่อนไว้ก่อน ดู docs/DECISIONS.md #36) ตอนนี้ถ้าจะมีหลายสาขาชื่อโต๊ะซ้ำกันต้องตั้งชื่อ
  // แยกกันเอง (เช่นใส่ prefix สาขา) จนกว่าจะแก้ schema
  create(payload, currentBranchId) {
    if (tableRepository.findByName(payload.name)) {
      throw ApiError.conflict('มีโต๊ะชื่อนี้อยู่แล้ว');
    }
    const branchId = resolveBranchIdForWrite(currentBranchId, payload.branchId);
    const table = toTableDto(tableRepository.create({ ...payload, branchId }));
    emit(EVENTS.TABLE_UPDATED, table);
    return table;
  },

  update(id, payload) {
    this.getById(id);
    if (payload.name) {
      const duplicated = tableRepository.findByName(payload.name);
      if (duplicated && duplicated.id !== Number(id)) {
        throw ApiError.conflict('มีโต๊ะชื่อนี้อยู่แล้ว');
      }
    }
    const table = toTableDto(tableRepository.update(id, payload));
    emit(EVENTS.TABLE_UPDATED, table);
    return table;
  },

  setStatus(id, status) {
    this.getById(id);
    if (status === 'available' && tableRepository.hasOpenOrder(id)) {
      throw ApiError.conflict('โต๊ะนี้ยังมีออเดอร์ที่ยังไม่ปิด ไม่สามารถเปลี่ยนเป็นว่างได้');
    }
    const table = toTableDto(tableRepository.setStatus(id, status));
    emit(EVENTS.TABLE_UPDATED, table);
    return table;
  },

  remove(id) {
    this.getById(id);
    if (tableRepository.hasOpenOrder(id)) {
      throw ApiError.conflict('ลบไม่ได้ เพราะโต๊ะนี้ยังมีออเดอร์ที่เปิดอยู่');
    }
    tableRepository.remove(id);
  },
};

export default tableService;
