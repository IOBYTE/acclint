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