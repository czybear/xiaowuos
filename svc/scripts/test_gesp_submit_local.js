const { chromium } = require("playwright");

const baseUrl = process.env.GESP_LOCAL_URL || "http://127.0.0.1:8765/gesp/mock";

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function main() {
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 960 },
    locale: "zh-CN",
  });

  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.getByRole("button", { name: "登入" }).click();
  await page.waitForTimeout(600);
  await page.locator("[data-code-problem='program1']").click();
  await page.waitForTimeout(600);

  const code = `#include <bits/stdc++.h>
using namespace std;

int main() {
    int t;
    cin >> t;
    while (t--) {
        long long a;
        cin >> a;
        long long b = sqrt(sqrt((long double)a));
        while (b * b * b * b < a) b++;
        while (b > 0 && b * b * b * b > a) b--;
        if (b > 0 && b * b * b * b == a) cout << b << "\\n";
        else cout << -1 << "\\n";
    }
    return 0;
}`;
  await page.locator("#officialCodeEditor").fill(code);
  await page.getByRole("button", { name: "递交评测" }).click();
  await page.waitForTimeout(600);

  const bodyAfterSubmit = await page.locator("body").innerText();
  assert(bodyAfterSubmit.includes("递交完成：答案正确"), "提交后当前页面没有显示答案正确反馈");
  assert(bodyAfterSubmit.includes("#891300"), "提交后递交历史没有新增本地提交编号");
  assert(bodyAfterSubmit.includes("测试点"), "提交后没有显示测试点明细");
  assert(bodyAfterSubmit.includes("AC"), "提交后没有显示 AC 测试点结果");

  await page.getByRole("button", { name: "提交状态" }).click();
  await page.waitForTimeout(600);
  const submissionText = await page.locator("body").innerText();
  assert(submissionText.includes("891300"), "提交状态页没有新增提交记录");
  assert(submissionText.includes("答案正确"), "提交状态页没有显示评测结果");

  await page.getByRole("button", { name: "得分情况" }).click();
  await page.waitForTimeout(600);
  const scoreText = await page.locator("body").innerText();
  assert(scoreText.includes("编程题1"), "得分情况页没有编程题1");
  assert(scoreText.includes("25"), "得分情况页没有显示编程题得分");

  await browser.close();
  console.log("GESP local submit flow passed");
}

main().catch(async (error) => {
  console.error(error);
  process.exit(1);
});
