import { fonts } from "./fonts-da7fc5bd78e5.js";
import { currencyTypes, validTracked, currencyRows } from "./currencies-da7fc5bd78e5.js";
import { sampleInventory, characters, qualities } from "./fixtures-da7fc5bd78e5.js";
import { categories, defaults } from "./data-da7fc5bd78e5.js";
export function validate(input = {}) {
  const state = {
    ...defaults,
    currencyPins: [...defaults.currencyPins],
    trackedCurrencies: [],
  };
  if (!input || typeof input !== "object") return state;
  const choices = {
    layout: ["compact", "split", "standard"],
    view: ["icons", "list"],
    group: ["section", "all", "bag"],
    sort: ["quality", "name", "ilvl", "newest", "oldest", "off"],
    gearSet: ["all", "dungeon", "raid"],
    filterCategory: ["all", ...categories],
    scenario: [
      "everyday",
      "original",
      "full",
      "long",
      "empty",
      "rarities",
      "stacks",
    ],
    character: characters.map((c) => c.id),
    rarity: ["all", ...qualities.map((_, i) => String(i))],
    skin: ["modern", "classic"],
    font: fonts.map((f) => f.id),
    headingFont: fonts.map((f) => f.id),
    tab: [
      "All",
      "Gear",
      "Consumables",
      "Trade Goods",
      "Quest",
      "Junk",
      "Gear Sets",
      "Bank",
    ],
  };
  for (const [key, allowed] of Object.entries(choices))
    if (allowed.includes(input[key])) state[key] = input[key];
  for (const key of [
    "merge",
    "count",
    "vendor",
    "auction",
    "drawer",
    "currencyOpen",
    "global",
    "travel",
  ])
    if (typeof input[key] === "boolean") state[key] = input[key];
  for (const [key, min, max] of [
    ["size", 32, 64],
    ["gap", 4, 20],
    ["opacity", 65, 100],
    ["width", 500, 1400],
    ["height", 360, 1000],
  ])
    if (Number.isFinite(input[key]))
      state[key] = Math.min(max, Math.max(min, input[key]));
  if (Array.isArray(input.trackedCurrencies))
    state.trackedCurrencies = [
      ...new Set(input.trackedCurrencies.filter(validTracked)),
    ];
  const allowedPins = currencyRows(state.character, state).map((c) => c.id);
  if (Array.isArray(input.currencyPins))
    state.currencyPins = [
      ...new Set(input.currencyPins.filter((id) => allowedPins.includes(id))),
    ];
  if (state.global) {
    state.group = "section";
    state.travel = false;
  }
  if (state.currencyOpen) state.drawer = false;
  return state;
}
export function inventory(state, query = "", rare = false) {
  let result = sourceInventory(state);
  if (state.filterCategory !== "all")
    result = result.filter((i) => i.category === state.filterCategory);
  if (state.tab === "Bank")
    result = result
      .filter((i) => i.id % 3 === 0)
      .map((i) => ({ ...i, count: i.count * 2 }));
  else if (state.tab === "Junk") result = result.filter((i) => i.quality === 0);
  else if (state.tab === "Gear Sets")
    result = result.filter(
      (i) =>
        i.category === "Gear" &&
        (state.gearSet === "all" ||
          (state.gearSet === "raid" ? i.quality >= 4 : i.quality === 3)),
    );
  else if (state.tab !== "All")
    result = result.filter((i) => i.category === state.tab);
  result = result.filter(
    (i) =>
      (state.rarity === "all" || i.quality === Number(state.rarity)) &&
      (!rare || i.quality >= 2) &&
      `${i.name} ${i.category}`.toLowerCase().includes(query.toLowerCase()),
  );
  if (state.merge) {
    const merged = new Map();
    for (const item of result) {
      const key = `${item.category}:${item.name}:${item.quality}${state.group === "bag" ? ":" + item.bag : ""}`;
      if (merged.has(key)) {
        const combined = merged.get(key);
        combined.count += item.count;
        combined.owners = [...(combined.owners || []), ...(item.owners || [])];
      } else merged.set(key, { ...item });
    }
    result = [...merged.values()];
  }
  if (state.sort === "name")
    result.sort((a, b) => a.name.localeCompare(b.name));
  if (state.sort === "quality") result.sort((a, b) => b.quality - a.quality);
  if (state.sort === "ilvl") result.sort((a, b) => b.level - a.level);
  if (state.sort === "oldest") result.sort((a, b) => a.id - b.id);
  if (state.sort === "newest") result.sort((a, b) => b.id - a.id);
  return result;
}
export function groups(list, state) {
  if (state.group === "all") return [{ name: "All Items", items: list }];
  const names =
    state.group === "bag"
      ? ["Backpack", "Linen Bag", "Woolen Bag", "Traveler’s Bag"]
      : categories;
  return names
    .map((name, index) => ({
      name:
        state.scenario === "long" && name === "Consumables"
          ? "Potions, Food & Adventure Supplies"
          : name,
      items: list.filter((i) =>
        state.group === "bag" ? i.bag === index + 1 : i.category === name,
      ),
    }))
    .filter((g) => g.items.length);
}

export function sourceInventory(state) {
  const owners = state.global
    ? characters
    : characters.filter((c) => c.id === state.character);
  return owners.flatMap((owner, ownerIndex) =>
    sampleInventory({ ...state, character: owner.id }).map((i) => ({
      ...i,
      id: i.id + ownerIndex * 10000,
      level:
        i.category === "Gear"
          ? Math.max(1, owner.level + i.quality * 5 + (i.id % 12))
          : 1,
      owners: [{ name: owner.name, count: i.count }],
    })),
  );
}
