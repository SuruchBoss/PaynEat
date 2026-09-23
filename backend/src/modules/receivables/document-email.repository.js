import { getDb } from '../../db/index.js';

/** ประวัติการส่งเอกสารลูกหนี้ทางอีเมล (ดู docs/DECISIONS.md #57) — ใครส่ง ส่งถึงใคร เมื่อไร */
export const documentEmailRepository = {
  record({ kind, documentId, toAddress, subject, messageId, sentBy }) {
    const info = getDb()
      .prepare(
        `
        INSERT INTO document_emails (kind, document_id, to_address, subject, message_id, sent_by)
        VALUES (?, ?, ?, ?, ?, ?)
      `,
      )
      .run(kind, documentId, toAddress, subject, messageId ?? null, sentBy);
    return info.lastInsertRowid;
  },

  byDocument(kind, documentId) {
    return getDb()
      .prepare(
        `
        SELECT de.*, u.name AS sent_by_name
          FROM document_emails de
          LEFT JOIN users u ON u.id = de.sent_by
         WHERE de.kind = ? AND de.document_id = ?
         ORDER BY de.id DESC
      `,
      )
      .all(kind, documentId);
  },
};

export default documentEmailRepository;
