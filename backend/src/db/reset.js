import fs from 'node:fs';
import { env } from '../config/env.js';
import { closeDb } from './index.js';
import { migrate } from './migrate.js';
import { seed } from './seed.js';

closeDb();
for (const suffix of ['', '-wal', '-shm']) {
  const file = `${env.databaseFile}${suffix}`;
  if (fs.existsSync(file)) fs.rmSync(file);
}
migrate();
seed();
console.log('♻️  reset ฐานข้อมูลและใส่ข้อมูลตัวอย่างเรียบร้อย');
