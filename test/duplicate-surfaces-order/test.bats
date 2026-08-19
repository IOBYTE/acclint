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
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-surfaces-order test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.result)" ]
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.result)" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-surfaces-order test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.result)" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test3.result)" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-surfaces-order test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test3.result)" ]
}

################################################################################

# Regression test: two byte-for-byte identical surfaces, with -Wno-duplicate-
# surfaces (disabling the exact-duplicate check) but -Wduplicate-surfaces-
# order left on (the default). Object::sameSurface's Order search used to
# match the trivial zero-rotation alignment too, so a genuinely identical
# pair got mislabeled "duplicate surfaces with different vertex order" even
# though the order was not different. Expect no output.
@test "test4" {
  $RUN_TEST acclint -Wno-duplicate-surfaces test4.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test4.result)" ]
}

################################################################################

# Regression test: two surfaces with identical vertex positions in the same
# order, differing only in vertex normals. Difference::None uses full Vertex
# equality (position + normal) and correctly fails to match, but
# Difference::Order used sameVertex() (position-only) and matched at the
# trivial zero-rotation alignment, misreporting "different vertex order"
# under DEFAULT flags -- no special -W flags needed to hit this. Expect no
# output.
@test "test5" {
  $RUN_TEST acclint test5.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test5.result)" ]
}

################################################################################
