/**
 * รูปแบบ response กลางของ API — ฝั่ง Flutter map เข้ากับ ApiResponse<T> ตรง ๆ
 */
export const ok = (res, data, meta) => res.status(200).json({ success: true, data, meta });

export const created = (res, data) => res.status(201).json({ success: true, data });

export const noContent = (res) => res.status(204).send();

export const paginated = (res, items, { page, limit, total }) =>
  res.status(200).json({
    success: true,
    data: items,
    meta: {
      page,
      limit,
      total,
      totalPages: limit > 0 ? Math.ceil(total / limit) : 0,
    },
  });
