#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
port_root="$root/ports/fx-ppos"
work="$root/build/fx-ppos/source"
prefix="$root/build/fx-ppos/install"
out="$root/build/fx-ppos/fx-ppos.wasm"
zig=${ZIG:-zig}

"$port_root/prepare.sh" "$work"
mkdir -p "$prefix"

cd "$work"
env -u DEEPSEEK_API_KEY \
    ZIG_GLOBAL_CACHE_DIR="$root/build/fx-ppos/zig-global-cache" \
    ZIG_LOCAL_CACHE_DIR="$work/.zig-cache" \
    "$zig" build fx-term-wasm -Dwasm-surface=term --prefix "$prefix"

cp "$prefix/bin/fx-term.wasm" "$out"
if strings "$out" | grep -q '^sk-'; then
    echo "fx-ppos: refusing artifact containing a key-shaped string" >&2
    exit 2
fi
shasum -a 256 "$out"
wc -c "$out"
