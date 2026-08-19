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

@test "test1.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test1.acc
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
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test1.acc
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
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.2" {
  $RUN_TEST acclint -Wno-warnings test4.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$output" = "" ]
}

@test "test4.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: a triangle-strip surface plus a plain triangle surface
# with an out-of-range vertex ref index (999 when only 5 vertices exist).
# Triangle::sameTriangle(const Object&, const Surface&, Difference) used to
# index object.vertices[surface.refs[k].index] without a bounds check in
# several places, causing a segfault (confirmed via ASan: SEGV in
# sameTriangle at ac3d.cpp:3306, called from checkDuplicateTriangles) when
# comparing the strip's triangles against the malformed surface.
@test "test5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test5.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: when surface1 (declared first) is a triangle strip and
# surface2 (declared second) is a plain triangle, the "duplicate triangle"
# diagnostic's second "ref" note incorrectly used surface1.refs[2] -- the
# strip's own constant 3rd ref, unrelated to which triangle in the strip
# matched and not even referring to surface2 (the actual duplicate). It
# should reference surface2.refs[2], matching the mirror-order branch
# (plain triangle first, strip second), which was already correct.
@test "test6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wno-different-surf -Wduplicate-triangles test6.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
