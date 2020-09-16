#!/usr/bin/bash

pushd collinear-surface-vertices
bats test.bats
popd

pushd invalid-vertex-index
bats test.bats
popd

pushd unused-vertex
bats test.bats
popd
