#!/usr/bin/env bash
#
# Run every bats suite under test/ and exit non-zero if any of them failed.
# Every suite is run even after one fails, so a single run reports all of
# the damage instead of stopping at the first broken directory.

set -u
shopt -s nullglob

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

    # Subshell so a failed cd can never leak into the next iteration.
    if ! ( cd "$dir" && bats test.bats -T ); then
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
