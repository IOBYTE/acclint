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

cd group-with-geometry
echo "${PWD##*/}"
bats test.bats
cd ..

cd output-version
echo "${PWD##*/}"
bats test.bats
cd ..

cd multiple-world
echo "${PWD##*/}"
bats test.bats
cd ..

cd different-surf
echo "${PWD##*/}"
bats test.bats
cd ..

cd merge
echo "${PWD##*/}"
bats test.bats
cd ..

cd different-mat
echo "${PWD##*/}"
bats test.bats
cd ..

cd surface-strip-size
echo "${PWD##*/}"
bats test.bats
cd ..
