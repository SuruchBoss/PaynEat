import { chromium } from 'playwright';
import fs from 'node:fs';

const [, , htmlPath, outDir, secondsArg] = process.argv;
const seconds = Number(secondsArg || 101);

fs.mkdirSync(outDir, { recursive: true });

// ใช้ Chromium ที่ Playwright ติดตั้งไว้เป็นค่าเริ่มต้น
// ตั้ง CHROMIUM_PATH ได้ถ้าอยากชี้ไปที่ไบนารีอื่น
const executablePath = process.env.CHROMIUM_PATH;
const browser = await chromium.launch({
  ...(executablePath && fs.existsSync(executablePath) ? { executablePath } : {}),
  args: ['--no-sandbox', '--force-device-scale-factor=1', '--hide-scrollbars'],
});

const tContext = Date.now();
const context = await browser.newContext({
  viewport: { width: 1920, height: 1080 },
  recordVideo: { dir: outDir, size: { width: 1920, height: 1080 } },
});

const page = await context.newPage();
await page.goto('file://' + htmlPath, { waitUntil: 'networkidle' });

// หยุดแอนิเมชันไว้ก่อน รอฟอนต์และรูปโหลดครบ แล้วค่อยรีเซ็ตเวลาเป็น 0 พร้อมกันทุกตัว
await page.evaluate(() => document.getAnimations().forEach((a) => a.pause()));
await page.evaluate(() => document.fonts.ready);
await page.evaluate(() =>
  Promise.all([...document.images].map((i) => (i.complete ? null : i.decode().catch(() => null)))),
);
await page.waitForTimeout(1500);

const t0 = Date.now();
const leadSeconds = (t0 - tContext) / 1000;
await page.evaluate(() => {
  document.getAnimations().forEach((a) => {
    a.currentTime = 0;
    a.play();
  });
});

await page.waitForTimeout(seconds * 1000);
console.log('played for', ((Date.now() - t0) / 1000).toFixed(1), 's');

await page.close();
await context.close();
await browser.close();

const file = fs.readdirSync(outDir).filter((f) => f.endsWith('.webm')).pop();
fs.writeFileSync(`${outDir}/lead.json`, JSON.stringify({ leadSeconds, file }, null, 2));
console.log('lead:', leadSeconds.toFixed(2), 's');
console.log('video:', `${outDir}/${file}`);
