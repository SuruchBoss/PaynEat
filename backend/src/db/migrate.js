import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { getDb } from './index.js';
import { env } from '../config/env.js';

const here = path.dirname(fileURLToPath(import.meta.url));

export const migrate = () => {
  const db = getDb();
  const sql = fs.readFileSync(path.join(here, 'schema.sql'), 'utf8');
  db.exec(sql);

  const defaults = {
    store_name: env.store.name,
    currency: env.store.currency,
    vat_rate: String(env.store.vatRate),
    service_charge_rate: String(env.store.serviceChargeRate),
    vat_included: String(env.store.vatIncluded),
  };
  const upsert = db.prepare(
    'INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO NOTHING',
  );
  for (const [key, value] of Object.entries(defaults)) upsert.run(key, value);

  return db;
};

if (import.meta.url === `file://${process.argv[1]}`) {
  migrate();
  console.log(`✅ migrate เสร็จแล้ว → ${env.databaseFile}`);
}

export default migrate;
