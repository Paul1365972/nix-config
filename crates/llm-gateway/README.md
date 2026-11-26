# llm-gateway

One gateway in front of several model providers.
It keeps the providers' keys on the server and gives each project its own key with a spending limit in USD.

## Use

The gateway checks each request's top-level fields and query, and refuses tools that use stored state or have charges the gateway cannot meter.
Anthropic beta flags pass through except `server-side-fallback-…`, which lets another model answer at another price.
Refusals are logged with the key's name.
[api.rs](src/api.rs) lists the allowed fields and refused tools for each API.

The gateway keeps nothing at a provider and reaches nothing kept there.
It refuses a request that asks to be stored, continues a stored response, or refers to a stored file or item, so a key can spend its limit and do nothing else.

- `POST /{provider}/v1/messages` is Anthropic's Messages API.
- `POST /{provider}/v1/responses` is OpenAI's Responses API.
  The gateway states `store` as false where a request leaves it out.
- `POST /{provider}/v1/chat/completions` is Chat Completions, for every provider that offers it.
- Each of the three also answers without the provider in its address, as `POST /v1/…` with the model named `provider/model`.
- `POST /{provider}/v1/messages/count_tokens` and `POST /{provider}/v1/responses/input_tokens` count tokens, uncharged as at the provider.
- `POST /{provider}/v1beta/models/{model}:generateContent` is Google's Gemini API.
- `POST /{provider}/v1beta/models/{model}:streamGenerateContent?alt=sse` streams a Gemini answer.
- `POST /{provider}/v1beta/models/{model}:countTokens` counts Gemini tokens, uncharged.
- `GET /{provider}/v1beta/models` lists the models of a provider that serves the Gemini API.
- `GET /{provider}/v1/models` lists a provider's models, and `GET /v1/models` those Chat Completions serves.
- `GET /v1/usage` shows what the calling key has spent of its limits.

Gemini requests take their model from the path and require the provider in the address.
The streaming route requires `alt=sse`, and the other Gemini routes accept no query.
The gateway serves no files, batches, embeddings or stored conversations.
A client that speaks only another provider's API needs a translator on its own side, such as a LiteLLM proxy pointed at the gateway.

A key goes in `Authorization: Bearer`, `x-api-key`, or `x-goog-api-key`.
The gateway's own address with a key's token after a `#` opens a page that shows the key's limits and spending, keeps the token in that browser, and walks through setting up a client.

OpenCode takes the gateway as providers of their own beside the ones it has, so a login it already holds keeps working.
Each names the provider whose models and API it borrows, and lists the models the gateway serves:

```jsonc
{
  "providers": {
    "paulmoe-anthropic": {
      "canonical": "anthropic",
      "settings": { "baseURL": "https://llm.paul.moe/anthropic/v1", "apiKey": "…" },
      "models": { "claude-opus-5-5": {} },
    },
    "paulmoe-openai": {
      "canonical": "openai",
      "settings": { "baseURL": "https://llm.paul.moe/openai/v1", "apiKey": "…", "transport": "http" },
      "models": { "gpt-6.2-sol": {} },
    },
    "paulmoe-google": {
      "canonical": "google",
      "settings": { "baseURL": "https://llm.paul.moe/google/v1beta", "apiKey": "…" },
      "models": { "gemini-4-neon": {} },
    },
  },
}
```

The usage page writes this block out in full for a key.
A program built on the OpenAI Agents SDK should set `OPENAI_AGENTS_DISABLE_TRACING=1`, or the SDK sends the gateway's key to OpenAI.

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
A client that leaves does not end its request: the gateway reads the provider's response to its end and charges it in full, and the request counts as running until then.
Hanging up early is so no way to a response the key does not pay for.
A response its provider breaks off, or one cut by the gateway stopping, is charged only what the provider had reported by then; nothing is estimated.

A request that asks for a costlier service tier, speed or region is refused, so every request runs at the list price.
Web searches on Messages and Responses are charged per search.

## Configure

Providers and models are declared in [llm-gateway.nix](../../modules/hosts/saber/services/llm-gateway.nix), with the providers' keys in `secrets/saber.yaml`.
`key_prefix` starts every new key, and `client_provider_prefix` starts the names the usage page gives the gateway's providers in a client; both are short words of their own, not taken from the host.
Each provider's `base_urls` maps the APIs it serves to their upstream base URLs.
For Google, `generate_content` uses `https://generativelanguage.googleapis.com/v1beta` and `chat_completions` uses `https://generativelanguage.googleapis.com/v1beta/openai`.
Prices come from a pinned [models.dev](https://github.com/anomalyco/models.dev); `nix flake update models-dev` takes in new ones.
Keys and spending live in a [redb](https://github.com/cberner/redb) file under `/var/lib/llm-gateway`.
