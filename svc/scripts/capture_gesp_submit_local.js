const fs = require("fs/promises");
const path = require("path");
const { chromium } = require("playwright");

const outputDir = "/Users/john/xiaowuOS/svc/docs/gesp-local";
const baseUrl = process.env.GESP_LOCAL_URL || "http://127.0.0.1:8765/gesp/mock";

async function capture(page, fileName) {
  const target = path.join(outputDir, fileName);
  await page.screenshot({ path: target, fullPage: true });
  console.log(target);
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 960 }, locale: "zh-CN" });
  await page.goto(baseUrl, { waitUntil: "networkidle" });
  await page.getByRole("button", { name: "登入" }).click();
  await page.waitForTimeout(600);
  await page.locator("[data-code-problem='program1']").click();
  await page.waitForTimeout(600);
  await page.locator("#officialCodeEditor").fill(`#include <bits/stdc++.h>
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
}`);
  await page.getByRole("button", { name: "递交评测" }).click();
  await page.waitForTimeout(600);
  await capture(page, "13-code-submit-feedback.png");
  await page.getByRole("button", { name: "提交状态" }).click();
  await page.waitForTimeout(600);
  await capture(page, "14-code-submit-status-after-judge.png");
  await page.getByRole("button", { name: "得分情况" }).click();
  await page.waitForTimeout(600);
  await capture(page, "15-code-score-after-judge.png");
  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
