import { RELEASE } from "./release.js";
import { fonts } from "./fonts.js";
import {
  currencyRows,
  defaultPins,
  panelState,
  trackableItems,
} from "./currencies.js";
import { characters, qualities, sampleInventory } from "./fixtures.js";
import { defaults } from "./data.js";
import { validate, inventory, groups, sourceInventory } from "./model.js";
const $ = (id) => document.getElementById(id);
let state = validate(),
  query = "",
  rare = false,
  collapsed = new Set(),
  recent = true;
try {
  state = validate(
    JSON.parse(
      location.hash.slice(1)
        ? decodeURIComponent(location.hash.slice(1))
        : localStorage.getItem("bagsmith-demo-v1") || "{}",
    ),
  );
} catch {}
// Shared URLs initialize once; later edits and refreshes use the saved view.
if (location.hash) {
  try {
    localStorage.setItem("bagsmith-demo-v1", JSON.stringify(state));
  } catch {}
  history.replaceState(null, "", location.pathname + location.search);
}
const icon = (name) =>
  `<img class="ui-icon" src="assets/ui-${name}.png" alt="">`;
const money = (value) => {
  const g = Math.floor(value / 10000),
    s = Math.floor(value / 100) % 100,
    c = value % 100;
  return `${g ? `${g}<i class="coin gold"></i> ` : ""}${s ? `${s}<i class="coin silver"></i> ` : ""}${c || !value ? `${c}<i class="coin copper"></i>` : ""}`;
};
function save() {
  try {
    localStorage.setItem("bagsmith-demo-v1", JSON.stringify(state));
  } catch {}
}
function set(key, value) {
  state = panelState(state, key, value);
  save();
  render();
}
function segment(key, label, values) {
  return `<fieldset><legend>${label}</legend><div class="segment">${values.map(([v, t]) => `<button data-setting="${key}" data-value="${v}" aria-pressed="${state[key] === v}">${t}</button>`).join("")}</div></fieldset>`;
}
function check(key, label) {
  return `<label class="check"><input type="checkbox" data-setting="${key}" ${state[key] ? "checked" : ""}><span>${label}</span></label>`;
}
function select(key, label, values) {
  return `<label class="select-label">${label}<select data-setting="${key}">${values.map(([v, t]) => `<option value="${v}" ${state[key] === v ? "selected" : ""}>${t}</option>`).join("")}</select></label>`;
}
let sidebarConcept = "compact";
try { const saved = localStorage.getItem("bagsmith-sidebar-concept"); if (["original", "compact", "minimal"].includes(saved)) sidebarConcept = saved; } catch {}
const openOptionSections = new Set();
function options() {
  for (const details of $("options").querySelectorAll("details[data-section]")) {
    details.open ? openOptionSections.add(details.dataset.section) : openOptionSections.delete(details.dataset.section);
  }
  const focused = document.activeElement;
  const restoreSetting = focused?.closest("#options") ? focused.dataset.setting : null;
  const restoreValue = focused?.dataset.value;
  $("options").innerHTML =
    segment("view", "View", [
      ["list", "List"],
      ["icons", "Icons"],
    ]) +
    segment("layout", "Layout", [
      ["standard", "Standard"],
      ["compact", "Compact"],
      ["split", "Split"],
    ]) +
    select("group", "Grouping", [
      ["all", "All Items"],
      ["section", "By Section"],
      ["bag", "By Bag"],
    ]) +
    `<button class="tool collapse" data-action="collapse">${icon("collapse")}<span>${collapsed.size ? "Expand" : "Collapse"} All Sections</span></button>` +
    select("sort", "Sorting", [
      ["quality", "Quality"],
      ["name", "Name"],
      ["ilvl", "Item Level"],
      ["newest", "Newest"],
      ["oldest", "Oldest"],
      ["off", "Off"],
    ]) +
    check("merge", "Merge Stacks") +
    `<fieldset><legend>Category Details</legend>${check("count", "Item Count")}${check("vendor", "Vendor Value")}${check("auction", "Auction Value")}</fieldset><fieldset><legend>Tools</legend>${[
      ["broom", "Clean Up Bags", "cleanup"],
      ["sword-shield", "Gear Sets", "gear"],
      ["bank", "Bank", "bank"],
      ["wallet", "Currencies", "currencies"],
      [
        "globe",
        state.global ? "Back to Character" : "Global Inventory",
        "global",
      ],
      ["signpost", state.travel ? "Exit Travel Mode" : "Travel Mode", "travel"],
    ]
      .map(
        ([i, t, a]) =>
          `<button class="tool" data-action="${a}">${icon(i)}<span>${t}</span></button>`,
      )
      .join("")}</fieldset>`;
  const bagGrouping = document.querySelector(
    '[data-setting="group"] option[value="bag"]',
  );
  if (bagGrouping) bagGrouping.disabled = state.global;
  $("drawer").dataset.concept = sidebarConcept;
  if (sidebarConcept !== "original") {
    const host = $("options");
    const view = host.querySelector("fieldset");
    view.classList.add("view-choice");
    view.querySelector('[data-value="icons"]').innerHTML = '<span class="view-glyph grid-glyph" aria-hidden="true"></span>Grid';
    view.querySelector('[data-value="list"]').innerHTML = '<span class="view-glyph list-glyph" aria-hidden="true"></span>List';
    view.querySelector(".segment").prepend(view.querySelector('[data-value="icons"]'));
    const layout = host.querySelectorAll("fieldset")[1];
    layout.classList.add("layout-choice");
    for (const button of layout.querySelectorAll("button")) {
      const value = button.dataset.value;
      button.innerHTML = `<span class="layout-preview preview-${value}" aria-hidden="true">${Array.from({length: 4}, () => '<span><i></i><i></i><i></i></span>').join("")}</span><span>${button.textContent}</span>`;
      button.title = value === "standard" ? "Full-width categories" : value === "compact" ? "Categories packed to fit their contents" : "Categories arranged in two columns";
      // Standard and Compact render identically in List view.
      if (state.view === "list" && value === "compact") button.hidden = true;
    }
    const grouping = host.querySelector('[data-setting="group"]').closest("label");
    grouping.classList.add("inline-group");
    grouping.firstChild.textContent = "Group by";
    grouping.querySelector("select").setAttribute("aria-label", "Grouping");
    grouping.querySelector('[value="section"]').textContent = "Category";
    const collapse = host.querySelector('[data-action="collapse"]');
    collapse.querySelector("span").textContent = `${collapsed.size ? "Expand" : "Collapse"} all categories`;
    const sort = host.querySelector('[data-setting="sort"]').closest("label");
    const merge = host.querySelector('[data-setting="merge"]').closest("label");
    const categoryDetails = host.querySelector('[data-setting="count"]').closest("fieldset");
    function disclosure(id, title, nodes, before) {
      const details = document.createElement("details");
      details.className = "option-disclosure";
      details.dataset.section = id;
      details.open = openOptionSections.has(id);
      details.innerHTML = `<summary>${title}<span class="disclosure-chevron" aria-hidden="true">&rsaquo;</span></summary><div class="disclosure-content"></div>`;
      host.insertBefore(details, before);
      nodes.forEach(node => details.lastElementChild.append(node));
      details.addEventListener("toggle", () => {
        if (!details.isConnected) return;
        details.open ? openOptionSections.add(id) : openOptionSections.delete(id);
      });
    }
    disclosure("sorting", "Sorting & stacking", [sort, merge], sort);
    disclosure("details", "Category details", [...categoryDetails.querySelectorAll("label")], categoryDetails);
    categoryDetails.remove();
    host.lastElementChild.classList.add("sidebar-tools");
    if (sidebarConcept === "minimal") {
      view.querySelector('[data-value="icons"]').textContent = "Grid";
      view.querySelector('[data-value="list"]').textContent = "List";
      const choices = layout.querySelector(".segment");
      const menu = document.createElement("details");
      menu.className = "layout-menu";
      const selected = state.view === "list" && state.layout === "compact" ? "Standard" : state.layout[0].toUpperCase() + state.layout.slice(1);
      menu.innerHTML = `<summary aria-label="Layout: ${selected}">${selected}<span aria-hidden="true">⌄</span></summary>`;
      menu.append(choices);
      layout.append(menu);
      const tools = host.lastElementChild;
      disclosure("tools", "Tools", [...tools.querySelectorAll("button")], tools);
      tools.remove();
    }
  }
  if (restoreSetting) {
    const candidates = [...$("options").querySelectorAll("[data-setting]")];
    if (sidebarConcept === "minimal" && restoreSetting === "layout") $("options").querySelector(".layout-menu summary")?.focus({preventScroll: true});
    else candidates.find(el => el.dataset.setting === restoreSetting && el.dataset.value === restoreValue)?.focus({preventScroll: true});
  }
  $("settings").innerHTML = icon("cog") + "All Settings";
}
let listRowIndex = 0;
function itemNode(item) {
  const b = document.createElement("button");
  b.className = `item quality-${item.quality}`;
  if (state.view === "list") b.classList.toggle("striped", listRowIndex++ % 2 === 1);
  b.setAttribute("aria-pressed", "false");
  b.setAttribute("aria-label", `${item.name}, ${item.count}`);
  b.style.setProperty("--rarity-color", qualities[item.quality].color);
  b.innerHTML = `<span class="item-art"><img src="assets/items/${item.icon}.jpg" alt="" loading="eager">${state.view !== "list" && item.count > 1 ? `<span class="stack">${item.count}</span>` : ""}</span>${state.view === "list" ? `<span class="item-name">${item.name}</span><span class="item-quantity">${item.count}</span><span class="item-type">${item.category}</span><span class="item-value">${money(item.vendor * item.count)}</span>` : ""}`;
  b.addEventListener("mouseenter", () => tooltip(item, b));
  b.addEventListener("focus", () => tooltip(item, b));
  b.addEventListener("mouseleave", hideTooltip);
  b.addEventListener("blur", hideTooltip);
  b.addEventListener("click", () => {
    b.classList.toggle("selected");
    b.setAttribute("aria-pressed", String(b.classList.contains("selected")));
    tooltip(item, b);
  });
  return b;
}
function tooltip(item, target) {
  const t = $("tooltip");
  t.innerHTML = `<strong style="color:${qualities[item.quality].color}">${item.name}</strong><span>${qualities[item.quality].name} · ${item.category} · Stack of ${item.count}</span>${item.category === "Quest" ? '<span class="quest-note">Quest Item</span>' : ""}<span>Vendor value: ${money(item.vendor * item.count)}</span><span>Auction estimate: ${money(item.auction * item.count)}</span>${state.global ? `<span class="item-owners">${item.owners.map((o) => `${o.name}: ${o.count}`).join("<br>")}</span>` : ""}<span>Item Level ${item.level}</span><small>Sample item · Click to select</small>`;
  t.hidden = false;
  const r = target.getBoundingClientRect();
  t.style.left =
    Math.max(8, Math.min(innerWidth - t.offsetWidth - 8, r.right + 12)) + "px";
  t.style.top =
    Math.max(8, Math.min(innerHeight - t.offsetHeight - 8, r.top)) + "px";
}
function hideTooltip() {
  $("tooltip").hidden = true;
}
function category(group, isRecent = false) {
  const section = document.createElement("section");
  section.className = "category";
  section.dataset.name = group.name;
  const off = collapsed.has(group.name);
  const head = document.createElement("div");
  head.className = "category-header";
  const toggle = document.createElement("button");
  toggle.className = "category-toggle";
  toggle.setAttribute("aria-expanded", String(!off));
  toggle.innerHTML = `${icon(off ? "chev-right" : "chev-down")}<strong>${group.name}</strong>${state.count ? `<span class="count">(${group.items.length})</span>` : ""}`;
  toggle.onclick = () => {
    off ? collapsed.delete(group.name) : collapsed.add(group.name);
    renderInventory();
    options();
  };
  head.append(toggle);
  const line = document.createElement("span");
  line.className = "divider";
  head.append(line);
  if (isRecent) {
    const clear = document.createElement("button");
    clear.className = "clear-recent";
    clear.textContent = "Clear Recent";
    clear.onclick = () => {
      recent = false;
      renderInventory();
    };
    head.append(clear);
  } else {
    const value = document.createElement("span");
    value.className = "values";
    const v = group.items.reduce((s, i) => s + i.vendor * i.count, 0);
    value.innerHTML = [
      state.vendor && v ? money(v) : "",
      state.auction && v ? `<span class="ah">AH</span> ${money(v * 3)}` : "",
    ]
      .filter(Boolean)
      .join('<span class="value-separator"></span>');
    if (value.innerHTML) head.append(value);
  }
  section.append(head);
  if (!off) {
    const grid = document.createElement("div");
    grid.className = "items";
    if (state.view === "list") {
      const columns = document.createElement("div");
      columns.className = "list-columns";
      columns.innerHTML = '<span>Item</span><span class="item-quantity">Qty</span><span class="item-type">Type</span><span class="item-value">Vendor</span>';
      section.append(columns);
    }
    group.items.forEach((i) => grid.append(itemNode(i)));
    section.append(grid);
  }
  return section;
}
function alignHeaders() {
  const heads = [...document.querySelectorAll(".categories .category-header")];
  heads.forEach((h) => (h.style.minHeight = ""));
  if (state.layout === "standard" || state.view === "list" || innerWidth <= 620)
    return;
  const rows = new Map();
  for (const h of heads) {
    const y = Math.round(h.parentElement.getBoundingClientRect().top);
    if (!rows.has(y)) rows.set(y, []);
    rows.get(y).push(h);
  }
  for (const row of rows.values()) {
    const height = Math.max(
      ...row.map((h) => h.getBoundingClientRect().height),
    );
    row.forEach((h) => (h.style.minHeight = height + "px"));
  }
}
function renderInventory() {
  listRowIndex = 0;
  hideTooltip();
  const list = inventory(state, query, rare),
    host = $("inventory");
  host.replaceChildren();
  host.dataset.layout = state.layout;
  host.dataset.view = state.view;
  if (recent && state.tab === "All" && list.some((i) => i.recent)) {
    const r = category(
      { name: "Recent", items: list.filter((i) => i.recent) },
      true,
    );
    r.classList.add("recent");
    host.append(r);
  }
  const area = document.createElement("div");
  area.className = "categories";
  for (const group of groups(list, state)) {
    const section = category(group);
    if (state.layout === "compact" && state.view === "icons")
      section.style.setProperty(
        "--category-width",
        `${Math.min(6, Math.max(2, group.items.length)) * (state.size + state.gap) - state.gap}px`,
      );
    area.append(section);
  }
  host.append(area);
  if (!list.length) {
    const empty = document.createElement("div");
    empty.className = "empty";
    empty.innerHTML = `${icon("pouch")}<strong>${query || rare || state.rarity !== "all" || state.filterCategory !== "all" ? "No matching items" : "Your bags are empty"}</strong><span>${query || rare || state.rarity !== "all" || state.filterCategory !== "all" ? "Try another search or turn off the quality filter." : "Choose another sample inventory to keep exploring."}</span>`;
    host.append(empty);
  }
  $("tabs").innerHTML = [
    "All",
    "Gear",
    "Consumables",
    "Trade Goods",
    "Quest",
    "Junk",
    "Gear Sets",
    "Bank",
  ]
    .map(
      (t) =>
        `<button data-tab="${t}" aria-current="${state.tab === t ? "page" : "false"}">${t}</button>`,
    )
    .join("");
  const character = characters.find((c) => c.id === state.character);
  $("money").innerHTML = money(
    state.global ? characters.reduce((n, c) => n + c.gold, 0) : character.gold,
  );
  $("bagbar").innerHTML = icon("bagbar");
  $("space").innerHTML =
    icon("pouch") +
    ` ${sourceInventory(state).length} / ${state.global ? characters.reduce((n, c) => n + c.capacity, 0) : Math.max(character.capacity, sourceInventory(state).length)}`;
  requestAnimationFrame(alignHeaders);
}
function renderCurrencies() {
  $("currencies").hidden = !state.currencyOpen;
  const character = characters.find((c) => c.id === state.character);
  $("currency-owner").textContent = state.global
    ? "All Characters"
    : character.name;
  $("currency-gold").innerHTML = money(
    state.global ? characters.reduce((n, c) => n + c.gold, 0) : character.gold,
  );
  const rows = currencyRows(state.character, state),
    filter = $("currency-search").value.toLowerCase();
  const matching = rows.filter((c) => c.name.toLowerCase().includes(filter));
  $("track-item").innerHTML = trackableItems(state.character)
    .filter((i) => !state.trackedCurrencies.includes(i.key))
    .map((i) => `<option value="${i.key}">${i.name}</option>`)
    .join("");
  $("add-tracked").disabled = !$("track-item").options.length;
  const currencyArt = (c) =>
    c.itemIcon
      ? `<img class="ui-icon" src="assets/items/${c.itemIcon}.jpg" alt="">`
      : icon(c.icon);
  const row = (c) =>
    `<div class="wallet-row"><button data-pin="${c.id}" aria-label="${state.currencyPins.includes(c.id) ? "Unpin" : "Pin"} ${c.name}" aria-pressed="${state.currencyPins.includes(c.id)}">${icon("pin")}</button>${currencyArt(c)}<span title="${state.global && c.per ? c.per : c.name}">${c.name}</span><strong>${c.amount.toLocaleString()}</strong><span class="currency-actions">${state.currencyPins.includes(c.id) ? `<button data-move-pin="${c.id}" data-direction="-1" aria-label="Move ${c.name} up" ${state.currencyPins.indexOf(c.id) === 0 ? "disabled" : ""}>↑</button><button data-move-pin="${c.id}" data-direction="1" aria-label="Move ${c.name} down" ${state.currencyPins.indexOf(c.id) === state.currencyPins.length - 1 ? "disabled" : ""}>↓</button>` : ""}${c.tracked ? `<button data-untrack="${c.id}" aria-label="Stop tracking ${c.name}">×</button>` : ""}</span></div>`;
  $("currency-list").innerHTML =
    ["Pinned", "Wallet"]
      .map((group) => {
        const list =
          group === "Pinned"
            ? state.currencyPins
                .map((id) => matching.find((c) => c.id === id))
                .filter(Boolean)
            : matching.filter((c) => !state.currencyPins.includes(c.id));
        return list.length
          ? `<section class="wallet-group"><h3>${group}</h3>${list.map(row).join("")}</section>`
          : "";
      })
      .join("") || '<p class="muted">No matching currencies.</p>';
  $("pinned-currencies").innerHTML = state.currencyPins
    .map((id) => {
      const c = rows.find((c) => c.id === id);
      return `<button data-action="currencies" title="${c.name}: ${c.amount.toLocaleString()}" aria-label="Open currencies: ${c.name}">${currencyArt(c)} ${c.amount.toLocaleString()}</button>`;
    })
    .join("");
  $("money").setAttribute("aria-expanded", state.currencyOpen);
}
function render() {
  options();
  renderCurrencies();
  $("drawer").hidden = !state.drawer;
  $("toggle-drawer").setAttribute("aria-expanded", state.drawer);
  $("toggle-drawer").innerHTML = icon("pouch");
  $("search-icon").innerHTML = icon("search");
  $("filter").innerHTML = icon("set-filter");
  $("filter").setAttribute(
    "aria-pressed",
    state.rarity !== "all" || state.filterCategory !== "all",
  );
  $("scenario").value = state.scenario;
  $("character").innerHTML = characters
    .map((c) => `<option value="${c.id}">${c.name} · ${c.level}</option>`)
    .join("");
  $("character").value = state.character;
  $("character").title = characters.find((c) => c.id === state.character).role;
  $("rarity").innerHTML =
    '<option value="all">All Rarities</option>' +
    qualities.map((q, i) => `<option value="${i}">${q.name}</option>`).join("");
  $("rarity").value = state.rarity;
  document.body.dataset.skin = state.skin;
  document.documentElement.style.setProperty(
    "--bag-font",
    fonts.find((f) => f.id === state.font).family,
  );
  document.documentElement.style.setProperty(
    "--heading-font",
    fonts.find((f) => f.id === state.headingFont).family,
  );
  document.fonts.ready.then(() => requestAnimationFrame(alignHeaders));
  $("bag-heading").textContent = state.global
    ? state.tab === "Bank"
      ? "Global Bank"
      : "Global Inventory"
    : state.tab === "Bank"
      ? "Bank"
      : state.travel
        ? "Travel Bags"
        : "Bags";
  $("exit-travel").hidden = !state.travel;
  $("workspace").classList.toggle("travel-mode", state.travel);
  $("inventory-status").innerHTML =
    state.tab === "Gear Sets"
      ? select("gearSet", "Gear Set", [
          ["all", "All Gear Sets"],
          ["dungeon", "Dungeon Set"],
          ["raid", "Raid Set"],
        ])
      : state.global
        ? "<span>All characters · Hover an item for its owners</span>"
        : "";
  $("bag").style.width = (state.travel ? 640 : state.width) + "px";
  $("workspace").style.setProperty(
    "--height",
    (state.travel ? 480 : state.height) + "px",
  );
  document.documentElement.style.setProperty("--item-size", state.size + "px");
  document.documentElement.style.setProperty("--gap", state.gap + "px");
  document.documentElement.style.setProperty(
    "--panel-opacity",
    state.opacity / 100,
  );
  renderInventory();
}
function notify(text) {
  $("toast").textContent = text;
  $("toast").classList.add("visible");
  clearTimeout(notify.timer);
  notify.timer = setTimeout(() => $("toast").classList.remove("visible"), 2600);
}
function modal(title, content) {
  $("dialog-title").textContent = title;
  $("dialog-content").innerHTML = content;
  $("dialog").showModal();
}
function settings() {
  modal(
    "Appearance",
    `<p>Adjust the demo’s appearance. Use Copy View Link to share these settings.</p>${select(
      "skin",
      "Skin",
      [
        ["modern", "Modern"],
        ["classic", "Classic"],
      ],
    )}${select(
      "font",
      "Interface Font",
      fonts.map((f) => [f.id, f.label]),
    )}${select(
      "headingFont",
      "Category Header Font",
      fonts.map((f) => [f.id, f.label]),
    )}<div class="font-preview"><strong>Consumables (17)</strong><span>BagSmith · Vendor Value · 1,234</span></div>${[
      ["size", "Item Size", 32, 64],
      ["gap", "Item Spacing", 4, 20],
      ["opacity", "Background Opacity", 65, 100],
      ["height", "Window Height", 360, 1000],
    ]
      .map(
        ([key, label, min, max]) =>
          `<label class="range-label">${label}<output id="out-${key}">${state[key]}</output><input type="range" min="${min}" max="${max}" value="${state[key]}" data-range="${key}"></label>`,
      )
      .join(
        "",
      )}<p class="muted">This is a browser simulation. Values and items are sample data; changes do not modify the installed addon.</p>`,
  );
}
document.addEventListener("click", (event) => {
  const target = event.target.closest("button");
  if (!target) return;
  if (target.dataset.pin) {
    const id = target.dataset.pin;
    state.currencyPins = state.currencyPins.includes(id)
      ? state.currencyPins.filter((p) => p !== id)
      : [...state.currencyPins, id];
    save();
    renderCurrencies();
    const button = document.querySelector(`[data-pin="${id}"]`);
    if (button) button.focus();
    return;
  }
  if (target.dataset.setting) set(target.dataset.setting, target.dataset.value);
  if (target.dataset.tab) set("tab", target.dataset.tab);
  if (target.dataset.movePin) {
    const i = state.currencyPins.indexOf(target.dataset.movePin),
      j = i + Number(target.dataset.direction);
    if (i >= 0 && j >= 0 && j < state.currencyPins.length) {
      [state.currencyPins[i], state.currencyPins[j]] = [
        state.currencyPins[j],
        state.currencyPins[i],
      ];
      save();
      renderCurrencies();
    }
    return;
  }
  if (target.dataset.untrack) {
    state.trackedCurrencies = state.trackedCurrencies.filter(
      (k) => k !== target.dataset.untrack,
    );
    state.currencyPins = state.currencyPins.filter(
      (k) => k !== target.dataset.untrack,
    );
    save();
    renderCurrencies();
    return;
  }
  switch (target.dataset.action) {
    case "clear-filters":
      state.rarity = "all";
      state.filterCategory = "all";
      rare = false;
      query = "";
      $("search").value = "";
      save();
      render();
      $("dialog").close();
      break;
    case "collapse":
      collapsed = collapsed.size
        ? new Set()
        : new Set([
            "Recent",
            ...groups(inventory(state, query, rare), state).map((g) => g.name),
          ]);
      render();
      break;
    case "cleanup":
      set("sort", "quality");
      notify("Bags sorted by quality");
      break;
    case "gear":
      set("tab", "Gear Sets");
      break;
    case "bank":
      set("tab", state.tab === "Bank" ? "All" : "Bank");
      break;
    case "currencies":
      set("currencyOpen", !state.currencyOpen);
      if (state.currencyOpen) $("close-currencies").focus();
      break;
    case "global":
      state.global = !state.global;
      state.travel = false;
      state.tab = "All";
      state.group = "section";
      save();
      render();
      break;
    case "travel":
      state.travel = !state.travel;
      state.global = false;
      state.drawer = false;
      state.currencyOpen = false;
      save();
      render();
      break;
  }
});
document.addEventListener("change", (event) => {
  const t = event.target;
  if (t.dataset.setting)
    set(t.dataset.setting, t.type === "checkbox" ? t.checked : t.value);
});
document.addEventListener("input", (event) => {
  const t = event.target;
  if (t.dataset.range) {
    set(t.dataset.range, Number(t.value));
    $("out-" + t.dataset.range).textContent = t.value;
  }
});
new ResizeObserver((entries) => {
  const b = entries[0].target;
  const r = b.getBoundingClientRect();
  if (!r.width || !r.height || state.travel) return;
  if (!state.travel) state.width = Math.round(r.width);
  state.height = Math.round(r.height);
  $("workspace").style.setProperty(
    "--height",
    (state.travel ? 480 : state.height) + "px",
  );
  save();
  requestAnimationFrame(alignHeaders);
}).observe($("bag"));
$("toggle-drawer").onclick = () => set("drawer", !state.drawer);
$("money").onclick = () => set("currencyOpen", !state.currencyOpen);
$("close-currencies").onclick = () => {
  set("currencyOpen", false);
  $("money").focus();
};
$("currency-search").oninput = renderCurrencies;
$("restore-pins").onclick = () => {
  state.currencyPins = [...defaultPins];
  save();
  renderCurrencies();
};
$("close-drawer").onclick = () => set("drawer", false);
$("search").oninput = (e) => {
  query = e.target.value;
  renderInventory();
};
$("filter").onclick = () =>
  modal(
    "Inventory Filters",
    `${select("rarity", "Quality", [["all", "All Rarities"], ...qualities.map((q, i) => [String(i), q.name])])}${select("filterCategory", "Category", [["all", "All Categories"], ...["Gear", "Consumables", "Reagents", "Trade Goods", "Recipes", "Quest", "Camp", "Other"].map((c) => [c, c])])}<button data-action="clear-filters">Clear Filters</button>`,
  );
function switchFixture(key, value) {
  collapsed.clear();
  recent = true;
  query = "";
  rare = false;
  $("search").value = "";
  state.tab = "All";
  set(key, value);
}
$("scenario").onchange = (e) => switchFixture("scenario", e.target.value);
$("character").onchange = (e) => {
  state.global = false;
  state.scenario = "everyday";
  switchFixture("character", e.target.value);
};
$("rarity").onchange = (e) => {
  rare = false;
  set("rarity", e.target.value);
};
$("settings").onclick = settings;
$("dismiss").onclick = () => $("dialog").close();
$("dialog").onclick = (e) => {
  if (e.target === $("dialog")) $("dialog").close();
};
$("close-bag").onclick = () => {
  state.drawer = false;
  state.currencyOpen = false;
  save();
  render();
  $("workspace").hidden = true;
  $("reopen").hidden = false;
  hideTooltip();
};
$("reopen").onclick = () => {
  $("workspace").hidden = false;
  $("reopen").hidden = true;
};
$("reset").onclick = () => {
  state = validate();
  query = "";
  rare = false;
  recent = true;
  collapsed.clear();
  $("search").value = "";
  history.replaceState(null, "", location.pathname);
  save();
  render();
  for (const id of ["options", "currency-list", "inventory"])
    $(id).scrollTop = 0;
  clearTimeout(notify.timer);
  $("toast").classList.remove("visible");
};
$("share").onclick = async () => {
  const url =
    location.origin +
    location.pathname +
    "#" +
    encodeURIComponent(JSON.stringify(state));
  try {
    await navigator.clipboard.writeText(url);

    notify("View link copied");
  } catch {
    modal(
      "Share This View",
      '<p>Copy this link to open the same view.</p><textarea id="share-url" readonly></textarea>',
    );
    $("share-url").value = url;
    $("share-url").select();
  }
};
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") hideTooltip();
  if (
    e.key.toLowerCase() === "b" &&
    !["INPUT", "SELECT", "TEXTAREA"].includes(e.target.tagName) &&
    !$("dialog").open
  ) {
    e.preventDefault();
    set("drawer", !state.drawer);
  }
});
render();

$("appearance-shortcut").onclick = settings;
$("exit-travel").onclick = () => set("travel", false);
$("add-tracked").onclick = () => {
  const key = $("track-item").value;
  if (!key) return;
  state.trackedCurrencies = [...state.trackedCurrencies, key];
  state.currencyPins = [...state.currencyPins, key];
  save();
  renderCurrencies();
};
$("release-label").textContent = `Build ${RELEASE}`;
$("reload-demo").onclick = () => {
  save();
  const url = new URL(location.href);
  url.searchParams.set("v", Date.now());
  url.hash = "";
  location.replace(url);
};
async function checkRelease() {
  if (RELEASE === "development") return;
  try {
    const response = await fetch("release.json", { cache: "no-store" });
    if (!response.ok) return;
    const latest = await response.json();
    if (latest.release !== RELEASE) {
      $("reload-demo").textContent = "Update Available · Refresh";
      $("reload-demo").classList.add("update-ready");
    }
  } catch {}
}
window.addEventListener("focus", checkRelease);
setInterval(checkRelease, 45000);
checkRelease();

$("sidebar-concept").value = sidebarConcept;
$("sidebar-concept").addEventListener("change", event => {
  sidebarConcept = event.target.value;
  try { localStorage.setItem("bagsmith-sidebar-concept", sidebarConcept); } catch {}
  set("drawer", true);
  $("options").scrollTop = 0;
});

document.addEventListener("click", event => {
  const menu = $("options").querySelector(".layout-menu");
  if (menu && !menu.contains(event.target)) menu.open = false;
});
document.addEventListener("keydown", event => {
  const menu = $("options").querySelector(".layout-menu[open]");
  if (event.key === "Escape" && menu) { menu.open = false; menu.querySelector("summary").focus(); }
});
