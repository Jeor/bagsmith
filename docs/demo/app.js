import { fonts } from "./fonts.js";
import { currencyRows, defaultPins, panelState } from "./currencies.js";
import { characters, qualities, sampleInventory } from "./fixtures.js";
import { defaults } from "./data.js";
import { validate, inventory, groups } from "./model.js";
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
function options() {
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
      ["newest", "Newest"],
      ["off", "Off"],
    ]) +
    check("merge", "Merge Stacks") +
    `<fieldset><legend>Category Details</legend>${check("count", "Item Count")}${check("vendor", "Vendor Value")}${check("auction", "Auction Value")}</fieldset><fieldset><legend>Tools</legend>${[
      ["broom", "Clean Up Bags", "cleanup"],
      ["sword-shield", "Gear Sets", "gear"],
      ["bank", "Bank", "bank"],
      ["wallet", "Currencies", "currencies"],
      ["globe", "Global Inventory", "global"],
      ["signpost", "Travel Mode", "travel"],
    ]
      .map(
        ([i, t, a]) =>
          `<button class="tool" data-action="${a}">${icon(i)}<span>${t}</span></button>`,
      )
      .join("")}</fieldset>`;
  $("settings").innerHTML = icon("cog") + "All Settings";
}
function itemNode(item) {
  const b = document.createElement("button");
  b.className = `item quality-${item.quality}`;
  b.setAttribute("aria-label", `${item.name}, ${item.count}`);
  b.style.setProperty("--rarity-color", qualities[item.quality].color);
  b.innerHTML = `<span class="item-art"><img src="assets/items/${item.icon}.jpg" alt="" loading="eager">${item.count > 1 ? `<span class="stack">${item.count}</span>` : ""}</span>${state.view === "list" ? `<span class="item-name">${item.name}</span><span class="item-value">${money(item.vendor * item.count)}</span>` : ""}`;
  b.addEventListener("mouseenter", () => tooltip(item, b));
  b.addEventListener("focus", () => tooltip(item, b));
  b.addEventListener("mouseleave", hideTooltip);
  b.addEventListener("blur", hideTooltip);
  b.addEventListener("click", () => {
    b.classList.toggle("selected");
    tooltip(item, b);
  });
  return b;
}
function tooltip(item, target) {
  const t = $("tooltip");
  t.innerHTML = `<strong style="color:${qualities[item.quality].color}">${item.name}</strong><span>${qualities[item.quality].name} · ${item.category} · Stack of ${item.count}</span>${item.category === "Quest" ? '<span class="quest-note">Quest Item</span>' : ""}<span>Vendor value: ${money(item.vendor * item.count)}</span><span>Auction estimate: ${money(item.auction * item.count)}</span><small>Sample item · Click to select</small>`;
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
    empty.innerHTML = `${icon("pouch")}<strong>${query || rare ? "No matching items" : "Your bags are empty"}</strong><span>${query || rare ? "Try another search or turn off the quality filter." : "Choose another sample inventory to keep exploring."}</span>`;
    host.append(empty);
  }
  $("tabs").innerHTML = [
    "All",
    "Gear",
    "Consumables",
    "Trade Goods",
    "Quest",
    "Junk",
    "Bank",
  ]
    .map(
      (t) =>
        `<button data-tab="${t}" aria-current="${state.tab === t ? "page" : "false"}">${t}</button>`,
    )
    .join("");
  const character = characters.find((c) => c.id === state.character);
  $("money").innerHTML = money(character.gold);
  $("bagbar").innerHTML = icon("bagbar");
  $("space").innerHTML =
    icon("pouch") +
    ` ${sampleInventory(state).length} / ${Math.max(character.capacity, sampleInventory(state).length)}`;
  requestAnimationFrame(alignHeaders);
}
function renderCurrencies() {
  $("currencies").hidden = !state.currencyOpen;
  const character = characters.find((c) => c.id === state.character);
  $("currency-owner").textContent = character.name;
  $("currency-gold").innerHTML = money(character.gold);
  const rows = currencyRows(state.character),
    filter = $("currency-search").value.toLowerCase();
  const matching = rows.filter((c) => c.name.toLowerCase().includes(filter));
  const row = (c) =>
    `<div class="wallet-row"><button data-pin="${c.id}" aria-label="${state.currencyPins.includes(c.id) ? "Unpin" : "Pin"} ${c.name}" aria-pressed="${state.currencyPins.includes(c.id)}">${icon("pin")}</button>${icon(c.icon)}<span>${c.name}</span><strong>${c.amount.toLocaleString()}</strong></div>`;
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
      return `<button data-action="currencies" title="${c.name}: ${c.amount.toLocaleString()}" aria-label="Open currencies: ${c.name}">${icon(c.icon)} ${c.amount.toLocaleString()}</button>`;
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
  $("filter").setAttribute("aria-pressed", rare);
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
  $("bag").style.width = state.width + "px";
  $("workspace").style.setProperty("--height", state.height + "px");
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
  switch (target.dataset.action) {
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
      set("tab", "Gear");
      break;
    case "bank":
      set("tab", state.tab === "Bank" ? "All" : "Bank");
      break;
    case "currencies":
      set("currencyOpen", !state.currencyOpen);
      if (state.currencyOpen) $("close-currencies").focus();
      break;
    case "global":
      modal(
        "Global Inventory",
        `<p>Sample characters</p>${characters.map((c) => `<div class="currency-row">${c.name}<span>${c.role}<br>${sampleInventory({ ...defaults, character: c.id }).length} slots</span></div>`).join("")}<p class="muted">Switch characters with the picker in the bag title. These are sample inventories.</p>`,
      );
      break;
    case "travel":
      set("drawer", false);
      notify("Travel Mode: options tucked away");
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
  if (!r.width || !r.height) return;
  state.width = Math.round(r.width);
  state.height = Math.round(r.height);
  $("workspace").style.setProperty("--height", state.height + "px");
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
$("filter").onclick = () => {
  rare = !rare;
  render();
};
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
  state = { ...defaults };
  query = "";
  rare = false;
  recent = true;
  collapsed.clear();
  $("search").value = "";
  history.replaceState(null, "", location.pathname);
  save();
  render();
};
$("share").onclick = async () => {
  const url =
    location.origin +
    location.pathname +
    "#" +
    encodeURIComponent(JSON.stringify(state));
  try {
    await navigator.clipboard.writeText(url);
    history.replaceState(null, "", url);
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
