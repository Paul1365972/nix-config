import { button, copy, dot, escaped, iconCopyButton, icons, providerName, veiledToken } from "/shared.js";

const TOKEN_PLACE = "\u0000";
const clients = { opencode: "OpenCode", "open-webui": "Open WebUI", other: "Something else" };
const apiNames = { messages: "Messages", responses: "Responses", generate_content: "Gemini API" };
const OPENCODE_CHAT_PACKAGE = "@opencode/ai/providers/openai-compatible";
const INPUTS_CHAT_TAKES = ["text", "image"];
const CHAT_NAME = "Chat Completions";
let chosenClient = "opencode", chosenKey = null;

function texts(usage) {
  const origin = location.origin;
  const baseUrl = (provider, api) => `${origin}/${provider}/${api === "generate_content" ? "v1beta" : "v1"}`;
  const providers = Object.entries(usage.apis_by_provider);
  const modelsOf = (provider) => usage.models_by_provider[provider] ?? [];
  const withChat = providers.filter(([, apis]) => apis.includes("chat_completions")).map(([provider]) => provider);
  const mostUsed = (models) => models.toSorted((one, other) => (usage.models[other]?.cost_usd ?? 0) - (usage.models[one]?.cost_usd ?? 0))[0];
  const viaChat = (provider) => Object.fromEntries(modelsOf(provider).map((model) => [model, { package: OPENCODE_CHAT_PACKAGE, capabilities: { input: INPUTS_CHAT_TAKES } }]));
  const inOpenCode = ([provider, apis]) => {
    const native = ["generate_content", "responses", "messages"].find((api) => apis.includes(api));
    return [provider, {
      settings: { baseURL: baseUrl(provider, native), ...(native === "responses" && { transport: "http" }) },
      ...(!native && { models: viaChat(provider) }),
    }];
  };
  const messagesProvider = providers.find(([, apis]) => apis.includes("messages"))?.[0];
  return {
    token: TOKEN_PLACE,
    config: JSON.stringify({ providers: Object.fromEntries(providers.map(inOpenCode)) }, null, 2),
    run: `opencode run -m "${mostUsed(providers.flatMap(([provider]) => modelsOf(provider).map((model) => `${provider}/${model}`)))}#high" "your task"`,
    connectTo: providers.map(([provider]) => providerName(provider)),
    chatUrl: `${origin}/v1`,
    withoutChat: providers.filter(([provider]) => !withChat.includes(provider)).map(([provider]) => providerName(provider)),
    curl: messagesProvider && `curl ${origin}/${messagesProvider}/v1/messages \\\n  -H "x-api-key: ${TOKEN_PLACE}" \\\n  -H "anthropic-version: 2023-06-01" \\\n  -H "content-type: application/json" \\\n` +
      `  -d '{"model": "${mostUsed(modelsOf(messagesProvider).map((model) => `${messagesProvider}/${model}`)).split("/")[1]}", "max_tokens": 64,\n       "messages": [{"role": "user", "content": "Say hi."}]}'`,
    rows: [
      ...providers.flatMap(([provider, apis]) => apis.toSorted((one, other) => (one in apiNames ? 0 : 1) - (other in apiNames ? 0 : 1))
        .map((api) => [`${dot(provider)}${providerName(provider)} ${apiNames[api] ?? CHAT_NAME}`, baseUrl(provider, api), modelsOf(provider).join(", ")])),
      ["Messages, Responses or Chat Completions, at one address", `${origin}/v1`, "provider/model"],
    ],
  };
}

const setupKey = (keys) => {
  const usable = keys.filter((key) => key.usage && key.problem !== "revoked");
  return [usable.find((key) => key.id === chosenKey) ?? usable[0], usable];
};
const and = (names) => (names.length > 1 ? `${names.slice(0, -1).join(", ")} and ${names.at(-1)}` : names.join(""));

export function renderSetup(keys) {
  const [key, usable] = setupKey(keys);
  if (!key) return "";
  const text = texts(key.usage);
  const shown = (snippet) => `<pre>${escaped(text[snippet]).replaceAll(TOKEN_PLACE, veiledToken(key.token))}</pre>`;
  const copies = (snippet, label = "Copy") =>
    button({ kind: "ghost small", label, done: "Copied", icon: icons.copy, attributes: `data-action="copy-setup" data-snippet="${snippet}"` });
  const step = (words, control = "", field = "") => `<li><div><div class="line"><p>${words}</p>${control}</div>${field}</div></li>`;
  const panels = {
    opencode: `<ol class="steps">` +
      step("Add the gateway to <code>~/.config/opencode/opencode.jsonc</code>", copies("config"), shown("config")) +
      step(`Run <code>/connect</code> in OpenCode and paste the token, once for ${and(text.connectTo)}`, copies("token", "Copy token")) +
      step("Pick a model, as provider/model#effort", copies("run"), shown("run")) + `</ol>`,
    "open-webui": `<ol class="steps">` +
      step("In Open WebUI, open the admin Settings, then Connections, and add a connection under OpenAI API") +
      step("URL", copies("chatUrl"), shown("chatUrl")) +
      step("API Key", copies("token", "Copy token"), shown("token")) + `</ol>` +
      (text.withoutChat.length ? `<p class="note">Open WebUI speaks Chat Completions only, so ${and(text.withoutChat)} models are not available in it through this gateway.</p>` : ""),
    other: `<div class="scroll"><table><thead><tr><th>A client that speaks</th><th>Base URL</th><th class="wide-only">Models</th></tr></thead><tbody>` +
      text.rows.map(([name, url, models]) => `<tr><td>${name}</td><td><span class="address"><code>${escaped(url)}</code>` +
        `${iconCopyButton("Copy the address", `data-action="copy-text" data-text="${escaped(url)}"`)}</span></td><td class="wide-only quiet">${escaped(models)}</td></tr>`).join("") +
      `</tbody></table></div>` +
      (text.curl ? `<div class="line"><p>Try it from a shell</p>${copies("curl")}</div>${shown("curl")}` : "") +
      `<p class="note">The token is the API key. Fast and priority tiers, other regions, tools the provider bills apart, and anything kept at the provider are refused. A request you cancel still runs to its end and is charged. With the OpenAI Agents SDK, set <code>OPENAI_AGENTS_DISABLE_TRACING=1</code>, or it sends this key to OpenAI.</p>`,
  };
  const choice = (action, value, label, isChosen) =>
    `<button data-action="${action}" data-value="${escaped(value)}" aria-pressed="${isChosen}">${escaped(label)}</button>`;
  const keyChoices = usable.length > 1
    ? `<div class="choices" role="group" aria-label="The key the steps use"><span>For the key</span>${usable.map((other) => choice("choose-setup-key", other.id, other.name, other === key)).join("")}</div>` : "";
  const tabs = Object.entries(clients).map(([client, name]) =>
    `<button role="tab" data-action="choose-client" data-value="${client}" aria-selected="${client === chosenClient}">${name}</button>`).join("");
  return `<section class="pass setup"><div class="pass-top"><div class="pass-head"><div class="pass-title"><h2>Set up a client</h2></div>${keyChoices}</div>` +
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
