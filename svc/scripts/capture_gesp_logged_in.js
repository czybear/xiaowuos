const fs = require("fs/promises");
const path = require("path");
const { chromium } = require("playwright");

const outputDir = "/Users/john/xiaowuOS/svc/docs/gesp-reference";
const codeUsername = process.env.GESP_CODE_USERNAME || "gesp_202606_c1_test_01";
const codePassword = process.env.GESP_CODE_PASSWORD || "bfn27T";
const codeLevel = process.env.GESP_CODE_LEVEL || "1";
const scratchUsername = process.env.GESP_SCRATCH_USERNAME || "062234";
const scratchPassword = process.env.GESP_SCRATCH_PASSWORD || "062234";

async function capture(page, fileName, fullPage = false) {
  const target = path.join(outputDir, fileName);
  await page.screenshot({ path: target, fullPage });
  console.log(target);
}

async function safeGoto(page, url) {
  try {
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 12000 });
  } catch (error) {
    console.log(`goto warning for ${url}: ${error.message}`);
  }
  await page.waitForTimeout(3500);
}

async function textSnapshot(page) {
  return await page.evaluate(() => document.body.innerText.slice(0, 1200));
}

async function loginCodeSystem(context) {
  const page = await context.newPage();
  await safeGoto(page, "https://gesp.trial.thusaac.com/#!/");
  await capture(page, "03-code-before-login.png");

  await page.getByRole("button", { name: "登录考试系统" }).click();
  await page.waitForTimeout(800);
  await page.getByPlaceholder("用户名").fill(codeUsername);
  await page.getByPlaceholder("密码").fill(codePassword);
  await page.getByRole("button", { name: "登入" }).click();
  await page.waitForTimeout(5000);
  await capture(page, "04-code-after-login.png", true);
  console.log(await textSnapshot(page));

  const candidates = ["考试列表", "题目列表", "得分情况"];
  for (const text of candidates) {
    const locator = page.getByText(text, { exact: true });
    if (await locator.count().catch(() => 0)) {
      try {
        await locator.click();
        await page.waitForTimeout(2500);
        await capture(page, `05-code-${text}.png`, true);
      } catch (error) {
        console.log(`click ${text} warning: ${error.message}`);
      }
    }
  }

  const examLink = page.getByText(`CCF GESP 2026年6月认证 C++ ${codeLevel}级 - 环境测试`).first();
  if (await examLink.count().catch(() => 0)) {
    try {
      await examLink.click();
      await page.waitForTimeout(5000);
      await capture(page, "08-code-exam-entry.png", true);
      console.log(await textSnapshot(page));

      const firstProblem = page.getByText(`CCF GESP 模拟测试 C++ ${codeLevel}级 选择题`).first();
      if (await firstProblem.count().catch(() => 0)) {
        await firstProblem.click();
        await page.waitForTimeout(3500);
        await capture(page, "10-code-problem-choice.png", true);
        console.log(await textSnapshot(page));
      }

      await page.goBack().catch(() => {});
      await page.waitForTimeout(1500);
      const programProblem = page.getByText(`CCF GESP 模拟测试 C++ ${codeLevel}级 编程题1`).first();
      if (await programProblem.count().catch(() => 0)) {
        await programProblem.click();
        await page.waitForTimeout(3500);
        await capture(page, "11-code-problem-program.png", true);
        console.log(await textSnapshot(page));
      }

      const statusTab = page.getByText("提交状态", { exact: true }).first();
      if (await statusTab.count().catch(() => 0)) {
        await statusTab.click();
        await page.waitForTimeout(2500);
        await capture(page, "12-code-submit-status.png", true);
      }

      const scoreTab = page.getByText("得分情况", { exact: true }).first();
      if (await scoreTab.count().catch(() => 0)) {
        await scoreTab.click();
        await page.waitForTimeout(2500);
        await capture(page, "13-code-score-status.png", true);
      }
    } catch (error) {
      console.log(`open code exam warning: ${error.message}`);
    }
  }
}

async function loginScratchSystem(context) {
  const page = await context.newPage();
  await safeGoto(page, "https://ccf.scratchoj.com/examv/#/");
  await capture(page, "06-scratch-before-login.png");

  await page.getByPlaceholder("请输入准考证号").fill(scratchUsername);
  await page.getByPlaceholder("请输入身份证号或者护照号后6位").fill(scratchPassword);
  await page.getByRole("button", { name: "考 生 登 录" }).click();
  await page.waitForTimeout(5000);
  await capture(page, "07-scratch-after-login.png", true);
  console.log(await textSnapshot(page));

  const enterButton = page.getByRole("button", { name: "进入考试" });
  if (await enterButton.count().catch(() => 0)) {
    try {
      await enterButton.click();
      await page.waitForTimeout(5000);
      await capture(page, "09-scratch-exam-entry.png", true);
      console.log(await textSnapshot(page));
    } catch (error) {
      console.log(`open scratch exam warning: ${error.message}`);
    }
  }
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 960 },
    deviceScaleFactor: 1,
    locale: "zh-CN",
  });

  await loginCodeSystem(context);
  await loginScratchSystem(context);
  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
