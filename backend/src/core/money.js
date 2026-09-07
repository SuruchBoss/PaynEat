/**
 * ตัวช่วยเรื่องเงิน — เก็บเป็น "สตางค์" (integer) เสมอเพื่อเลี่ยงปัญหา floating point
 */
export const toSatang = (amount) => Math.round(Number(amount) * 100);

export const toBaht = (satang) => Number((Number(satang) / 100).toFixed(2));

export const percentOf = (satang, rate) => Math.round(Number(satang) * Number(rate));

export const sum = (values) => values.reduce((acc, value) => acc + Number(value), 0);
