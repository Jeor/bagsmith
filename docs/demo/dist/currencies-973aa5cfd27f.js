import { sampleInventory, characters } from "./fixtures-973aa5cfd27f.js";
import { defaults } from "./data-973aa5cfd27f.js";
export const currencyTypes = [
  {
    id: "honor",
    name: "Honor",
    icon: "sword-shield",
    amounts: [1250, 8740, 15200, 480],
  },
  {
    id: "justice",
    name: "Justice Points",
    icon: "bank",
    amounts: [340, 1850, 2600, 120],
  },
  {
    id: "valor",
    name: "Valor Points",
    icon: "star",
    amounts: [0, 740, 1250, 90],
  },
  {
    id: "conquest",
    name: "Conquest",
    icon: "sword-shield-mark",
    amounts: [0, 250, 1450, 0],
  },
  {
    id: "badges",
    name: "Badges of Justice",
    icon: "wallet",
    amounts: [12, 86, 143, 310],
  },
  {
    id: "marks",
    name: "Marks of Honor",
    icon: "pin",
    amounts: [3, 24, 72, 18],
  },
  {
    id: "seals",
    name: "Champion’s Seals",
    icon: "key",
    amounts: [0, 32, 14, 185],
  },
  {
    id: "tokens",
    name: "Event Tokens",
    icon: "leaf",
    amounts: [8, 120, 45, 999],
  },
];
export const defaultPins = ["honor", "justice"];
export function trackableItems(character) {
  return sampleInventory({ ...defaults, character })
    .filter((i) => i.category !== "Gear")
    .map((i) => ({ ...i, key: `item:${character}:${i.id}` }));
}
export function validTracked(key) {
  if (typeof key !== "string") return false;
  return characters.some((c) =>
    trackableItems(c.id).some((i) => i.key === key),
  );
}
export function currencyRows(character, state = {}) {
  const index = Math.max(
    0,
    characters.findIndex((c) => c.id === character),
  );
  const wallet = currencyTypes.map((c) => ({
    ...c,
    amount: state.global
      ? c.amounts.reduce((a, b) => a + b, 0)
      : c.amounts[index],
    per: characters
      .map((owner, n) => `${owner.name}: ${c.amounts[n].toLocaleString()}`)
      .join(" � "),
  }));
  const tracked = (state.trackedCurrencies || [])
    .map((key) =>
      characters
        .flatMap((c) => trackableItems(c.id))
        .find((i) => i.key === key),
    )
    .filter(Boolean)
    .map((item) => ({
      id: item.key,
      name: item.name,
      itemIcon: item.icon,
      tracked: true,
      amount: (state.global
        ? characters
        : characters.filter((c) => c.id === character)
      )
        .flatMap((c) => sampleInventory({ ...defaults, character: c.id }))
        .filter((i) => i.name === item.name)
        .reduce((n, i) => n + i.count, 0),
    }));
  return [...wallet, ...tracked];
}
export function panelState(state, key, open) {
  const next = { ...state, [key]: open };
  if (open && key === "drawer") next.currencyOpen = false;
  if (open && key === "currencyOpen") next.drawer = false;
  return next;
}
