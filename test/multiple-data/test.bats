#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  run acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  run acclint -Wno-warnings -Wmultiple-data test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint --quiet test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  run acclint --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  run acclint --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################

@test "test2.1" {
  run acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.2" {
  run acclint -Wno-warnings test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test2.3" {
  run acclint -Wno-warnings -Wmultiple-data test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.4" {
  run acclint --quiet test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.4.result)" ]
}

@test "test2.5" {
  run acclint --summary test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.5.result)" ]
}

@test "test2.6" {
  run acclint --quiet --summary test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.6.result)" ]
}

################################################################################
