# fx port for ppos

[Simplified Chinese](README.zh-CN.md)

This directory is the reproducible ppos port of fx 0.0.6. It does not vendor
the upstream source or a generated WASM binary. `SOURCE.lock` pins the reviewed
source archive, while `fx-ppos.patch` and `src/providers/deepseek.zig` contain
the local changes.

The port keeps fx's terminal UI, agent loop, sessions, and tool dispatch. For
the WASM terminal build only, it replaces the Vercel AI Gateway wire protocol
with DeepSeek's OpenAI-compatible Chat Completions protocol. Native fx behavior
is intentionally unchanged.

## Contract

- Default model: `deepseek-v4-flash`.
- Default base URL: `https://api.deepseek.com`.
- Public configuration: `DEEPSEEK_BASE_URL`; only HTTPS URLs without userinfo,
  query, or fragment are accepted.
- Secret input: `DEEPSEEK_API_KEY`; it is supplied by the runtime and is never
  a build input.
- Streaming: content, reasoning, fragmented tool calls, finish reason,
  generation identity, and token usage are decoded from OpenAI-compatible SSE.
- DeepSeek reasoning needed for a tool continuation is carried through fx's
  provider-neutral `provider_state_json`; no process-global cache is used.
- Host ABI: unchanged from the upstream `fx-term.wasm` import set.

The ppos host owns the setup screen, secret lifetime, TLS trust, network
transport, and cancellation. The WASM module owns no persistent plaintext key.

## Build

Use the reviewed archive:

```bash
FX_ARCHIVE=/path/to/fx-0.0.6.zip \
ZIG=/path/to/zig \
    ports/fx-ppos/test.sh

FX_ARCHIVE=/path/to/fx-0.0.6.zip \
ZIG=/path/to/zig \
    ports/fx-ppos/build.sh
```

An extracted tree may be supplied with `FX_SOURCE=/path/to/fx-0.0.6` instead.
The artifact is written to `build/fx-ppos/fx-ppos.wasm` and remains ignored by
Git.

fx is licensed under Apache-2.0. The source archive retains its upstream
license and notices; this port records local modifications separately.
