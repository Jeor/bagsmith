import { test } from "node:test";
import { panelState, currencyRows } from "./currencies.js";
import assert from "node:assert/strict";
test("drawers are mutually exclusive for either opening order", () => {
  let state = validate();
  state = panelState(state, "currencyOpen", true);
  assert.equal(state.drawer, false);
  assert.equal(state.currencyOpen, true);
  state = panelState(state, "drawer", true);
  assert.equal(state.currencyOpen, false);
  assert.equal(state.drawer, true);
  assert.equal(validate({ drawer: true, currencyOpen: true }).drawer, false);
});
test("currency balances differ by character and shared pins are validated", () => {
  assert.notEqual(
    currencyRows("hex")[0].amount,
    currencyRows("mira")[0].amount,
  );
  assert.deepEqual(
    validate({ currencyPins: ["honor", "honor", "invalid"] }).currencyPins,
    ["honor"],
  );
});
import { validate, inventory, groups } from "./model.js";
test("untrusted share settings are bounded and enums validated", () => {
  const s = validate({
    size: 999,
    height: -100,
    layout: "evil",
    vendor: "false",
  });
  assert.equal(s.size, 64);
  assert.equal(s.height, 360);
  assert.equal(s.layout, "compact");
  assert.equal(s.vendor, true);
});
test("merging preserves item quantity and vendor total", () => {
  const s = validate({ merge: false });
  const a = inventory(s),
    b = inventory({ ...s, merge: true });
  assert.ok(a.length > b.length);
  for (const total of [(x) => x.count, (x) => x.count * x.vendor])
    assert.equal(
      a.reduce((n, i) => n + total(i), 0),
      b.reduce((n, i) => n + total(i), 0),
    );
});
test("search and rarity filter compose with tabs", () => {
  const a = inventory(
    validate({ tab: "Gear", scenario: "original" }),
    "bronze",
    true,
  );
  assert.equal(a.length, 1);
  assert.equal(a[0].name, "Bronze Band");
  assert.equal(
    inventory(validate({ tab: "Gear", scenario: "original" }), "copper", true)
      .length,
    0,
  );
});
test("by bag grouping never loses an item", () => {
  const s = validate({ group: "bag", scenario: "full" }),
    list = inventory(s);
  assert.equal(
    groups(list, s).reduce((n, g) => n + g.items.length, 0),
    list.length,
  );
});
test("empty and long scenarios exercise meaningful edge states", () => {
  assert.equal(inventory(validate({ scenario: "empty" })).length, 0);
  const s = validate({ scenario: "long" });
  assert.ok(groups(inventory(s), s).some((g) => g.name.length > 30));
});

import { characters, qualities, sampleInventory } from "./fixtures.js";
test("characters have distinct substantial inventories and complete item metadata", () => {
  const names = [];
  for (const c of characters) {
    const list = sampleInventory(validate({ character: c.id }));
    assert.ok(list.length >= 60, c.id);
    assert.ok(
      list.every(
        (i) => i.icon && i.count > 0 && i.quality >= 0 && i.quality <= 8,
      ),
    );
    names.push(list.map((i) => i.name).join("|"));
  }
  assert.equal(new Set(names).size, characters.length);
});
test("rarity preset includes every rarity and exact filter isolates it", () => {
  for (let q = 0; q < qualities.length; q++) {
    const list = inventory(
      validate({ scenario: "rarities", rarity: String(q) }),
    );
    assert.ok(list.length > 0);
    assert.ok(list.every((i) => i.quality === q));
  }
});
test("full bags fill each character capacity before merging", () => {
  for (const c of characters)
    assert.equal(
      sampleInventory(validate({ character: c.id, scenario: "full" })).length,
      c.capacity,
    );
});
test("stack stress merging preserves large quantities", () => {
  const state = validate({ scenario: "stacks", merge: false });
  const raw = inventory(state),
    merged = inventory({ ...state, merge: true });
  assert.ok(raw.length > merged.length);
  assert.equal(
    raw.reduce((n, i) => n + i.count, 0),
    merged.reduce((n, i) => n + i.count, 0),
  );
  assert.ok(merged.some((i) => i.count > 2000));
});
test("shared state round trips selected character, inventory and rarity", () => {
  const state = validate({
    character: "mira",
    scenario: "rarities",
    rarity: "5",
  });
  assert.deepEqual(validate(JSON.parse(JSON.stringify(state))), state);
  assert.equal(validate(null).character, "hex");
});

import { sourceInventory } from "./model.js";
import { validTracked, trackableItems } from "./currencies.js";
test("global inventory contains each character and preserves quantities when merged", () => {
  const s = validate({ global: true, merge: false });
  const list = inventory(s);
  assert.equal(
    list.length,
    characters.reduce(
      (n, c) => n + sampleInventory({ ...s, character: c.id }).length,
      0,
    ),
  );
  assert.equal(
    new Set(list.flatMap((i) => i.owners.map((o) => o.name))).size,
    4,
  );
  const merged = inventory({ ...s, merge: true });
  assert.equal(
    merged.reduce((n, i) => n + i.count, 0),
    list.reduce((n, i) => n + i.count, 0),
  );
});
test("gear sets and filters compose, and all six sort modes are supported", () => {
  const s = validate({ tab: "Gear Sets", gearSet: "raid" });
  assert.ok(inventory(s).every((i) => i.category === "Gear" && i.quality >= 4));
  const sorted = inventory({ ...s, sort: "ilvl" });
  assert.ok(sorted.every((v, i) => !i || v.level <= sorted[i - 1].level));
  assert.equal(validate({ sort: "oldest" }).sort, "oldest");
  assert.ok(
    inventory(validate({ filterCategory: "Reagents" })).every(
      (i) => i.category === "Reagents",
    ),
  );
});
test("tracked currencies and reordered defaults stay isolated", () => {
  const item = trackableItems("hex")[0];
  assert.ok(validTracked(item.key));
  const s = validate({
    trackedCurrencies: [item.key, "invalid"],
    currencyPins: [item.key],
  });
  assert.equal(s.trackedCurrencies.length, 1);
  assert.ok(currencyRows("hex", s).some((c) => c.id === item.key));
  const a = validate();
  a.currencyPins.reverse();
  assert.deepEqual(validate().currencyPins, ["honor", "justice"]);
});
