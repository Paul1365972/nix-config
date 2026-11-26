import { button, copy, dot, escaped, iconCopyButton, icons, providerName, veiledToken } from "/shared.js";

const TOKEN_PLACE = "";
const clients = { opencode: "OpenCode", "open-webui": "Open WebUI", other: "Other clients" };
const modelFamilies = { anthropic: "Claude", google: "Gemini", openai: "GPT" };
const apiNames = { messages: "Messages", responses: "Responses", generate_content: "Gemini API" };
const familyOf = (provider) => modelFamilies[provider] ?? providerName(provider);
let chosenClient = "opencode", chosenKey = null;

function texts(usage) {
  const origin = location.origin;
  const openCodeId = (provider) => `${usage.client_provider_prefix}-${provider}`;
  const baseUrl = (provider, api) => `${origin}/${provider}/${api === "generate_content" ? "v1beta" : "v1"}`;
  const providers = Object.entries(usage.api_by_provider).map(([provider, api]) => ({ provider, api, url: baseUrl(provider, api) }));
  const modelsOf = (provider) => usage.models_by_provider[provider] ?? [];
  const inOpenWebUi = providers.filter(({ api }) => api === "responses");
  const outsideOpenWebUi = providers.filter(({ api }) => api !== "responses");
  const mostUsed = (models) => models.toSorted((one, other) => (usage.models[other.join("/")]?.cost_usd ?? 0) - (usage.models[one.join("/")]?.cost_usd ?? 0))[0];
  const [mostUsedProvider, mostUsedModel] = mostUsed(providers.flatMap(({ provider }) => modelsOf(provider).map((model) => [provider, model]))) ?? [];
  const inOpenCode = ({ provider, api, url }) => [openCodeId(provider), {
    canonical: provider,
    name: `${providerName(provider)} via ${location.hostname}`,
    settings: { baseURL: url, apiKey: TOKEN_PLACE, ...(api === "responses" && { transport: "http" }) },
    models: Object.fromEntries(modelsOf(provider).map((name) => [name, {}])),
  }];
  const messagesProvider = providers.find(({ api }) => api === "messages")?.provider;
  return {
    token: TOKEN_PLACE,
    config: JSON.stringify({ providers: Object.fromEntries(providers.map(inOpenCode)) }, null, 2),
    run: `opencode run -m "${openCodeId(mostUsedProvider)}/${mostUsedModel}#high" "your task"`,
    connections: inOpenWebUi,
    ...Object.fromEntries(inOpenWebUi.map(({ provider, url }) => [`url-${provider}`, url])),
    outsideOpenWebUi,
    curl: messagesProvider && `curl ${origin}/${messagesProvider}/v1/messages \\\n  -H "x-api-key: ${TOKEN_PLACE}" \\\n  -H "anthropic-version: 2023-06-01" \\\n  -H "content-type: application/json" \\\n` +
      `  -d '{"model": "${mostUsed(modelsOf(messagesProvider).map((model) => [messagesProvider, model]))[1]}", "max_tokens": 64,\n       "messages": [{"role": "user", "content": "Say hi."}]}'`,
    groups: providers.map(({ provider, api, url }) => ({
      title: `${dot(provider)}${providerName(provider)}`, models: modelsOf(provider).join(", "), api, url,
    })),
  };
}

const setupKey = (keys) => {
  const usable = keys.filter((key) => key.usage && key.problem !== "revoked");
  return [usable.find((key) => key.id === chosenKey) ?? usable[0], usable];
};
const and = (names) => (names.length > 1 ? `${names.slice(0, -1).join(", ")} and ${names.at(-1)}` : names.join(""));

function keyPicker(usable, chosen) {
  if (usable.length < 2) return "";
  const widestName = usable.map((key) => `<span aria-hidden="true">${escaped(key.name)}</span>`).join("");
  const option = (key) => `<button role="option" data-action="choose-setup-key" data-value="${escaped(key.id)}" aria-selected="${key === chosen}">${escaped(key.name)}${icons.check}</button>`;
  return `<div class="picker"><span id="setup-key-label">Key to use</span>` +
    `<button aria-haspopup="listbox" aria-labelledby="setup-key-label setup-key-name"><span class="names">${widestName}<span id="setup-key-name">${escaped(chosen.name)}</span></span>${icons.chevron}</button>` +
    `<div class="picker-menu" role="listbox" aria-labelledby="setup-key-label">${usable.map(option).join("")}</div></div>`;
}

export function renderSetup(keys) {
  const [key, usable] = setupKey(keys);
  if (!key) return "";
  const text = texts(key.usage);
  const shown = (snippet) => `<pre>${escaped(text[snippet]).replaceAll(TOKEN_PLACE, veiledToken(key.token))}</pre>`;
  const copies = (snippet, label = "Copy") =>
    button({ kind: "ghost small", label, done: "Copied", icon: icons.copy, attributes: `data-action="copy-setup" data-snippet="${snippet}"` });
  const step = (words, control = "", field = "") => `<li><div><div class="line"><p>${words}</p>${control}</div>${field}</div></li>`;
  const group = ({ title, models, api, url }) => `<li><h3>${title}</h3><p class="models">${escaped(models)}</p>` +
    `<div class="address-row"><span>${apiNames[api]}</span><span class="address"><code>${escaped(url)}</code>` +
    `${iconCopyButton("Copy the base URL", `data-action="copy-text" data-text="${escaped(url)}"`)}</span></div></li>`;
  const panels = {
    opencode: `<ol class="steps">` +
      step("Merge this into <code>~/.config/opencode/opencode.jsonc</code>. Your key is already in it, and your existing providers and logins stay as they are. It needs OpenCode 2, which npm ships as <code>@opencode/cli</code>.", copies("config"), shown("config")) +
      step("Pick one of the added models in OpenCode, or run it from your terminal. The part after <code>#</code> sets the thinking effort.", copies("run"), shown("run")) + `</ol>`,
    "open-webui": `<ol class="steps">` +
      step(`In Open WebUI, open Admin Panel, then Settings, then Connections. Under OpenAI API, add ${text.connections.length === 1 ? "a connection" : "one connection for each address below"}.`) +
      text.connections.map(({ provider, api }) =>
        step(`For ${familyOf(provider)} models, paste this into the URL field and set the API type to ${apiNames[api]}.`, copies(`url-${provider}`), shown(`url-${provider}`))).join("") +
      step(`Paste this into ${text.connections.length === 1 ? "its API Key field" : "the API Key field of each"}.`, copies("token"), shown("token")) + `</ol>` +
      (text.outsideOpenWebUi.length ? `<p class="note">Open WebUI speaks only OpenAI's formats, so ${and(text.outsideOpenWebUi.map(({ provider }) => familyOf(provider)))} models do not work through a connection, even though adding their address lists them. ` +
        `They need a pipe function that speaks the provider's own API.</p>` : ""),
    other: `<p class="lead">Point your client or SDK at the base URL for its API format, and use your key as the API key.</p>` +
      `<ul class="addresses">${text.groups.map(group).join("")}</ul>` +
      (text.curl ? `<div class="line"><p>Test it with curl</p>${copies("curl")}</div>${shown("curl")}` : ""),
  };
  const tabs = Object.entries(clients).map(([client, name]) =>
    `<button role="tab" data-action="choose-client" data-value="${client}" aria-selected="${client === chosenClient}">${name}</button>`).join("");
  return `<section class="pass setup"><div class="pass-top"><div class="pass-head"><div class="pass-title"><h2>Connect a client</h2></div>${keyPicker(usable, key)}</div>` +
    `<div class="tabs" role="tablist">${tabs}</div><div class="panels">` +
    Object.entries(panels).map(([client, panel]) => `<div role="tabpanel" ${client === chosenClient ? "data-shown" : ""}>${panel}</div>`).join("") +
    `</div></div></section>`;
}

export function actOnSetup(control, keys) {
  const { action, value, snippet } = control.dataset;
  if (action === "choose-client") chosenClient = value;
  if (action === "choose-setup-key") chosenKey = value;
  if (action === "copy-setup") {
    const [key] = setupKey(keys);
    copy(texts(key.usage)[snippet].replaceAll(TOKEN_PLACE, key.token), control);
  }
  return action === "choose-client" || action === "choose-setup-key";
}
