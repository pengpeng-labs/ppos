#!/bin/sh
set -eu

kernel=$1
disk=$2
initrd=$3
log=$(mktemp)
monitor=$(mktemp -u)
pid=''

cleanup() {
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    fi
    rm -f "$log" "$monitor"
}
trap cleanup EXIT INT TERM

"${QEMU:-qemu-system-x86_64}" \
    -machine pc -cpu max -m 128M -display none -serial file:"$log" \
    -monitor unix:"$monitor",server,nowait \
    -kernel "$kernel" -initrd "$initrd" -append 'ppos.test=1' \
    -drive file="$disk",format=raw,if=ide \
    -device e1000,netdev=net0 -netdev user,id=net0 \
    -no-reboot -no-shutdown &
pid=$!

wait_for() {
    marker=$1
    i=0
    while [ "$i" -lt 200 ]; do
        if grep -q "$marker" "$log"; then return 0; fi
        if grep -q 'PPOS FAIL' "$log"; then cat "$log"; return 1; fi
        if ! kill -0 "$pid" 2>/dev/null; then cat "$log"; return 1; fi
        sleep 0.05
        i=$((i + 1))
    done
    cat "$log"
    return 1
}

send_keys() {
    commands=$1
    printf '%b' "$commands" | nc -w 1 -U "$monitor" >/dev/null 2>&1
}

wait_for 'PPOS READY'
wait_for 'OSSH PROMPT READY'

send_keys 'sendkey c 20\nsendkey o 20\nsendkey m 20\nsendkey p 20\nsendkey o 20\nsendkey n 20\nsendkey e 20\nsendkey n 20\nsendkey t 20\nsendkey s 20\nsendkey ret 20\n'
wait_for 'osbare 0.1.0'
wait_for 'oscore 0.1.0'
wait_for 'ossh 0.1.0'

send_keys 'sendkey s 20\nsendkey u 20\nsendkey p 20\nsendkey tab 20\nsendkey ret 20\n'
wait_for 'shell_task='
wait_for 'restarts=0'

send_keys 'sendkey s 20\nsendkey t 20\nsendkey a 20\nsendkey t 20\nsendkey u 20\nsendkey s 20\nsendkey ret 20\n'
wait_for 'oscore initialized=yes'

send_keys 'sendkey t 20\nsendkey a 20\nsendkey s 20\nsendkey k 20\nsendkey s 20\nsendkey ret 20\n'
wait_for 'task 0 state='

send_keys 'sendkey h 20\nsendkey e 20\nsendkey l 20\nsendkey p 20\nsendkey ret 20\n'
wait_for 'Show the pinned component matrix'

grep -q 'composition: osbare + oscore + ossh' "$log"
grep -q 'OSCORE INIT PASS' "$log"
grep -q 'ossh 0.1.0' "$log"
grep -q 'PPOS READY' "$log"
cat "$log"
