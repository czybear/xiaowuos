const fs = require("fs/promises");
const path = require("path");
const { chromium } = require("playwright");

const outputDir = "/Users/john/xiaowuOS/svc/docs/gesp-reference";
const username = process.env.GESP_SCRATCH_USERNAME || "062234";
const password = process.env.GESP_SCRATCH_PASSWORD || "062234";

async function capture(page, fileName) {
  const target = path.join(outputDir, fileName);
  await page.screenshot({ path: target, fullPage: true });
  console.log(target);
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 960 },
    deviceScaleFactor: 1,
    locale: "zh-CN",
  });

  await page.goto("https://ccf.scratchoj.com/examv/#/", { waitUntil: "domcontentloaded", timeout: 20000 });
  await page.waitForTimeout(3500);
  await capture(page, "20-scratch-login.png");

  await page.getByPlaceholder("请输入准考证号").fill(username);
  await page.getByPlaceholder("请输入身份证号或者护照号后6位").fill(password);
  await page.getByRole("button", { name: "考 生 登 录" }).click();
  await page.waitForTimeout(5000);
  await capture(page, "21-scratch-dashboard.png");

  await page.getByRole("button", { name: "进入考试" }).click();
  await page.waitForTimeout(6000);
  await capture(page, "22-scratch-enter-modal.png");
  console.log(await page.evaluate(() => document.body.innerText.slice(0, 2000)));

  const startButton = page.getByText(/开始考试|继续作答/).last();
  if (await startButton.count().catch(() => 0)) {
    await startButton.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(6000);
    await capture(page, "23-scratch-after-continue.png");
    console.log(await page.evaluate(() => document.body.innerText.slice(0, 3000)));
  }

  const listButton = page.getByText("列表模式", { exact: true }).first();
  const realStartButton = page.getByText("开始考试", { exact: true }).first();
  if (await realStartButton.count().catch(() => 0)) {
    await realStartButton.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(6000);
    await capture(page, "24-scratch-real-exam.png");
    console.log(await page.evaluate(() => document.body.innerText.slice(0, 3000)));
  }

  const afterStartListButton = page.getByText("列表模式", { exact: true }).first();
  if (await afterStartListButton.count().catch(() => 0)) {
    await afterStartListButton.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(2500);
    await capture(page, "25-scratch-real-list-mode.png");
  }

  const afterStartNextButton = page.getByText("下一题", { exact: true }).first();
  if (await afterStartNextButton.count().catch(() => 0)) {
    await afterStartNextButton.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(2500);
    await capture(page, "26-scratch-real-next-question.png");
  }

  await browser.close();
  return;

  if (await listButton.count().catch(() => 0)) {
    await listButton.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(2500);
    await capture(page, "24-scratch-list-mode.png");
  }

  const nextButton = page.getByText("下一题", { exact: true }).first();
  if (await nextButton.count().catch(() => 0)) {
    await nextButton.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(2500);
    await capture(page, "25-scratch-next-question.png");
  }

  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
