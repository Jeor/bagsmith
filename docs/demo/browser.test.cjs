// Run against a local server or the published site with DEMO_URL.
const { chromium } = require("playwright");
const assert = require("node:assert/strict");
(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1518, height: 900 },
    permissions: ["clipboard-read", "clipboard-write"],
  });
  const page = await context.newPage(),
    errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  const base = process.env.DEMO_URL || "http://127.0.0.1:8001/demo/";
  const button = (name) => page.getByRole("button", { name, exact: true });
  const select = (name, value) =>
    page.getByRole("combobox", { name, exact: true }).selectOption(value);
  try {
    await page.goto(
      base +
        "#" +
        encodeURIComponent(JSON.stringify({ font: "marcellus", drawer: true })),
    );
    await button("Fonts & Appearance").click();
    await select("Interface Font", "inter");
    await select("Category Header Font", "marcellus");
    await button("Close dialog").click();
    await page.reload();
    assert.ok(
      (
        await page
          .locator("#drawer")
          .evaluate((el) => getComputedStyle(el).fontFamily)
      ).includes("Inter"),
      "shared URL must not revert font changes",
    );
    assert.equal(new URL(page.url()).hash, "");
    await button("Currencies").click();
    assert.ok(await page.locator("#currencies").isVisible());
    assert.ok(!(await page.locator("#drawer").isVisible()));
    await page.reload();
    assert.ok(
      await page.locator("#currencies").isVisible(),
      "drawer choice persists after shared-link load",
    );
    await button("Pin Valor Points").click();
    await button("Move Valor Points up").click();
    assert.equal(
      await page
        .locator("#pinned-currencies button")
        .nth(1)
        .getAttribute("aria-label"),
      "Open currencies: Valor Points",
    );
    await button("Unpin Valor Points").click();
    assert.equal(await page.locator("#pinned-currencies button").count(), 2);
    const trackedName = await page
      .locator("#track-item option")
      .first()
      .innerText();
    await button("Track Item").click();
    assert.ok(await button("Stop tracking " + trackedName).isVisible());
    await button("Stop tracking " + trackedName).click();
    assert.equal(await button("Stop tracking " + trackedName).count(), 0);
    await page
      .getByRole("searchbox", { name: "Search currencies" })
      .fill("zz-no-match");
    assert.ok(await page.getByText("No matching currencies.").isVisible());
    await page.getByRole("searchbox", { name: "Search currencies" }).fill("");
    await button("Toggle bag options").click();
    assert.ok(!(await page.locator("#currencies").isVisible()));
    await button("Toggle currency drawer").click();
    assert.ok(await page.locator("#currencies").isVisible());
    await button("Close currencies").click();
    await button("Toggle bag options").click();
    for (const layout of ["Standard", "Compact", "Split"])
      await button(layout).click();
    await button("List").click();
    assert.ok((await page.locator(".item-name").count()) > 0);
    await button("Icons").click();
    for (const sort of ["quality", "name", "ilvl", "newest", "oldest", "off"])
      await select("Sorting", sort);
    await select("Grouping", "bag");
    assert.ok(
      await page.getByRole("button", { name: /Backpack \(/ }).isVisible(),
    );
    await select("Grouping", "section");
    await button("Global Inventory").click();
    assert.equal(
      await page.locator("#bag-heading").innerText(),
      "Global Inventory",
    );
    assert.ok((await page.locator(".categories .item").count()) > 100);
    assert.equal(
      await page
        .locator('[data-setting="group"] option[value="bag"]')
        .isDisabled(),
      true,
    );
    await button("Back to Character").click();
    await button("Gear Sets").first().click();
    await select("Gear Set", "raid");
    assert.ok(
      (
        await page
          .locator(".categories .item")
          .evaluateAll((nodes) => nodes.map((n) => n.className))
      ).every((c) => /quality-[4-8]/.test(c)),
    );
    await page
      .locator("#tabs")
      .getByRole("button", { name: "Bank", exact: true })
      .click();
    assert.equal(await page.locator("#bag-heading").innerText(), "Bank");
    await page
      .locator("#tabs")
      .getByRole("button", { name: "All", exact: true })
      .click();
    await button("Inventory filters").click();
    await select("Quality", "4");
    await select("Category", "Gear");
    await button("Close dialog").click();
    assert.ok(
      (
        await page
          .locator(".categories .item")
          .evaluateAll((nodes) => nodes.map((n) => n.className))
      ).every((c) => c.includes("quality-4")),
    );
    await button("Inventory filters").click();
    await button("Clear Filters").click();
    const width = await page
      .locator("#bag")
      .evaluate((el) => el.getBoundingClientRect().width);
    await button("Travel Mode").click();
    assert.ok(await button("Exit Travel Mode").isVisible());
    assert.ok(!(await page.locator("#tabs").isVisible()));
    await button("Exit Travel Mode").click();
    assert.equal(
      await page
        .locator("#bag")
        .evaluate((el) => el.getBoundingClientRect().width),
      width,
    );
    await button("Fonts & Appearance").click();
    for (const value of [
      "marcellus",
      "inter",
      "noto",
      "roboto",
      "roboto-bold",
      "fira",
      "cabin",
      "barlow",
      "asap",
    ]) {
      await select("Interface Font", value);
      await select("Category Header Font", value);
      await page.evaluate(() => document.fonts.ready);
      assert.ok(
        await page.evaluate(() =>
          document.fonts.check(
            "14px " +
              getComputedStyle(document.documentElement)
                .getPropertyValue("--bag-font")
                .trim(),
          ),
        ),
      );
    }
    await button("Close dialog").click();
    await button("Copy View Link").click();
    const link = await page.evaluate(() => navigator.clipboard.readText());
    const other = await context.newPage();
    await other.goto(link);
    assert.ok(
      (
        await other
          .locator("#bag")
          .evaluate((el) => getComputedStyle(el).fontFamily)
      ).includes("AsapCondensed"),
    );
    await other.close();
    await button("Reset").click();
    await page
      .locator("img")
      .evaluateAll((imgs) => Promise.all(imgs.map((i) => i.decode())));
    await page.screenshot({
      path: process.env.DEMO_SCREENSHOT || "parity-desktop.png",
      fullPage: true,
    });
    await page.setViewportSize({ width: 390, height: 844 });
    await button("Close bag options").click();
    assert.ok(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    );
    await button("Toggle currency drawer").click();
    assert.ok(await page.locator("#currencies").isVisible());
    await button("Close currencies").click();
    await button("Fonts & Appearance").click();
    await select("Interface Font", "inter");
    await button("Close dialog").click();
    assert.ok(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    );
    assert.deepEqual(errors, []);
    console.log(
      "PASS: shared-link persistence, currencies, fonts, all visible tools, layouts, filters, sorts, global/gear/bank/travel views and mobile",
    );
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
