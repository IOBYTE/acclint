#!/usr/bin/bash

cd collinear-surface-vertices
echo "${PWD##*/}"
bats test.bats
cd ..

cd duplicate-surface-vertices
echo "${PWD##*/}"
bats test.bats
cd ..

cd invalid-vertex-index
echo "${PWD##*/}"
bats test.bats
cd ..

cd unused-vertex
echo "${PWD##*/}"
bats test.bats
cd ..
