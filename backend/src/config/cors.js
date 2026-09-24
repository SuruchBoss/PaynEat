/**
 * แปลง CORS_ORIGIN (คั่นหลายค่าด้วย ,) เป็นค่า `origin` ของแพ็กเกจ cors และ socket.io
 *
 * `*` ต้องส่งเป็น string ตรง ๆ แพ็กเกจ cors ถึงจะตอบ `Access-Control-Allow-Origin: *` — ถ้าส่งเป็น array
 * `['*']` มันเทียบแบบ exact-string กับ origin จริงของเบราว์เซอร์ (เช่น http://localhost:8080) ซึ่งไม่มีวัน
 * ตรง จึงปิด cross-origin ทั้งหมดเงียบ ๆ เดิมแก้แค่กรณีไม่ตั้งค่า (security review #6) แต่ `.env.example`
 * กับ docker-compose ตั้ง `CORS_ORIGIN=*` ไว้ตรง ๆ แอปเว็บที่รันคนละพอร์ตกับ API จึงล็อกอินไม่ได้
 */
export const parseCorsOrigin = (raw) => {
  const origins = (raw ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  if (origins.length === 0 || origins.includes('*')) return '*';
  return origins;
};

export default parseCorsOrigin;
