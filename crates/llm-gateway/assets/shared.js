export const element = (id) => document.getElementById(id);
export const escaped = (text) => String(text).replace(/[&<>"']/g, (character) => `&#${character.charCodeAt(0)};`);

const dollars = new Intl.NumberFormat("en", { style: "currency", currency: "USD" });
const exactly = new Intl.NumberFormat("en");
const roughly = new Intl.NumberFormat("en", { notation: "compact", maximumSignificantDigits: 3 });
const relatively = new Intl.RelativeTimeFormat("en", { numeric: "always" });
export const usd = (amount) => (amount > 0 && amount < 0.005 ? "&lt;$0.01" : dollars.format(amount));
export const count = (number) => exactly.format(number);
const compact = (number) => !number ? `<span class="none">–</span>`
  : number < 10000 ? count(number) : `<span title="${count(number)}">${roughly.format(number)}</span>`;
export const sum = (amounts) => amounts.reduce((total, amount) => total + amount, 0);

const midnightUtc = (day) => new Date(`${day}T00:00:00Z`);
export const dayAfter = (day, days) => new Date(midnightUtc(day).getTime() + days * 86400000).toISOString().slice(0, 10);
const dayName = (day) => midnightUtc(day).toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short", timeZone: "UTC" });
const clock = (moment) => moment.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
function fromNow(moment) {
  const minutes = Math.max(1, Math.round((moment - Date.now()) / 60000));
  if (minutes < 90) return relatively.format(minutes, "minute");
  if (minutes < 36 * 60) return relatively.format(Math.round(minutes / 60), "hour");
  return relatively.format(Math.round(minutes / 1440), "day");
}

export const icons = {
  copy: `<svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5.5" y="5.5" width="8" height="8" rx="2"/><path d="M10.5 5.5v-1a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v4a2 2 0 0 0 2 2h1"/></svg>`,
  link: `<svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6.8 9.2a3 3 0 0 0 4.2 0l2-2a3 3 0 0 0-4.2-4.2l-.6.6"/><path d="M9.2 6.8a3 3 0 0 0-4.2 0l-2 2a3 3 0 0 0 4.2 4.2l.6-.6"/></svg>`,
  check: `<svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m3 8.5 3.2 3.2L13 4.8"/></svg>`,
  eye: `<svg class="when-idle" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1.5 8S4 3.5 8 3.5 14.5 8 14.5 8 12 12.5 8 12.5 1.5 8 1.5 8Z"/><circle cx="8" cy="8" r="2"/></svg>`,
  eyeClosed: `<svg class="when-pressed" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1.5 8S4 3.5 8 3.5 14.5 8 14.5 8 12 12.5 8 12.5 1.5 8 1.5 8Z"/><path d="m3 2.5 10 11"/></svg>`,
  chevron: `<svg class="chevron" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 3 5 5-5 5"/></svg>`,
};

const knownProviders = { anthropic: "Anthropic", google: "Google", openai: "OpenAI" };
function provider(id) {
  if (id in knownProviders) return { name: knownProviders[id], color: `var(--${id})` };
  const hash = [...id].reduce((hash, character) => Math.imul(hash ^ character.charCodeAt(0), 16777619) >>> 0, 2166136261);
  return { name: escaped(id), color: `var(--other-${hash % 6})` };
}
export const providerName = (id) => provider(id).name;
const providerOf = (model) => model.split("/")[0];
export const dot = (id) => `<i class="dot" style="--color:${provider(id).color}" aria-hidden="true"></i>`;
export const periods = { daily: "today", weekly: "this week", monthly: "this month", never: "" };

export function button({ kind = "ghost", label, done, busy, icon = "", attributes = "" }) {
  return `<button class="button ${kind}" ${attributes}><span class="face">${icon}<span class="words">${label}</span></span>` +
    (done ? `<span class="face done" aria-hidden="true">${icons.check}<span class="words">${done}</span></span>` : "") +
    (busy ? `<span class="face busy" aria-hidden="true"><i class="spinner"></i>${busy}</span>` : "") + `</button>`;
}
export const copyButton = (label, attributes, icon = icons.copy) => button({ kind: "ghost", label, done: "Copied", icon, attributes });
export const iconCopyButton = (label, attributes) =>
  `<button class="icon-button" ${attributes} aria-label="${label}" title="${label}"><span class="when-idle">${icons.copy}</span><span class="when-done">${icons.check}</span></button>`;

const standInForEverySecret = [...crypto.getRandomValues(new Uint8Array(96))].map((byte) => (byte % 16).toString(16)).join("");
export function veiledToken(token) {
  const secretStart = token.lastIndexOf("-") + 1;
  return `${escaped(token.slice(0, secretStart))}<span class="veiled" aria-hidden="true">${standInForEverySecret.slice(0, token.length - secretStart)}</span>`;
}
export function tokenStrip({ id, prefix, secret, secretLength, buttons }) {
  const isShown = secret !== undefined;
  return `<div class="token-row"><div class="token"><code><span>${escaped(prefix)}</span>` +
    `<span class="secret ${isShown ? "" : "veiled"}" data-secret="${escaped(id)}" ${isShown ? "" : `aria-hidden="true"`}>${isShown ? escaped(secret) : standInForEverySecret.slice(0, secretLength)}</span></code>` +
    `<button class="icon-button" data-action="reveal" data-id="${escaped(id)}" aria-pressed="${isShown}" aria-label="Show the token">${icons.eye}${icons.eyeClosed}<i class="spinner"></i></button></div>${buttons}</div>`;
}
export function decode(secret) {
  const text = secret.textContent, started = performance.now(), duration = matchMedia("(prefers-reduced-motion: reduce)").matches ? 0 : 420;
  const step = (now) => {
    const settled = Math.floor(text.length * Math.min(1, (now - started) / duration));
    const unsettled = [...text.slice(settled)].map(() => "0123456789abcdef"[Math.floor(Math.random() * 16)]).join("");
    secret.textContent = text.slice(0, settled) + unsettled;
    if (settled < text.length && secret.isConnected) requestAnimationFrame(step);
  };
  if (duration) requestAnimationFrame(step);
}

export function pool(spentByProvider, scale) {
  const segments = Object.entries(spentByProvider).filter(([, spent]) => spent > 0).map(([id, spent]) =>
    `<i data-provider="${escaped(id)}" style="--share:${100 * spent / (scale || 1)}%;--color:${provider(id).color}"></i>`);
  return `<div class="pool" aria-hidden="true">${segments.join("")}</div>`;
}

function headroom(key, id) {
  const keyLeft = Math.max(0, key.limit_usd - key.spent_usd);
  const [spent, limit] = [key.spent_usd_by_provider[id] ?? 0, key.limit_usd_by_provider[id]];
  if (limit === 0) return { state: "off", spent, left: 0 };
  if (limit === undefined) return { state: keyLeft ? "shared" : "key-reached", spent, left: keyLeft };
  const ownLeft = Math.max(0, limit - spent);
  if (!ownLeft) return { state: "reached", spent, limit, left: 0 };
  if (keyLeft < ownLeft) return { state: keyLeft ? "held" : "key-reached", spent, limit, left: keyLeft, heldBack: ownLeft - keyLeft };
  return { state: "own", spent, limit, left: ownLeft };
}
function tile(key, id) {
  const { state, spent, limit, left, heldBack } = headroom(key, id);
  const scale = limit ?? Math.max(key.limit_usd, key.spent_usd);
  const share = (amount) => `--share:${scale ? Math.min(100, 100 * amount / scale) : 0}%`;
  const amount = limit === undefined ? `${usd(spent)} spent` : `${usd(spent)} of ${usd(limit)}`;
  const [leftClass, words] = {
    off: ["", spent ? `${usd(spent)} spent before it was switched off` : "Switched off for this key"],
    shared: ["shared", `${amount}, shares the key's limit`],
    own: ["", amount],
    held: ["held", `${amount}, held back by the key's limit`],
    reached: ["reached", `${amount}, its limit is reached`],
    "key-reached": ["reached", `${amount}, the key's limit is reached`],
  }[state];
  const bar = state === "off" ? ""
    : `${spent ? `<i class="spent" style="${share(spent)}"></i>` : ""}` + (limit === undefined
      ? `<i class="others" style="${share(key.spent_usd - spent)}"></i><i class="open"></i>`
      : `<i class="open"></i>${heldBack ? `<i class="held" style="${share(heldBack)}"></i>` : ""}`);
  const head = state === "off" ? `<span class="switched-off">Off</span>` : `<span class="${leftClass}">${usd(left)} left</span>`;
  return `<li class="tile ${state === "off" ? "off" : ""}" data-provider="${escaped(id)}" style="--color:${provider(id).color}">` +
    `<div class="tile-head"><b>${dot(id)}${providerName(id)}</b>${head}</div><div class="tile-bar" aria-hidden="true">${bar}</div><p>${words}</p></li>`;
}
export const spendingTiles = (rows, total) => `<ul class="tiles">${rows.map(({ id, spent, words }) =>
  `<li class="tile" data-provider="${escaped(id)}" style="--color:${provider(id).color}"><div class="tile-head"><b>${dot(id)}${providerName(id)}</b><span>${usd(spent)}</span></div>` +
  `<div class="tile-bar" aria-hidden="true">${spent ? `<i class="spent" style="--share:${100 * spent / total}%"></i>` : ""}</div><p>${words}</p></li>`).join("")}</ul>`;
export const tiles = (key) => `<ul class="tiles">${Object.keys(key.spent_usd_by_provider).map((id) => tile(key, id)).join("")}</ul>`;

export function resetWords(key) {
  const hasReachedLimit = key.spent_usd >= key.limit_usd;
  if (!key.limit_resets_on) return hasReachedLimit ? "This limit does not reset, so the key is used up." : "This limit does not reset.";
  const moment = midnightUtc(key.limit_resets_on);
  const when = `${fromNow(moment)}, on ${moment.toLocaleString("en-GB", { weekday: "long", day: "numeric", month: "long", hour: "2-digit", minute: "2-digit" })}`;
  return hasReachedLimit ? `Requests are refused until the limit resets ${when}.` : `Resets ${when}.`;
}

export function modelsSummary(tallies) {
  const [requests, uncached, read] = ["requests", "uncached_input_tokens", "cache_read_tokens"].map((field) => sum(tallies.map(([, tally]) => tally[field])));
  if (!requests) return "";
  const fromCache = read ? `, ${(100 * read / (uncached + read)).toFixed(1)}% of input read from cache` : "";
  return `${count(requests)} ${requests === 1 ? "request" : "requests"}${fromCache}`;
}
export function modelsTable(tallies, wordsWhenEmpty) {
  if (!tallies.length) return `<p class="note">${wordsWhenEmpty}</p>`;
  const fields = ["requests", "uncached_input_tokens", "cache_read_tokens", "cache_write_tokens", "output_tokens", "web_searches"];
  const total = Object.fromEntries([...fields, "cost_usd", "unfinished_requests"].map((field) => [field, sum(tallies.map(([, tally]) => tally[field]))]));
  const shown = fields.filter((field) => field !== "web_searches" || total.web_searches);
  const wideOnly = (field) => (field === "requests" ? "" : ` class="wide-only"`);
  const cells = (tally) => shown.map((field) => `<td${wideOnly(field)}>${compact(tally[field])}</td>`).join("") + `<td>${usd(tally.cost_usd)}</td>`;
  const sorted = [...tallies].sort(([, one], [, other]) => other.cost_usd - one.cost_usd);
  const rows = sorted.map(([model, tally]) => `<tr><td>${dot(providerOf(model))}${escaped(model.split("/")[1] ?? model)}</td>${cells(tally)}</tr>`).join("");
  const unfinished = total.unfinished_requests ? `<p class="note">${count(total.unfinished_requests)} ${total.unfinished_requests === 1
    ? "request was cut off before its provider reported all of its usage, so only what was reported is counted."
    : "requests were cut off before their provider reported all of their usage, so only what was reported is counted."}</p>` : "";
  const names = { requests: "Requests", uncached_input_tokens: "Input", cache_read_tokens: "Cache read", cache_write_tokens: "Cache write", output_tokens: "Output", web_searches: "Searches" };
  return `<div class="scroll"><table><thead><tr><th>Model</th>${shown.map((field) => `<th${wideOnly(field)}>${names[field]}</th>`).join("")}<th>Spent</th></tr></thead><tbody>${rows}</tbody>` +
    `${tallies.length > 1 ? `<tfoot><tr><td>Total</td>${cells(total)}</tr></tfoot>` : ""}</table></div>${unfinished}`;
}

export function dayBars({ spentByDay, firstDay, dayCount, today, title, isWide, summary = (total) => usd(total) }) {
  const days = Array.from({ length: dayCount }, (_, index) => dayAfter(firstDay, index));
  const totalOf = (day) => sum(Object.values(spentByDay[day] ?? {}));
  const [largest, total] = [Math.max(...days.map(totalOf)), sum(days.map(totalOf))];
  const columns = days.map((day) => {
    const segments = Object.entries(spentByDay[day] ?? {}).filter(([, spent]) => spent > 0)
      .map(([id, spent]) => `<i style="--share:${100 * spent / largest}%;--color:${provider(id).color}"></i>`).join("");
    if (day > today) return `<div class="day nothing ahead"><i></i></div>`;
    return `<div class="day ${segments ? "" : "nothing"}" data-readout="${dayName(day)}: ${usd(totalOf(day))}">${segments || "<i></i>"}</div>`;
  });
  return `<div class="days ${isWide ? "wide" : ""}"><div class="label-row"><h3>${title}</h3><span class="readout" data-default="${summary(total)}">${summary(total)}</span></div>` +
    `<div class="bars" role="img" aria-label="Spending per day, ${usd(total)} in all">${columns.join("")}</div></div>`;
}

const kindOf = (node) => (node.nodeType === Node.ELEMENT_NODE ? node.nodeName : node.nodeType);
const keyOf = (node) => (node.nodeType === Node.ELEMENT_NODE ? node.getAttribute("data-key") : null);
function morphNode(node, wanted) {
  if (node.nodeType !== Node.ELEMENT_NODE) {
    if (node.nodeValue !== wanted.nodeValue) node.nodeValue = wanted.nodeValue;
    return;
  }
  for (const { name } of [...node.attributes]) if (!wanted.hasAttribute(name) && !name.startsWith("data-ui-")) node.removeAttribute(name);
  for (const { name, value } of wanted.attributes) if (node.getAttribute(name) !== value) node.setAttribute(name, value);
  morphChildren(node, wanted);
}
function morphChildren(parent, wantedParent) {
  const keyed = new Map([...parent.children].filter(keyOf).map((child) => [keyOf(child), child]));
  let next = parent.firstChild;
  for (const wanted of [...wantedParent.childNodes]) {
    const key = keyOf(wanted);
    const kept = key ? keyed.get(key) : next && !keyOf(next) && kindOf(next) === kindOf(wanted) ? next : null;
    if (!kept || kindOf(kept) !== kindOf(wanted)) { parent.insertBefore(wanted, next); continue; }
    if (kept === next) next = next.nextSibling; else parent.insertBefore(kept, next);
    morphNode(kept, wanted);
  }
  while (next) { const following = next.nextSibling; next.remove(); next = following; }
}
export function morph(target, html) {
  const wanted = document.createElement("template");
  wanted.innerHTML = html;
  morphChildren(target, wanted.content);
}

const flashes = new WeakMap();
function flash(control) {
  clearTimeout(flashes.get(control));
  control.dataset.uiState = "done";
  flashes.set(control, setTimeout(() => delete control.dataset.uiState, 1800));
}
export async function copy(text, control) {
  try {
    await navigator.clipboard.writeText(text);
    flash(control);
    announce("Copied");
  } catch {
    toast("The browser blocked copying. Show the text and copy it by hand.", { isProblem: true });
  }
}
export async function whileBusy(control, work) {
  if (control.dataset.uiState === "busy") return;
  control.dataset.uiState = "busy";
  control.disabled = true;
  try {
    return await work();
  } finally {
    delete control.dataset.uiState;
    control.disabled = false;
  }
}

function announce(words) {
  const region = element("announcements") ?? document.body.appendChild(Object.assign(document.createElement("div"), { id: "announcements", className: "hidden-from-sight" }));
  region.setAttribute("aria-live", "polite");
  region.textContent = words;
}
const toasts = () => element("toasts") ?? document.body.appendChild(Object.assign(document.createElement("div"), { id: "toasts", className: "toasts" }));
let toastTimer;
export function toast(words, { action, onAction, isProblem = false, milliseconds = 6000 } = {}) {
  const leave = (shown) => { shown.classList.add("leaving"); setTimeout(() => shown.remove(), 240); };
  toasts().querySelectorAll(".toast:not(.lasting)").forEach(leave);
  const shown = Object.assign(document.createElement("div"), { className: `toast ${isProblem ? "problem-tone" : ""}`, textContent: words });
  shown.setAttribute("role", isProblem ? "alert" : "status");
  if (action) shown.append(Object.assign(document.createElement("button"), { textContent: action, onclick: () => { leave(shown); onAction(); } }));
  toasts().append(shown);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => leave(shown), milliseconds);
}
export function lastingNotice(words) {
  const shown = toasts().querySelector(".lasting");
  if (!words) return shown?.remove();
  const notice = shown ?? toasts().insertAdjacentElement("afterbegin", Object.assign(document.createElement("div"), { className: "toast lasting" }));
  notice.setAttribute("role", "alert");
  notice.textContent = words;
}
export const unansweredNotice = (figuresFrom) => lastingNotice(`The gateway is not answering.${figuresFrom ? ` These figures are from ${clock(figuresFrom)}.` : ""}`);
export const problemToast = (problem) => toast(problem.message, { isProblem: true });

export async function request(method, path, { body, token } = {}) {
  const headers = { ...(body && { "content-type": "application/json" }), ...(token && { authorization: `Bearer ${token}` }) };
  let response;
  try {
    response = await fetch(path, { method, headers, body: body && JSON.stringify(body) });
  } catch {
    throw Object.assign(new Error("The gateway did not answer. Try again in a moment."), { isUnreachable: true });
  }
  if (!response.ok) throw Object.assign(new Error((await response.json().catch(() => ({}))).error?.message ?? `The gateway answered ${response.status}.`), { status: response.status });
  return response.status === 204 ? null : response.json();
}

document.addEventListener("click", (event) => { if (event.target.matches("dialog[open]")) event.target.close(); });
document.addEventListener("wheel", (event) => { if (event.target.type === "number" && event.target === document.activeElement) event.target.blur(); }, { passive: true });
let highlighted = [null, undefined];
document.addEventListener("pointerover", (event) => {
  const day = event.target.closest?.(".day[data-readout]");
  if (day) day.closest(".days").querySelector(".readout").textContent = day.dataset.readout;
  const scope = event.target.closest?.("[data-provider-scope]") ?? null;
  const id = scope ? event.target.closest("[data-provider]")?.dataset.provider : undefined;
  if (highlighted[0] === scope && highlighted[1] === id) return;
  highlighted = [scope, id];
  document.querySelectorAll("[data-ui-hover], [data-ui-hot]").forEach((lit) => { delete lit.dataset.uiHover; delete lit.dataset.uiHot; });
  if (!id) return;
  scope.dataset.uiHover = id;
  scope.querySelectorAll(`[data-provider="${CSS.escape(id)}"]`).forEach((hot) => { hot.dataset.uiHot = ""; });
});
document.addEventListener("pointerout", (event) => {
  const bars = event.target.closest?.(".bars");
  if (!bars || bars.contains(event.relatedTarget)) return;
  const readout = bars.closest(".days").querySelector(".readout");
  readout.textContent = readout.dataset.default;
});
