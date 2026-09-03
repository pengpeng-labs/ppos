#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
port_root="$root/ports/fx-ppos"
work="$root/build/fx-ppos/test-source"
zig=${ZIG:-zig}

"$port_root/prepare.sh" "$work"

cd "$work"
ZIG_GLOBAL_CACHE_DIR="$root/build/fx-ppos/zig-global-cache" \
ZIG_LOCAL_CACHE_DIR="$work/.zig-cache" \
    "$zig" test --dep build_options \
        -Mroot=src/deepseek_port_test.zig \
        -Mbuild_options=src/deepseek_test_build_options.zig \
        -lc --test-filter DeepSeek
