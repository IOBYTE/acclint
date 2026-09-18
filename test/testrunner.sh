#!/usr/bin/env bash
#
# Run every bats suite under test/ and exit non-zero if any of them failed.
# Every suite is run even after one fails, so a single run reports all of
# the damage instead of stopping at the first broken directory.

set -u
shopt -s nullglob

trap 'echo; echo "Interrupted." >&2; exit 130' INT

use_valgrind=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-valgrind)
            use_valgrind=false
            shift
            ;;
        *)
            echo "error: unknown option: $1" >&2
            echo "usage: $0 [--no-valgrind]" >&2
            exit 2
            ;;
    esac
done

if ! command -v bats > /dev/null 2>&1; then
    echo "error: bats not found in PATH" >&2
    exit 1
fi

if ! command -v acclint > /dev/null 2>&1; then
    echo "error: acclint not found in PATH -- build it first" >&2
    exit 1
fi

failed=()

for dir in */; do
    name=${dir%/}

    if [ ! -f "$dir/test.bats" ]; then
        echo "warning: $name has no test.bats, skipping" >&2
        continue
    fi

    echo "$name"

    (
        cd "$dir" || exit
        USE_VALGRIND="$use_valgrind" bats test.bats -T
    )
    status=$?

    if [ "$status" -eq 130 ]; then
        exit 130
    elif [ "$status" -ne 0 ]; then
        failed+=("$name")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    echo >&2
    echo "${#failed[@]} suite(s) failed: ${failed[*]}" >&2
    exit 1
fi

echo
echo "all suites passed"

