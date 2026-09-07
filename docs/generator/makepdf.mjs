import { chromium } from 'playwright';

const [,, htmlPath, pdfPath, footerText] = process.argv;
const footer = footerText || 'PaynEat POS';
const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args: ['--no-sandbox'],
});
const page = await browser.newPage();
page.on('pageerror', e => console.log('PAGEERROR:', e.message));
await page.goto('file://' + htmlPath, { waitUntil: 'networkidle' });
await page.waitForTimeout(1500);
await page.evaluate(() => document.fonts.ready);
await page.pdf({
  path: pdfPath,
  format: 'A4',
  printBackground: true,
  displayHeaderFooter: true,
  headerTemplate: '<div></div>',
  footerTemplate: `<div style="width:100%;font-size:7pt;color:#9CA3AF;padding:0 13mm;
      font-family:sans-serif;display:flex;justify-content:space-between;">
      <span>${footer}</span>
      <span class="pageNumber"></span>
    </div>`,
  margin: { top: '0', bottom: '12mm', left: '0', right: '0' },
});
await browser.close();
console.log('PDF_DONE');
