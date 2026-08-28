#!/bin/sh
set -eu

object=$1
symbols=$(${NM:-x86_64-elf-nm} -u "$object")
if printf '%s\n' "$symbols" | grep -E '(^| )(outb|inb|cli|sti|hlt)$' >/dev/null; then
    echo 'ppos contains a forbidden direct machine dependency' >&2
    exit 1
fi
printf 'PPOS BOUNDARY PASS\n'
