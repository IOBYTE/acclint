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
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-errors test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-ref-vertex-index test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################

@test "test2" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-errors test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-ref-vertex-index test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.4" {
  $RUN_TEST acclint --quiet test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.4.result)" ]
}

@test "test3.5" {
  $RUN_TEST acclint --summary test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.5.result)" ]
}

@test "test3.6" {
  $RUN_TEST acclint --quiet --summary test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.6.result)" ]
}

################################################################################