#!/usr/bin/bash

cd collinear-surface-vertices
echo "${PWD##*/}"
bats test.bats
cd ..

cd duplicate-surface-vertices
echo "${PWD##*/}"
bats test.bats
cd ..

cd duplicate-vertices
echo "${PWD##*/}"
bats test.bats
cd ..

cd invalid-ref-count
echo "${PWD##*/}"
bats test.bats
cd ..

cd invalid-vertex-index
echo "${PWD##*/}"
bats test.bats
cd ..

cd surface-self-intersecting
echo "${PWD##*/}"
bats test.bats
cd ..

cd surface-not-convex
echo "${PWD##*/}"
bats test.bats
cd ..

cd surface-not-coplanar
echo "${PWD##*/}"
bats test.bats
cd ..

cd trailing-text
echo "${PWD##*/}"
bats test.bats
cd ..

cd unused-vertex
echo "${PWD##*/}"
bats test.bats
cd ..

cd different-uv
echo "${PWD##*/}"
bats test.bats
cd ..
