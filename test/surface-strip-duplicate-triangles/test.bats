#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

################################################################################

@test "test1.0" {
  $RUN_TEST acclint test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary -Wsurface-strip-duplicate-triangles test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

################################################################################

@test "test5.1" {
  $RUN_TEST acclint -Wsurface-strip-duplicate-triangles test5.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test5.result)" ]
}

################################################################################
