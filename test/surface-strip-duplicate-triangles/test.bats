#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

# Delete any *.output debug files left over from a previous run before
# running any tests in this file.
setup_file() {
    rm -f ./*.output
}

################################################################################

@test "test1.0" {
  $RUN_TEST acclint test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.0.output
  fi
  [ "$output" = "" ]
}

@test "test1.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: Surface::setTriangleStrip() used to index
# object.vertices[refs[i].index] without a bounds check, causing a segfault
# (confirmed via gdb: SIGSEGV inside Triangle::Triangle, called from
# setTriangleStrip at ac3d.cpp:2878) whenever a triangle-strip surface had
# an out-of-range ref vertex index. The surface here has 2 vertices but a
# ref index of 999; acclint must report the invalid ref vertex index error
# and exit cleanly instead of crashing.
@test "test4" {
  $RUN_TEST acclint test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: sameTriangle() checked against Difference::None, Order
# and Winding are not mutually exclusive for a degenerate triangle (one
# with a repeated vertex) -- all three can be simultaneously true, since
# some of its vertex slots are interchangeable copies of each other. Before
# the fix, this surface's two fully-degenerate triangles (every ref points
# at the same vertex) produced three redundant warnings for a single pair.
# Degenerate triangles are already covered by
# -Wsurface-strip-degenerate, so checkSurfaceStripDuplicateTriangles must
# skip them and produce no output here.
@test "test5" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-duplicate-triangles test5.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.output
  fi
  [ "$output" = "" ]
}

################################################################################
