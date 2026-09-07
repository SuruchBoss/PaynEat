/**
 * ห่อ async controller เพื่อส่ง error เข้า error middleware โดยไม่ต้องเขียน try/catch ซ้ำ
 */
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

export default asyncHandler;
