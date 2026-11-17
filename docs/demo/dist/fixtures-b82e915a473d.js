import { items } from "./data-b82e915a473d.js";

export const qualities = [
  { name: "Poor", color: "#9d9d9d" },
  { name: "Common", color: "#ffffff" },
  { name: "Uncommon", color: "#1eff00" },
  { name: "Rare", color: "#0070dd" },
  { name: "Epic", color: "#a335ee" },
  { name: "Legendary", color: "#ff8000" },
  { name: "Artifact", color: "#e6cc80" },
  { name: "Heirloom", color: "#00ccff" },
  { name: "Token", color: "#00ccff" },
];
export const characters = [
  {
    id: "hex",
    name: "Hex Loothur",
    level: 28,
    role: "Warlock",
    capacity: 80,
    gold: 128386,
  },
  {
    id: "elowen",
    name: "Elowen",
    level: 60,
    role: "Druid / Herbalist",
    capacity: 96,
    gold: 8742651,
  },
  {
    id: "brom",
    name: "Brom Ironhand",
    level: 60,
    role: "Warrior / Blacksmith",
    capacity: 80,
    gold: 2459870,
  },
  {
    id: "mira",
    name: "Mira Goldleaf",
    level: 60,
    role: "Banker / Collector",
    capacity: 120,
    gold: 45873291,
  },
];
// Curated names/art, with intentionally synthetic rarity, stack and price data.
// These are testing fixtures, not an item database or live auction estimates.
function batch(category, names, icons, quality = 1, count = 1) {
  return names
    .split("|")
    .map((name, index) => ({
      name,
      category,
      icon: icons[index % icons.length],
      quality: typeof quality === "function" ? quality(index) : quality,
      count: typeof count === "function" ? count(index) : count,
      vendor: category === "Quest" ? 0 : 35 + (index + 1) * 173,
      auction: 1250 + (index + 1) * 571,
    }));
}
const herbs = batch(
  "Trade Goods",
  "Earthroot|Mageroyal|Briarthorn|Bruiseweed|Wild Steelbloom|Kingsblood|Liferoot|Fadeleaf|Goldthorn|Khadgar’s Whisker|Wintersbite|Firebloom|Purple Lotus|Sungrass|Blindweed|Ghost Mushroom|Gromsblood|Golden Sansam|Dreamfoil|Mountain Silversage|Plaguebloom|Icecap|Black Lotus",
  [
    "inv_misc_herb_01",
    "inv_misc_herb_03",
    "inv_misc_herb_07",
    "inv_misc_herb_08",
    "inv_misc_flower_01",
    "inv_misc_herb_10",
  ],
  1,
  (i) => 3 + i * 7,
);
const metals = batch(
  "Trade Goods",
  "Tin Ore|Iron Ore|Mithril Ore|Thorium Ore|Silver Ore|Gold Ore|Truesilver Ore|Dark Iron Ore|Copper Bar|Bronze Bar|Iron Bar|Steel Bar|Mithril Bar|Thorium Bar|Arcanite Bar|Rough Stone|Coarse Stone|Heavy Stone|Solid Stone|Dense Stone",
  [
    "inv_ore_tin_01",
    "inv_ore_iron_01",
    "inv_ore_mithril_01",
    "inv_ore_thorium_02",
    "inv_ingot_02",
    "inv_stone_01",
  ],
  1,
  (i) => 5 + i * 9,
);
const enchanting = batch(
  "Reagents",
  "Soul Dust|Vision Dust|Dream Dust|Illusion Dust|Lesser Magic Essence|Greater Magic Essence|Lesser Astral Essence|Greater Astral Essence|Small Glimmering Shard|Large Glowing Shard|Small Radiant Shard|Large Brilliant Shard|Arcane Crystal|Righteous Orb|Essence of Fire|Essence of Water|Essence of Air|Essence of Earth",
  [
    "inv_enchant_dustsoul",
    "inv_enchant_dustvision",
    "inv_enchant_dustdream",
    "inv_enchant_essencemagiclarge",
    "inv_enchant_shardbrilliantsmall",
    "inv_misc_gem_crystal_02",
  ],
  (i) => (i % 3 === 0 ? 3 : 2),
  (i) => 1 + i * 3,
);
const potions = batch(
  "Consumables",
  "Major Healing Potion|Major Mana Potion|Greater Fire Protection Potion|Greater Nature Protection Potion|Elixir of the Mongoose|Elixir of Greater Intellect|Flask of Supreme Power|Flask of the Titans|Swiftness Potion|Free Action Potion|Limited Invulnerability Potion|Restorative Potion|Heavy Runecloth Bandage|Smoked Desert Dumplings|Grilled Squid|Nightfin Soup",
  [
    "inv_potion_54",
    "inv_potion_76",
    "inv_potion_24",
    "inv_potion_31",
    "inv_potion_97",
    "inv_potion_17",
    "inv_misc_bandage_12",
    "inv_misc_food_15",
  ],
  1,
  (i) => [1, 5, 20, 40][i % 4],
);
const caster = batch(
  "Gear",
  "Dreadmist Mask|Dreadmist Mantle|Dreadmist Robe|Dreadmist Bracers|Dreadmist Wraps|Dreadmist Belt|Dreadmist Leggings|Dreadmist Sandals|Felheart Horns|Felheart Shoulder Pads|Felheart Robes|Felheart Gloves|Felheart Belt|Felheart Pants|Felheart Slippers|Staff of Dominance|Witchblade|Bonecreeper Stylus|Eye of Orgrimmar|Royal Seal of Eldre’Thalas",
  [
    "inv_helmet_29",
    "inv_shoulder_25",
    "inv_chest_cloth_09",
    "inv_bracer_07",
    "inv_gauntlets_19",
    "inv_belt_13",
    "inv_pants_06",
    "inv_boots_05",
    "inv_staff_13",
    "inv_jewelry_talisman_07",
  ],
  (i) => (i < 8 ? 3 : 4),
);
const warrior = batch(
  "Gear",
  "Helm of Valor|Spaulders of Valor|Breastplate of Valor|Bracers of Valor|Gauntlets of Valor|Belt of Valor|Legplates of Valor|Boots of Valor|Helm of Might|Pauldrons of Might|Breastplate of Might|Gauntlets of Might|Belt of Might|Legplates of Might|Sabatons of Might|Obsidian Edged Blade|Quel’Serrar|Drillborer Disk|Hand of Justice|Blackhand’s Breadth",
  [
    "inv_helmet_09",
    "inv_shoulder_15",
    "inv_chest_plate16",
    "inv_bracer_19",
    "inv_gauntlets_26",
    "inv_belt_09",
    "inv_pants_04",
    "inv_boots_plate_06",
    "inv_sword_27",
    "inv_shield_06",
  ],
  (i) => (i < 8 ? 3 : 4),
);
const druid = batch(
  "Gear",
  "Wildheart Cowl|Wildheart Spaulders|Wildheart Vest|Wildheart Bracers|Wildheart Gloves|Wildheart Belt|Wildheart Kilt|Wildheart Boots|Cenarion Helm|Cenarion Spaulders|Cenarion Vestments|Cenarion Gloves|Cenarion Belt|Cenarion Leggings|Cenarion Boots|Finkle’s Lava Dredger|Warden Staff|Idol of Rejuvenation|Second Wind|Mindtap Talisman",
  [
    "inv_helmet_27",
    "inv_shoulder_06",
    "inv_chest_leather_06",
    "inv_bracer_09",
    "inv_gauntlets_17",
    "inv_belt_06",
    "inv_pants_12",
    "inv_boots_08",
    "inv_staff_15",
    "inv_jewelry_talisman_07",
  ],
  (i) => (i < 8 ? 3 : 4),
);
const quests = batch(
  "Quest",
  "The Missing Diplomat|A Crumpled Map of Blackrock Depths|Sealed Orders from the Argent Dawn|A Carefully Wrapped Dragon Egg|The Lost Tablets of Mosh’aru|Ancient Qiraji Artifact|The Scepter’s Final Fragment|A Very Long and Suspiciously Specific Quest Item Name",
  ["inv_misc_note_01", "inv_misc_book_06", "inv_scroll_05", "inv_egg_02"],
  1,
);
const recipes = batch(
  "Recipes",
  "Recipe: Major Mana Potion|Recipe: Flask of the Titans|Plans: Arcanite Reaper|Plans: Lionheart Helm|Pattern: Mooncloth Bag|Pattern: Robe of the Void|Formula: Enchant Weapon - Crusader|Schematic: Arcanite Dragonling",
  ["inv_scroll_03", "inv_scroll_05"],
  (i) => 2 + (i % 3),
);
const collectibles = batch(
  "Other",
  "Mechanical Squirrel|Tiny Crimson Whelpling|Captured Firefly|Lucky Rabbit’s Foot|Broken Antler|Tarnished Silver Necklace|Cracked Dragon Scale|Frayed Adventurer’s Cloak|Ancient Gold Coin|A Faded Photograph",
  [
    "inv_misc_bag_08",
    "inv_misc_monsterhead_01",
    "inv_misc_gem_pearl_02",
    "inv_jewelry_ring_03",
    "inv_misc_book_07",
  ],
  (i) => (i < 3 ? 3 : i < 8 ? 0 : 1),
);
const rarityRows = [
  ["Tattered Cloth Gloves", "inv_gauntlets_19", 0],
  ["Worn Wooden Shield", "inv_shield_06", 0],
  ["Simple Linen Robe", "inv_chest_cloth_09", 1],
  ["Plain Copper Ring", "inv_jewelry_ring_03", 1],
  ["Greenweave Mantle", "inv_shoulder_25", 2],
  ["Jade-Tipped Dagger", "inv_weapon_shortblade_01", 2],
  ["Staff of Jordan", "inv_staff_13", 3],
  ["Helm of Valor", "inv_helmet_09", 3],
  ["Azuresong Mageblade", "inv_sword_27", 4],
  ["Felheart Horns", "inv_helmet_29", 4],
  ["Thunderfury, Blessed Blade of the Windseeker", "inv_sword_39", 5],
  ["Sulfuras, Hand of Ragnaros", "inv_hammer_unique_sulfuras", 5],
  ["Ashbringer — Artifact Preview", "inv_sword_2h_ashbringercorrupt", 6],
  ["Ancient Keeper’s Relic — Artifact Preview", "inv_misc_gem_crystal_02", 6],
  ["Dignified Headmaster’s Charge", "inv_staff_13", 7],
  ["Champion Herod’s Shoulder", "inv_shoulder_15", 7],
  ["WoW Token — Color Preview", "inv_misc_coin_01", 8],
];
export const rarityItems = rarityRows.map(([name, icon, quality]) => ({
  name,
  icon,
  quality,
  category: quality === 8 ? "Other" : "Gear",
  count: 1,
  vendor: quality >= 5 ? 0 : 100 + quality * 17500,
  auction: quality >= 5 ? 0 : 25000 + quality * 150000,
}));
const base = (categories) =>
  items.filter((i) => categories.includes(i.category)).map((i) => ({ ...i }));
const collections = {
  hex: [
    ...base(["Consumables", "Reagents", "Camp", "Other"]),
    ...caster,
    ...enchanting.slice(0, 8),
    ...quests,
    ...recipes.slice(0, 4),
  ],
  elowen: [
    ...druid,
    ...herbs,
    ...potions,
    ...quests.slice(0, 4),
    ...recipes.slice(0, 4),
    ...base(["Camp", "Other"]),
  ],
  brom: [
    ...warrior,
    ...metals,
    ...potions,
    ...quests.slice(2, 6),
    ...recipes.slice(2, 6),
    ...base(["Camp", "Other"]),
  ],
  mira: [
    ...herbs,
    ...metals,
    ...enchanting,
    ...recipes,
    ...collectibles,
    ...rarityItems,
  ],
};
export function sampleInventory(state) {
  let list = collections[state.character] || collections.hex;
  // Keep the original screenshot-like inventory available independently.
  if (state.scenario === "original") list = items;
  if (state.scenario === "rarities") list = rarityItems;
  if (state.scenario === "stacks")
    list = [
      ...herbs.slice(0, 6),
      ...metals.slice(0, 6),
      ...potions.slice(0, 6),
    ].flatMap((i, n) =>
      [1, 20, 200, 999, 1000].map((count, k) => ({
        ...i,
        count,
        bag: 1 + (k % 4),
      })),
    );
  if (state.scenario === "empty") return [];
  const character =
    characters.find((c) => c.id === state.character) || characters[0];
  if (state.scenario === "full")
    list = Array.from({ length: character.capacity }, (_, n) => ({
      ...list[n % list.length],
      count:
        list[n % list.length].category === "Gear" ? 1 : 1 + ((n * 13) % 200),
    }));
  return list.map((i, id) => ({
    ...i,
    id,
    bag: i.bag || 1 + (id % 4),
    recent: [2, 5, 11, 18, 25, 31].includes(id),
  }));
}
