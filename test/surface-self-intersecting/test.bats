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
  $RUN_TEST acclint -Wno-surface-not-convex test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-self-intersecting test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

################################################################################

@test "test2" {
  $RUN_TEST acclint -Wno-surface-not-convex test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

################################################################################

@test "test3" {
  $RUN_TEST acclint -Wno-surface-not-convex test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-surface-not-convex test4.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

################################################################################

@test "test5" {
  $RUN_TEST acclint -Wno-surface-not-convex test5.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test5.result)" ]
}