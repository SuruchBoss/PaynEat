import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';
import { env } from '../config/env.js';

let instance = null;

/**
 * เปิดการเชื่อมต่อ SQLite แบบ singleton
 * - WAL mode เพื่อให้อ่าน/เขียนพร้อมกันได้ (POS มีหลายเครื่องยิงเข้ามา)
 * - foreign_keys = ON เพื่อให้ constraint ทำงานจริง
 */
export const getDb = () => {
  if (instance) return instance;

  if (env.databaseFile !== ':memory:') {
    fs.mkdirSync(path.dirname(env.databaseFile), { recursive: true });
  }

  instance = new Database(env.databaseFile);
  instance.pragma('journal_mode = WAL');
  instance.pragma('foreign_keys = ON');
  return instance;
};

export const closeDb = () => {
  if (instance) {
    instance.close();
    instance = null;
  }
};

/** ห่อหลาย statement ให้อยู่ใน transaction เดียว */
export const transaction = (fn) => getDb().transaction(fn);

export default getDb;
