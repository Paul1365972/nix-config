# llm-gateway

One gateway in front of several model providers.
It keeps the providers' keys on the server and gives each project its own key with a spending limit in USD.

## Use

A request reaches its provider byte for byte, but only when the gateway knows all of it: every top-level field, every tool's type, the query and the beta flags.
Anything else is refused by name, so nothing runs at a provider that the gateway cannot charge.
[api.rs](src/api.rs) lists what each API passes on.
The conversation itself, and what is inside a known field, pass on unread.

- `POST /{provider}/v1/messages` is Anthropic's Messages API.
- `POST /{provider}/v1/responses` is OpenAI's Responses API. A request must state `store` as false, for the gateway keeps nothing at a provider, and so cannot continue a stored response.
- `POST /v1/chat/completions` is Chat Completions for every provider that offers it, with the model named `provider/model`.
- `GET /v1/usage` shows what the calling key has spent of its limits, and `GET /v1/models` the models Chat Completions serves.

A key goes in `Authorization: Bearer` or in `x-api-key`.
The gateway's own address with a key's token after a `#` opens a page that shows the key's limits and spending, keeps the token in that browser, and walks through setting up a client.

OpenCode takes the gateway as the base URL of its own providers, with the gateway key from `/connect`:

```jsonc
{
  "providers": {
    "anthropic": { "settings": { "baseURL": "https://llm.paul.moe/anthropic/v1" } },
    "openai": { "settings": { "baseURL": "https://llm.paul.moe/openai/v1", "transport": "http" } },
    "google": {
      "settings": { "baseURL": "https://llm.paul.moe/v1" },
      "models": {
        "gemini-4-neon": { "package": "@opencode/ai/providers/openai-compatible", "modelID": "google/gemini-4-neon" },
      },
    },
  },
}
```

Google is served through Chat Completions, which reports its cached and thinking tokens, so OpenCode is pointed there model by model.
A client has to send a tool call back as it received it, with Google's signature, or Google refuses the request.

## Keys

The dashboard makes, changes, revokes, restores and deletes keys and shows what each has spent, by provider, model and day.
A key has a limit that resets every day, week or month, or never, which makes it a cap on all the key ever spends.
It may have tighter limits for single providers; a limit of 0 keeps it off a provider.
Days, weeks and months turn over at midnight UTC, weeks on Monday.
Spending is recorded under a key's name, so the name of a deleted key that has spent anything cannot be used again.
The dashboard listens on its own port and has no login, so it must only be reachable from a trusted network; saber serves it to the tailnet.
The dashboard shows a key's token and its link again whenever asked, so the store holds the tokens as they are.

## Limit

A request runs while its key has spent less than its limits, and is charged the usage its provider reports once the response ends.
A key can so pass a limit by the requests it has running when it reaches it, of which it may run only so many at once.
A response that is cut off, because its client left or its provider broke off, is charged only what its provider had reported by then; nothing is estimated.
Anthropic reports the input when a response starts, the others report nothing until it ends.
A client that leaves ends the request at the provider too.

A request that asks for a costlier service tier, speed or region is refused, so every request runs at the list price.
Web searches a provider runs are charged per search; its other tools are refused.

## Configure

Providers and models are declared in [llm-gateway.nix](../../modules/hosts/saber/services/llm-gateway.nix), with the providers' keys in `secrets/saber.yaml`.
Prices come from a pinned [models.dev](https://github.com/anomalyco/models.dev); `nix flake update models-dev` takes in new ones.
Keys and spending live in a [redb](https://github.com/cberner/redb) file under `/var/lib/llm-gateway`.
