const fs = require("fs/promises");
const path = require("path");
const { chromium } = require("playwright");

const outputDir = "/Users/john/xiaowuOS/svc/docs/gesp-reference";

async function safeGoto(page, url) {
  try {
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 12000 });
  } catch (error) {
    console.log(`goto warning for ${url}: ${error.message}`);
  }
  await page.waitForTimeout(4000);
}

async function capture(page, fileName, fullPage = false) {
  const target = path.join(outputDir, fileName);
  await page.screenshot({ path: target, fullPage });
  console.log(target);
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 960 },
    deviceScaleFactor: 1,
    locale: "zh-CN",
  });

  const codePage = await context.newPage();
  await safeGoto(codePage, "https://gesp.trial.thusaac.com/#!/");
  await capture(codePage, "01-code-login-viewport.png");
  await capture(codePage, "01-code-login-full.png", true);

  const scratchPage = await context.newPage();
  await safeGoto(scratchPage, "https://ccf.scratchoj.com/examv/#/");
  await capture(scratchPage, "02-scratch-login-viewport.png");
  await capture(scratchPage, "02-scratch-login-full.png", true);

  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
