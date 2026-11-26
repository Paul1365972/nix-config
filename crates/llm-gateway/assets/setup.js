import { button, copy, dot, escaped, iconCopyButton, icons, providerName, veiledToken } from "/shared.js";

const TOKEN_PLACE = "";
const clients = { opencode: "OpenCode", "open-webui": "Open WebUI", other: "Other clients" };
const modelFamilies = { anthropic: "Claude", google: "Gemini", openai: "GPT" };
const apis = {
  messages: {
    name: "Messages", reference: "https://platform.claude.com/docs/en/api/messages/create", addressAtProvider: "https://api.anthropic.com",
    supported: "text, inline images and PDFs, streaming, tools, thinking, prompt caching, structured output, web search and fetch, token counting",
    excluded: "Files API, batches, code execution, advisor tool, refusal fallback, fast mode",
  },
  responses: {
    name: "Responses", reference: "https://developers.openai.com/api/reference/resources/responses/methods/create", addressAtProvider: "https://api.openai.com",
    supported: "text, inline images and PDFs, streaming, tools, reasoning, prompt caching, structured output, web search, token counting",
    excluded: "Files API, stored responses and conversations, background mode, file search, code interpreter, image generation, other service tiers",
  },
  generate_content: {
    name: "Gemini API", reference: "https://aistudio.google.com/api-reference/generate-content", addressAtProvider: "https://generativelanguage.googleapis.com",
    supported: "text, inline images and PDFs, streaming, tools, thinking, automatic caching, structured output, token counting",
    excluded: "Files API, explicit caches, batches, Google Search and Maps grounding",
  },
};
const reasonsForExclusion = [
  ["Nothing stored at the provider.", "Every key shares one account per provider, so anything stored there could be reached by other key holders. Files still work when sent inline in the request."],
  ["Charged from reported usage.", "Your key is billed from the tokens and web searches the provider reports on each request. Features billed outside that report cannot be charged to your key."],
  ["Standard tiers only.", "Fast mode and other service tiers are refused, so every request runs at list price."],
];
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
  const exampleProvider = providers.find(({ api }) => api === "responses") ?? providers[0];
  return {
    token: TOKEN_PLACE,
    config: JSON.stringify({ providers: Object.fromEntries(providers.map(inOpenCode)) }, null, 2),
    run: `opencode run -m "${openCodeId(mostUsedProvider)}/${mostUsedModel}#high" "your task"`,
    connections: inOpenWebUi,
    ...Object.fromEntries(inOpenWebUi.map(({ provider, url }) => [`url-${provider}`, url])),
    outsideOpenWebUi,
    curl: messagesProvider && `curl ${origin}/${messagesProvider}/v1/messages \\\n  -H "x-api-key: ${TOKEN_PLACE}" \\\n  -H "anthropic-version: 2023-06-01" \\\n  -H "content-type: application/json" \\\n` +
      `  -d '{"model": "${mostUsed(modelsOf(messagesProvider).map((model) => [messagesProvider, model]))[1]}", "max_tokens": 64,\n       "messages": [{"role": "user", "content": "Say hi."}]}'`,
    example: exampleProvider && { atProvider: `${apis[exampleProvider.api].addressAtProvider}${exampleProvider.url.slice(exampleProvider.url.lastIndexOf("/"))}`, atGateway: exampleProvider.url },
    groups: providers.map(({ provider, api, url }) => ({
      title: `${dot(provider)}${providerName(provider)}`, models: modelsOf(provider).join(", "), api, address: `${origin}/${provider}`,
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
  const group = ({ title, models, api, address }) => `<li><h3>${title}<a href="${apis[api].reference}" target="_blank" rel="noreferrer">${apis[api].name.replace(/ API$/, "")} API reference</a></h3>` +
    `<p class="models">${escaped(models)}</p>` +
    `<div class="address-row"><span>Replaces <code>${apis[api].addressAtProvider}</code></span><span class="address"><code>${escaped(address)}</code>` +
    `${iconCopyButton("Copy the address", `data-action="copy-text" data-text="${escaped(address)}"`)}</span></div>` +
    `<dl class="facts"><dt>Supported</dt><dd>${apis[api].supported}</dd><dt>Excluded</dt><dd>${apis[api].excluded}</dd></dl></li>`;
  const panels = {
    opencode: `<ol class="steps">` +
      step("Merge this into <code>~/.config/opencode/opencode.jsonc</code>. Your key is already in it, and your existing providers and logins stay as they are. It needs OpenCode 2, which npm ships as <code>@opencode/cli</code>.", copies("config"), shown("config")) +
      step("Pick one of the added models in OpenCode, or run it from your terminal. The part after <code>#</code> sets the thinking effort.", copies("run"), shown("run")) + `</ol>`,
    "open-webui": `<ol class="steps">` +
      step(`In Open WebUI, open Admin Panel, then Settings, then Connections. Under OpenAI API, add ${text.connections.length === 1 ? "a connection" : "one connection for each address below"}.`) +
      text.connections.map(({ provider, api }) =>
        step(`For ${familyOf(provider)} models, paste this into the URL field and set the API type to ${apis[api].name}.`, copies(`url-${provider}`), shown(`url-${provider}`))).join("") +
      step(`Paste this into ${text.connections.length === 1 ? "its API Key field" : "the API Key field of each"}.`, copies("token"), shown("token")) + `</ol>` +
      (text.outsideOpenWebUi.length ? `<p class="note">Open WebUI speaks only OpenAI's formats, so ${and(text.outsideOpenWebUi.map(({ provider }) => familyOf(provider)))} models do not work through a connection, even though adding their address lists them. ` +
        `They need a pipe function that speaks the provider's own API.</p>` : ""),
    other: `<p class="lead">Replace the provider's address with the one below and keep any path after it` +
      (text.example ? `, so <code>${escaped(text.example.atProvider)}</code> becomes <code>${escaped(text.example.atGateway)}</code>` : "") + `. Use your key as the API key.</p>` +
      `<p class="lead">Each provider is served on its own API only. There is no Chat Completions endpoint, and no OpenAI-compatible endpoint for Claude or Gemini.</p>` +
      `<ul class="addresses">${text.groups.map(group).join("")}</ul>` +
      `<div class="reasons"><p>Why features are excluded</p><ul>${reasonsForExclusion.map(([rule, reason]) => `<li><b>${rule}</b> ${reason}</li>`).join("")}</ul></div>` +
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
