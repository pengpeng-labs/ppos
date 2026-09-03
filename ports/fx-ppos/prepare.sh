#!/usr/bin/env bash
set -euo pipefail

port_root=$(cd "$(dirname "$0")" && pwd)
work=${1:?usage: prepare.sh WORK_DIR}
source_dir=${FX_SOURCE:-}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

if [[ -n "${FX_ARCHIVE:-}" ]]; then
    expected=93f916f3366a2289ef06858e62cb9d9ea9387329ebc67a33039e615a35cb68e6
    actual=$(sha256_file "$FX_ARCHIVE")
    [[ "$actual" == "$expected" ]] || {
        echo "fx-ppos: source archive checksum mismatch" >&2
        exit 2
    }
    archive_root="$work.archive"
    rm -rf "$archive_root"
    mkdir -p "$archive_root"
    unzip -q "$FX_ARCHIVE" -d "$archive_root"
    source_dir="$archive_root/fx-0.0.6"
fi

[[ -n "$source_dir" && -f "$source_dir/build.zig" ]] || {
    echo "fx-ppos: set FX_SOURCE to extracted fx 0.0.6 or FX_ARCHIVE to the pinned zip" >&2
    exit 2
}

rm -rf "$work"
mkdir -p "$work/src/providers"
cp -R "$source_dir/." "$work/"
cp "$port_root/src/providers/deepseek.zig" "$work/src/providers/deepseek.zig"
cp "$port_root/src/deepseek_port_test.zig" "$work/src/deepseek_port_test.zig"
cp "$port_root/src/deepseek_test_build_options.zig" "$work/src/deepseek_test_build_options.zig"
patch -s -d "$work" -p1 < "$port_root/fx-ppos.patch"
