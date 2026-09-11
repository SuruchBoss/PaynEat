// PaynEat POS — original project by SuruchBoss (https://github.com/SuruchBoss/PaynEat)
// Licensed under Apache License 2.0 — see LICENSE and NOTICE at repo root
import http from 'node:http';
import { env } from './config/env.js';
import { createApp } from './app.js';
import { migrate } from './db/migrate.js';
import { seed } from './db/seed.js';
import { initSocket } from './realtime/socket.js';
import { closeDb } from './db/index.js';

migrate();
if (process.env.AUTO_SEED !== 'false') seed();

const app = createApp();
const server = http.createServer(app);
initSocket(server);

server.listen(env.port, env.host, () => {
  console.log(`
🍽️  PaynEat POS API
   ▸ REST      : http://localhost:${env.port}/api/v1
   ▸ Docs      : http://localhost:${env.port}/docs
   ▸ Health    : http://localhost:${env.port}/health
   ▸ Realtime  : ws://localhost:${env.port} (socket.io)
   ▸ Database  : ${env.databaseFile}
   ▸ Env       : ${env.nodeEnv}
`);
});

const shutdown = (signal) => {
  console.log(`\n${signal} received — กำลังปิดเซิร์ฟเวอร์...`);
  server.close(() => {
    closeDb();
    process.exit(0);
  });
};

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
