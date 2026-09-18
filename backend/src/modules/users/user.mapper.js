// branch: สาขาที่ "กำลังทำงานอยู่" ของ session/token นี้ (ดู docs/DECISIONS.md #36) — เป็น context
// ของ token ไม่ใช่ property ถาวรของ user (user คนเดียวมีได้หลายสาขา) จึงต้องส่งเข้ามาจาก caller เอง
// เสมอ ไม่ query จาก row ตรงๆ — null ได้ทั้งตอนที่ยังไม่รู้ (เช่น GET /users list ทั้งบริษัท) และ
// ตอน admin เลือกโหมด "ทุกสาขา"
export const toUserDto = (row, branch = null) => {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    username: row.username,
    role: row.role,
    isActive: Boolean(row.is_active),
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    branchId: branch?.id ?? null,
    branchName: branch?.name ?? null,
  };
};

export default toUserDto;
