import {
  button, copy, copyButton, count, dayBars, decode, dot, element, escaped, icons, modelsSummary, modelsTable, morph, periods, pool,
  problemToast, providerName, request, resetWords, spendingTiles, sum, tiles, toast, tokenStrip, usd, whileBusy,
} from "/shared.js";

const REFRESH_INTERVAL_MILLISECONDS = 10000;
const openKeys = new Set(), shownTokens = new Set(), tokens = new Map();
const fields = element("key-form").elements;
let overview, editedKey = null, keyToRevoke = null;

const monthName = (month, options = { month: "long", year: "numeric" }) => new Date(`${month}-15T12:00:00Z`).toLocaleString("en", { ...options, timeZone: "UTC" });
const daysIn = (month) => new Date(Date.UTC(Number(month.slice(0, 4)), Number(month.slice(5)), 0)).getUTCDate();
const isThisMonth = () => overview.month === overview.months[0];
const tallies = (name) => Object.entries(overview.tallies[name] ?? {});
const spentIn = (modelTallies) => sum(modelTallies.map(([, tally]) => tally.cost_usd));
const spentByProvider = (modelTallies) => Object.fromEntries(overview.providers.map((provider) =>
  [provider, spentIn(modelTallies.filter(([model]) => model.split("/")[0] === provider))]));
const keyNamed = (name) => overview.keys.find((key) => key.name === name);
const usableKeys = () => overview.keys.filter((key) => !key.is_revoked);
const listed = (names) => (names.length > 2 ? `${names.length} keys` : names.join(" and "));

async function tokenOf(name) {
  if (!tokens.has(name)) tokens.set(name, (await request("GET", `/api/keys/${encodeURIComponent(name)}/token`)).token);
  return tokens.get(name);
}

function renderMonth() {
  const month = monthName(overview.month, { month: "long" });
  const everyTally = Object.values(overview.tallies).flatMap(Object.entries);
  const [total, byProvider] = [spentIn(everyTally), spentByProvider(everyTally)];
  const running = sum(usableKeys().map((key) => key.running_requests));
  const daysCounted = isThisMonth() ? Number(overview.today.slice(8)) : daysIn(overview.month);
  const reached = usableKeys().filter((key) => key.spent_usd >= key.limit_usd).map((key) => escaped(key.name));
  const keys = `${count(usableKeys().length)} ${usableKeys().length === 1 ? "key" : "keys"}`;
  const status = !isThisMonth() ? [`This month is over.`]
    : [`${keys}, ${running ? `${running} ${running === 1 ? "request" : "requests"} running now` : "no request running right now"}.`,
      reached.length ? `${listed(reached)} ${reached.length > 1 ? "have reached their limits" : "has reached its limit"}.` : ""];
  const providerRows = overview.providers.map((id) => {
    const requests = sum(everyTally.filter(([model]) => model.split("/")[0] === id).map(([, tally]) => tally.requests));
    return { id, spent: byProvider[id], words: `${count(requests)} ${requests === 1 ? "request" : "requests"}` };
  });
  return `<article class="pass" data-provider-scope><div class="pass-top">` +
    `<p class="balance">${usd(total)}<small>spent in ${month}</small></p>${status.filter(Boolean).map((words) => `<p class="status">${words}</p>`).join("")}` +
    dayBars({ spentByDay: overview.days, firstDay: `${overview.month}-01`, dayCount: daysIn(overview.month), today: overview.today, title: `Each day of ${month}`, isWide: true, summary: (spent) => `${usd(spent / daysCounted)} a day` }) +
    `</div><div class="seam"></div><div class="pass-bottom"><div class="label-row"><h3>Providers in ${month}</h3><span>${modelsSummary(everyTally)}</span></div>` +
    `${spendingTiles(providerRows, total)}</div></article>`;
}

function renderDetail(name, key, modelTallies) {
  const month = monthName(overview.month, { month: "long" });
  const models = `<div class="label-row"><h3>Models in ${month}</h3><span>${modelsSummary(modelTallies)}</span></div>` +
    modelsTable(modelTallies, `No requests in ${month}.`);
  if (!key || key.is_revoked) return models;
  const attributes = `data-name="${escaped(name)}"`;
  const strip = tokenStrip({
    id: name, prefix: key.token_prefix, secret: shownTokens.has(name) ? tokens.get(name).slice(key.token_prefix.length) : undefined, secretLength: key.token_secret_length,
    buttons: copyButton("Copy link", `data-action="copy-link" ${attributes}`, icons.link) + copyButton("Copy token", `data-action="copy-token" ${attributes}`),
  });
  const period = periods[key.limit_resets];
  const allowance = isThisMonth()
    ? `<div class="label-row"><h3>Allowance${period && ` ${period}`}</h3><span>${resetWords(key)}</span></div>${tiles(key)}` : "";
  return `${strip}${allowance}${models}<div class="detail-actions"><span>Up to ${key.limit_requests_at_once} requests at once.</span>` +
    button({ kind: "quiet danger small", label: "Revoke", attributes: `data-action="ask-revoke" ${attributes}` }) + `</div>`;
}

function renderRow(name, largestSpending) {
  const [key, modelTallies] = [keyNamed(name), tallies(name)];
  const isUsable = Boolean(key) && !key.is_revoked;
  const showsLimit = isUsable && isThisMonth();
  const spent = showsLimit ? key.spent_usd : spentIn(modelTallies);
  const hasReachedLimit = showsLimit && spent >= key.limit_usd;
  const below = !isUsable ? "revoked" : hasReachedLimit ? `<span class="flag">Limit reached</span>`
    : showsLimit && key.running_requests ? `<i class="live"></i>${key.running_requests} running` : "";
  const spending = showsLimit
    ? `<b class="${hasReachedLimit ? "reached" : ""}">${usd(spent)}</b> of ${usd(key.limit_usd)}<small>${periods[key.limit_resets] || "in total"}</small>`
    : `<b>${usd(spent)}</b><small>in ${monthName(overview.month, { month: "long" })}</small>`;
  const isOpen = openKeys.has(name);
  const attributes = `data-name="${escaped(name)}"`;
  const control = isUsable ? button({ kind: "ghost small", label: "Edit", attributes: `data-action="edit" ${attributes} aria-label="Edit ${escaped(name)}"` })
    : key ? button({ kind: "ghost small", label: "Restore", busy: "", attributes: `data-action="restore" ${attributes} aria-label="Restore ${escaped(name)}"` }) : "<span></span>";
  return `<li class="${isUsable ? "" : "revoked"}" data-key="${escaped(name)}" data-provider-scope><div class="row">` +
    `<button class="summary" data-name="${escaped(name)}" aria-expanded="${isOpen}">` +
    `<span class="name"><b>${escaped(name)}</b><small>${below}</small></span>` +
    pool(showsLimit ? key.spent_usd_by_provider : spentByProvider(modelTallies), showsLimit ? Math.max(key.limit_usd, spent) : largestSpending) +
    `<span class="spending">${spending}</span>${icons.chevron}</button>` +
    `${control}</div>` +
    `<div class="disclosure" ${isOpen ? "data-open" : ""}><div><div class="detail">${renderDetail(name, key, modelTallies)}</div></div></div></li>`;
}

function render() {
  const [newest, oldest] = [overview.months[0], overview.months.at(-1)];
  element("host").textContent = new URL(overview.public_url).host;
  element("month").textContent = monthName(overview.month);
  element("earlier").disabled = overview.month === oldest;
  element("later").disabled = overview.month === newest;
  const namesOf = (keys) => keys.map((key) => key.name).sort();
  const goneNames = Object.keys(overview.tallies).filter((name) => !keyNamed(name)).sort();
  const names = [...namesOf(usableKeys()), ...namesOf(overview.keys.filter((key) => key.is_revoked)), ...goneNames];
  const largestSpending = Math.max(0, ...names.map((name) => spentIn(tallies(name))));
  morph(element("month-pass"), renderMonth());
  morph(element("keys"), names.map((name) => renderRow(name, largestSpending)).join("") ||
    `<li class="nothing">No keys yet. Make one, then send its link to whoever will use it.</li>`);
}

async function load(month = overview?.month ?? "") {
  overview = await request("GET", `/api/overview${month ? `?month=${month}` : ""}`);
  render();
}

function openForm(key) {
  editedKey = key?.name ?? null;
  element("key-form").reset();
  element("key-form").querySelector(".problem").textContent = "";
  element("key-title").textContent = key ? `Edit ${key.name}` : "New key";
  element("save").firstElementChild.textContent = key ? "Save changes" : "Create key";
  fields.key_name.value = key?.name ?? "";
  fields.key_name.disabled = Boolean(key);
  fields.limit_usd.value = key?.limit_usd ?? 10;
  fields.limit_resets.value = key?.limit_resets ?? "monthly";
  fields.limit_requests_at_once.value = key?.limit_requests_at_once ?? 4;
  const limits = key?.limit_usd_by_provider ?? {};
  element("provider-limits").innerHTML = [...new Set([...overview.providers, ...Object.keys(limits)])].map((provider) =>
    `<label><b>${dot(provider)}${providerName(provider)}</b><span class="dollars">` +
    `<input type="number" min="0" step="any" placeholder="Shares the limit" data-provider="${escaped(provider)}" value="${limits[provider] ?? ""}"></span></label>`).join("");
  element("key-dialog").showModal();
  (key ? fields.limit_usd : fields.key_name).select();
}

function settingsInForm() {
  const providerLimits = [...element("provider-limits").querySelectorAll("input")]
    .filter((limit) => limit.value !== "")
    .map((limit) => [limit.dataset.provider, Number(limit.value)]);
  return {
    limit_usd: Number(fields.limit_usd.value),
    limit_usd_by_provider: Object.fromEntries(providerLimits),
    limit_resets: fields.limit_resets.value,
    limit_requests_at_once: Number(fields.limit_requests_at_once.value),
  };
}

function showCreated(name, token) {
  tokens.set(name, token);
  element("created-title").textContent = `${name} is ready`;
  const link = `${overview.public_url}/#${token}`;
  element("created-token").innerHTML = `<div class="token"><code>${escaped(token)}</code>` +
    copyButton("Copy link", `data-action="copy-text" data-text="${escaped(link)}"`, icons.link) +
    copyButton("Copy token", `data-action="copy-text" data-text="${escaped(token)}"`) + `</div>`;
  element("created-dialog").showModal();
}

async function restore(name, control) {
  const restoring = () => request("POST", `/api/keys/${encodeURIComponent(name)}/restore`);
  await (control ? whileBusy(control, restoring) : restoring());
  toast(`Restored ${name}.`);
  await load();
}

async function act(control) {
  const { action, text } = control.dataset, name = control.dataset.name ?? control.dataset.id;
  if (action === "close-dialog") control.closest("dialog").close();
  if (action === "copy-text") await copy(text, control);
  if (action === "copy-token") await copy(await tokenOf(name), control);
  if (action === "copy-link") await copy(`${overview.public_url}/#${await tokenOf(name)}`, control);
  if (action === "edit") openForm(keyNamed(name));
  if (action === "restore") await restore(name, control);
  if (action === "ask-revoke") {
    keyToRevoke = name;
    element("revoke-title").textContent = `Revoke ${name}?`;
    element("revoke-dialog").showModal();
  }
  if (action === "reveal") {
    const isShown = !shownTokens.delete(name) && Boolean(await whileBusy(control, () => tokenOf(name))) && Boolean(shownTokens.add(name));
    render();
    if (isShown) decode(document.querySelector(`[data-secret="${CSS.escape(name)}"]`));
  }
}

document.addEventListener("click", (event) => {
  const control = event.target.closest("[data-action]");
  if (control) return act(control).catch(problemToast);
  const name = event.target.closest(".summary")?.dataset.name;
  if (!name) return;
  if (!openKeys.delete(name)) openKeys.add(name);
  if (openKeys.has(name) && keyNamed(name)) tokenOf(name).catch(() => {});
  render();
});
element("earlier").onclick = () => load(overview.months[overview.months.indexOf(overview.month) + 1]).catch(problemToast);
element("later").onclick = () => load(overview.months[overview.months.indexOf(overview.month) - 1]).catch(problemToast);
element("new-key").onclick = () => openForm(null);
element("revoke").onclick = () => whileBusy(element("revoke"), async () => {
  await request("DELETE", `/api/keys/${encodeURIComponent(keyToRevoke)}`);
  [openKeys, shownTokens, tokens].forEach((names) => names.delete(keyToRevoke));
  element("revoke-dialog").close();
  const name = keyToRevoke;
  toast(`Revoked ${name}.`, { action: "Undo", onAction: () => restore(name).catch(problemToast) });
  await load();
}).catch(problemToast);
element("key-form").onsubmit = (event) => {
  event.preventDefault();
  const words = element("key-form").querySelector(".problem");
  words.textContent = "";
  whileBusy(element("save"), async () => {
    const [name, settings] = [fields.key_name.value, settingsInForm()];
    if (editedKey) await request("PUT", `/api/keys/${encodeURIComponent(editedKey)}`, { body: settings });
    const created = editedKey ? null : await request("POST", "/api/keys", { body: { name, ...settings } });
    element("key-dialog").close();
    await load();
    if (created) showCreated(name, created.token); else toast(`Saved ${name}.`);
  }).catch((problem) => { words.textContent = problem.message; });
};

load("").catch(problemToast);
document.addEventListener("visibilitychange", () => { if (!document.hidden && overview && isThisMonth()) load("").catch(() => {}); });
setInterval(() => { if (!document.hidden && overview && isThisMonth()) load("").catch(() => {}); }, REFRESH_INTERVAL_MILLISECONDS);
