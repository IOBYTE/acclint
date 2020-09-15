#!/usr/bin/bash

pushd collinear-surface-vertices
bats test.bats
popd

pushd invalid-vertex-index
bats test.bats
popd
