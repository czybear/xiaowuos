const { chromium } = require("playwright");

async function inspect(url) {
  const browser = await chromium.launch({ channel: "chrome", headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 960 }, locale: "zh-CN" });
  try {
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 12000 });
  } catch {}
  await page.waitForTimeout(4000);
  const data = await page.evaluate(() => ({
    title: document.title,
    url: location.href,
    inputs: Array.from(document.querySelectorAll("input")).map((input) => ({
      type: input.type,
      placeholder: input.placeholder,
      name: input.name,
      id: input.id,
      value: input.value,
    })),
    buttons: Array.from(document.querySelectorAll("button")).map((button) => button.innerText.trim()).filter(Boolean).slice(0, 30),
    links: Array.from(document.querySelectorAll("a")).map((a) => ({ text: a.innerText.trim(), href: a.href })).filter((a) => a.text || a.href).slice(0, 30),
    text: document.body.innerText.slice(0, 2000),
  }));
  console.log(JSON.stringify(data, null, 2));
  await browser.close();
}

inspect(process.argv[2]).catch((error) => {
  console.error(error);
  process.exit(1);
});
