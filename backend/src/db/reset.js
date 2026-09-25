import fs from 'node:fs';
import { env } from '../config/env.js';
import { closeDb } from './index.js';
import { migrate } from './migrate.js';
import { seed } from './seed.js';
import { logger } from '../core/telemetry/logger.js';

closeDb();
for (const suffix of ['', '-wal', '-shm']) {
  const file = `${env.databaseFile}${suffix}`;
  if (fs.existsSync(file)) fs.rmSync(file);
}
migrate();
seed();
logger.info('Database reset and sample data seeded');
