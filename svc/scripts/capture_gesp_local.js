const fs = require("fs/promises");
const path = require("path");
const { chromium } = require("playwright");

const outputDir = "/Users/john/xiaowuOS/svc/docs/gesp-local";
const baseUrl = process.env.GESP_LOCAL_URL || "http://127.0.0.1:8765/gesp/mock";
const codeUsername = process.env.GESP_CODE_USERNAME || "gesp_202606_c2_test_50";
const codePassword = process.env.GESP_CODE_PASSWORD || "shHLM7";

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

  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await capture(page, "01-code-login.png");

  await page.getByPlaceholder("用户名").fill(codeUsername);
  await page.getByPlaceholder("密码").fill(codePassword);
  await page.getByRole("button", { name: "登入" }).click();
  await page.waitForTimeout(800);
  await capture(page, "02-code-dashboard.png");

  await page.locator("[data-code-problem='choice']").click();
  await page.waitForTimeout(800);
  await capture(page, "03-code-choice-group.png");
  await page.getByRole("button", { name: /A/ }).first().click();
  await page.waitForTimeout(500);
  await capture(page, "07-code-choice-selected.png");
  await page.getByRole("button", { name: "考试列表" }).click();
  await page.waitForTimeout(800);
  await page.locator("[data-code-problem='program1']").click();
  await page.waitForTimeout(800);
  await capture(page, "07-code-program-editor.png");

  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.getByPlaceholder("用户名").fill(codeUsername);
  await page.getByPlaceholder("密码").fill(codePassword);
  await page.getByRole("button", { name: "登入" }).click();
  await page.waitForTimeout(800);
  await page.getByRole("button", { name: "提交状态" }).click();
  await page.waitForTimeout(600);
  await capture(page, "08-code-submit-status.png");
  await page.getByRole("button", { name: "得分情况" }).click();
  await page.waitForTimeout(600);
  await capture(page, "09-code-score-status.png");

  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.getByText("图形化编程模拟系统").click();
  await page.waitForTimeout(500);
  await capture(page, "04-scratch-login.png");

  await page.getByRole("button", { name: "考 生 登 录" }).click();
  await page.waitForTimeout(800);
  await capture(page, "05-scratch-dashboard.png");

  await page.getByRole("button", { name: "进入考试" }).click();
  await page.waitForTimeout(800);
  await capture(page, "06-scratch-resume-modal.png");
  await page.getByRole("button", { name: "继续作答" }).click();
  await page.waitForTimeout(800);
  await capture(page, "10-scratch-notice-page.png");
  await page.getByRole("button", { name: "开始考试" }).click();
  await page.waitForTimeout(800);
  await capture(page, "11-scratch-real-exam.png");
  await page.getByRole("button", { name: "下一题" }).click();
  await page.waitForTimeout(500);
  await capture(page, "12-scratch-next-question.png");

  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
