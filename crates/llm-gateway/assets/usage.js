import {
  button, copy, copyButton, dayAfter, dayBars, decode, element, escaped, lastingNotice, modelsSummary, modelsTable, morph,
  periods, pool, request, resetWords, tiles, toast, tokenStrip, unansweredNotice, usd, whileBusy,
} from "/shared.js";
import { actOnSetup, renderSetup } from "/setup.js";

const STORED_KEYS = "llm-gateway.keys";
const REFRESH_INTERVAL_MILLISECONDS = 30000;
const DAYS_SHOWN = 14;
const COLLAPSE_MILLISECONDS = 260;
const shownTokens = new Set();
let keys = [], answeredAt = null;

try { keys = JSON.parse(localStorage.getItem(STORED_KEYS)) ?? []; } catch { keys = []; }
keys.forEach((key) => { key.id = crypto.randomUUID(); });
const store = () => { try { localStorage.setItem(STORED_KEYS, JSON.stringify(keys.map(({ token, name }) => ({ token, name })))); } catch {} };
const tokenIn = (text) => decodeURIComponent(text.trim().split("#").at(-1));
const keyWith = (id) => keys.find((key) => key.id === id);

async function load(key) {
  try {
    key.usage = await request("GET", "/v1/usage", { token: key.token });
    key.name = key.usage.key;
    key.problem = null;
  } catch (problem) {
    key.problem = problem.status === 401 ? "revoked" : "unanswered";
  }
}

function renderUsage(usage) {
  const [spent, limit, period] = [usage.spent_usd, usage.limit_usd, periods[usage.limit_resets]];
  const over = spent > limit ? `, ${usd(spent - limit)} over because requests that were already running could finish` : "";
  const models = Object.entries(usage.models);
  return `<div class="hero"><div>` +
    `<p class="balance ${spent >= limit ? "reached" : ""}">${usd(Math.max(0, limit - spent))}<small>left${period && ` ${period}`}</small></p>` +
    `<p class="status"><b>${usd(spent)}</b> of ${usd(limit)} spent${over}.</p><p class="status">${resetWords(usage)}</p></div>` +
    dayBars({ spentByDay: usage.days, firstDay: dayAfter(usage.today, 1 - DAYS_SHOWN), dayCount: DAYS_SHOWN, today: usage.today, title: `Last ${DAYS_SHOWN} days` }) +
    `</div>${pool(usage.spent_usd_by_provider, Math.max(limit, spent))}</div><div class="seam"></div><div class="pass-bottom">` +
    `<div class="label-row"><h3>Providers</h3><span>What each can still spend</span></div>${tiles(usage)}` +
    `<div class="label-row"><h3>Models ${period || "so far"}</h3><span>${modelsSummary(models)}</span></div>` +
    modelsTable(models, `No requests ${period || "yet"}.`);
}

function renderKey(key) {
  const { id, token, usage } = key;
  const secretStart = token.lastIndexOf("-") + 1;
  const isRevoked = key.problem === "revoked";
  const flag = isRevoked ? "Revoked" : usage && usage.spent_usd >= usage.limit_usd ? "Limit reached" : "";
  const running = usage?.running_requests
    ? `<i class="live"></i>${usage.running_requests} of ${usage.limit_requests_at_once} requests running`
    : `Up to ${usage?.limit_requests_at_once} requests at once`;
  const strip = tokenStrip({
    id, prefix: token.slice(0, secretStart), secret: shownTokens.has(id) ? token.slice(secretStart) : undefined, secretLength: token.length - secretStart,
    buttons: copyButton("Copy token", `data-action="copy-token" data-id="${id}"`),
  });
  const body = isRevoked ? `<p class="status">This key is revoked and refused for now. It works again if it is restored; otherwise remove it here.</p>`
    : usage ? renderUsage(usage) : `<p class="status">The gateway has not answered for this key yet.</p>`;
  return `<div class="slot" data-key="${id}"><div><article class="pass" data-provider-scope><div class="pass-top">` +
    `<div class="pass-head"><div class="pass-title"><h2>${escaped(key.name ?? "New key")}</h2>` +
    `${flag ? `<span class="flag">${flag}</span>` : usage ? `<small>${running}</small>` : ""}</div>` +
    button({ kind: "quiet danger small", label: "Remove", attributes: `data-action="remove" data-id="${id}"` }) +
    `</div>${strip}${body}</div></article></div></div>`;
}

const emptyPass = `<div class="slot" data-key="empty"><div><article class="pass"><form class="dialog-body" data-add>` +
  `<h2>No keys in this browser yet</h2><p>Open the link you were sent, or paste a key's token or link here, to see what the key has left and what it was spent on.</p>` +
  `<div class="inline-form"><input type="text" name="token" required aria-label="Token or link" placeholder="A key or its link" autocomplete="off" spellcheck="false">` +
  button({ kind: "primary", label: "Add key", busy: "Checking" }) + `</div><p class="problem line" role="alert"></p></form></article></div></div>`;

function render() {
  morph(element("keys"), keys.map(renderKey).join("") || emptyPass);
  morph(element("setup"), renderSetup(keys));
  element("add-key").hidden = !keys.length;
  document.title = keys.length === 1 && keys[0].name ? `${keys[0].name} usage` : "Usage";
}

async function refresh() {
  await Promise.all(keys.map(load));
  if (keys.length && keys.every((key) => key.problem === "unanswered")) unansweredNotice(answeredAt);
  else lastingNotice(null), answeredAt = new Date();
  store();
  render();
}

async function add(token) {
  if (keys.some((key) => key.token === token)) return "This key is already here.";
  const key = { id: crypto.randomUUID(), token };
  await load(key);
  if (key.problem === "revoked") return "No key has this token. It may be incomplete or revoked.";
  if (key.problem) return "The gateway did not answer. Try again in a moment.";
  keys.push(key);
  store();
  render();
  document.querySelector(`[data-key="${key.id}"]`).scrollIntoView({ behavior: "smooth", block: "nearest" });
  return "";
}

async function takeKeyFromLink() {
  const token = tokenIn(location.hash.slice(1));
  if (!location.hash) return;
  history.replaceState(null, "", location.pathname);
  const problem = await add(token);
  if (problem && problem !== "This key is already here.") toast(problem, { isProblem: true });
}

function remove(key) {
  const [slot, place] = [document.querySelector(`[data-key="${key.id}"]`), keys.indexOf(key)];
  slot.dataset.uiLeaving = "";
  setTimeout(() => {
    keys = keys.filter((other) => other !== key);
    store();
    render();
  }, COLLAPSE_MILLISECONDS);
  toast(`Removed ${key.name ?? "the key"} from this browser.`, {
    action: "Undo",
    onAction: () => {
      keys.splice(Math.min(place, keys.length), 0, key);
      store();
      render();
    },
  });
}

document.addEventListener("click", (event) => {
  const control = event.target.closest("[data-action]");
  if (!control) return;
  const { action, id, text } = control.dataset;
  if (actOnSetup(control, keys)) render();
  if (action === "close-dialog") control.closest("dialog").close();
  if (action === "copy-text") copy(text, control);
  if (action === "copy-token") copy(keyWith(id).token, control);
  if (action === "remove") remove(keyWith(id));
  if (action === "reveal") {
    const isShown = !shownTokens.delete(id) && Boolean(shownTokens.add(id));
    render();
    if (isShown) decode(document.querySelector(`[data-secret="${id}"]`));
  }
});
document.addEventListener("submit", async (event) => {
  const form = event.target.closest("[data-add]");
  if (!form) return;
  event.preventDefault();
  const [words, input] = [form.querySelector(".problem"), form.elements.token];
  words.textContent = "";
  const problem = await whileBusy(form.querySelector(".primary"), () => add(tokenIn(input.value)));
  if (problem === undefined) return;
  words.textContent = problem;
  if (problem) return input.select();
  form.reset();
  form.closest("dialog")?.close();
});
element("add-key").onclick = () => {
  const dialog = element("add-dialog");
  dialog.querySelector("form").reset();
  dialog.querySelector(".problem").textContent = "";
  dialog.showModal();
};
addEventListener("hashchange", takeKeyFromLink);
document.addEventListener("visibilitychange", () => { if (!document.hidden) refresh(); });
setInterval(() => { if (!document.hidden) refresh(); }, REFRESH_INTERVAL_MILLISECONDS);

element("host").textContent = location.host;
if (!keys.length) render();
Promise.all([refresh(), takeKeyFromLink()]).then(() => requestAnimationFrame(() => document.body.classList.add("settled")));
