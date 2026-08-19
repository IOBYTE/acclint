#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

################################################################################

@test "test1.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.4.result)" ]
}

@test "test2.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.5.result)" ]
}

@test "test2.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.6.result)" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.4.result)" ]
}

@test "test3.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.5.result)" ]
}

@test "test3.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.6.result)" ]
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

@test "test4.2" {
  $RUN_TEST acclint -Wno-warnings test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test4.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-triangles test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

@test "test4.4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.4.result)" ]
}

@test "test4.5" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --summary test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.5.result)" ]
}

@test "test4.6" {
  $RUN_TEST acclint -Wno-duplicate-surfaces -Wduplicate-triangles --quiet --summary test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.6.result)" ]
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
  [ "$output" = "$(cat test5.result)" ]
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
  [ "$output" = "$(cat test6.result)" ]
}

################################################################################
