# llm-gateway

One gateway in front of several model providers.
It keeps the providers' keys on the server and gives each project its own key with a spending limit in USD.

## Use

Requests and responses pass through as they are, so caching, thinking, tools and files work as they do at the provider.

- `POST /{provider}/v1/messages` is Anthropic's Messages API.
- `POST /{provider}/v1/responses` is OpenAI's Responses API, without background responses.
- `POST /v1/chat/completions` is Chat Completions for every provider that offers it, with the model named `provider/model`.
- `GET /v1/usage` shows what the calling key has spent of its limits, and `GET /v1/models` the configured models.

A key goes in `Authorization: Bearer` or in `x-api-key`.
The gateway's own address with a key's token after a `#` opens a page that shows the key's limits and spending and keeps the token in that browser.

OpenCode takes the gateway as the base URL of its own providers, with the gateway key from `/connect`:

```jsonc
{
  "providers": {
    "anthropic": { "settings": { "baseURL": "https://llm.paul.moe/anthropic/v1" } },
    "openai": { "settings": { "baseURL": "https://llm.paul.moe/openai/v1", "transport": "http" } },
  },
}
```

Google is served only through Chat Completions so far.
Its own Interactions API takes another variant of `Api` in [api.rs](src/api.rs), a route in [http.rs](src/http.rs), and a base URL per API.

## Keys

The dashboard makes, changes, revokes, restores and deletes keys and shows what each has spent, by provider, model and day.
A key has a limit that resets every day, week or month, or never, which makes it a cap on all the key ever spends.
It may have tighter limits for single providers; a limit of 0 keeps it off a provider.
Days, weeks and months turn over at midnight UTC, weeks on Monday.
The dashboard listens on its own port and has no login, so it must only be reachable from a trusted network; saber serves it to the tailnet.
The dashboard shows a key's token and its link again whenever asked, so the store holds the tokens as they are.

## Limit

A request runs while its key has spent less than its limits, and is charged the usage its provider reports once the response ends.
A key can so pass a limit by the requests it has running when it reaches it, of which it may run only so many at once.
A response that ends without its usage, because its client left or its provider broke off, is charged an estimate.
A client that leaves ends the request at the provider too.

A request that asks for a costlier service tier, speed or region is refused, so every request runs at the list price.
Web searches a provider runs are charged per search; its other tools that bill per call are not counted.

## Configure

Providers and models are declared in [llm-gateway.nix](../../modules/hosts/saber/services/llm-gateway.nix), with the providers' keys in `secrets/saber.yaml`.
Prices come from a pinned [models.dev](https://github.com/anomalyco/models.dev); `nix flake update models-dev` takes in new ones.
Keys and spending live in a [redb](https://github.com/cberner/redb) file under `/var/lib/llm-gateway`.
