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
export function currencyRows(character) {
  const index = Math.max(
    0,
    ["hex", "elowen", "brom", "mira"].indexOf(character),
  );
  return currencyTypes.map((c) => ({ ...c, amount: c.amounts[index] }));
}
export function panelState(state, key, open) {
  const next = { ...state, [key]: open };
  if (open && key === "drawer") next.currencyOpen = false;
  if (open && key === "currencyOpen") next.drawer = false;
  return next;
}
