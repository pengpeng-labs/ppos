# Changelog

## 0.3.0

- Compose osrt 0.1.1 and WAMR 2.4.5 as the capability-gated WASM application
  host.
- Add the reproducible fx 0.0.6 port with a direct DeepSeek
  OpenAI-compatible provider.
- Add pphttp 0.1.0 and a bounded DNS, TCP, TLS, HTTP/1.1, and SSE transport
  path for the Agent.
- Add masked volatile API-key setup, HTTPS base URL configuration, runtime
  admission checks, cancellation, and explicit secret clearing.
- Expand the bounded page pool and QEMU memory required by the validated fx
  application while preserving a single foreground instance.
- Validate one real DeepSeek model turn from the QEMU image; CI remains
  deterministic and contains no provider secret.

## 0.2.0

- Compose ossh 0.1.1 and ppnet 0.2.0 over one oscore 0.1.3 instance.
- Add bounded static QEMU network policy and product network/ping commands.
- Link pinned uIP and BearSSL through ppnet without copying protocol code.
- Verify the product image reaches the QEMU gateway through ppnet ICMP.

## 0.1.0

- Compose osbare, oscore, and ossh v0.1.0 into a bootable product image.
- Add release and component identity commands.
- Add cooperative Shell lifecycle supervision.
- Add graphical and headless QEMU run targets.
- Add product-level interactive acceptance and component boundary checks.
