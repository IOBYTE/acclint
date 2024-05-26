#!/usr/bin/bash

for f in *; do
    if [ -d "$f" ]; then
        cd $f
        echo "${PWD##*/}"
        bats test.bats
        cd ..
    fi
done
