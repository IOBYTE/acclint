#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint -Wno-unused-vertex -Wno-unused-material test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  run acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  run acclint -Wno-warnings -Wmissing-surfaces test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

################################################################################
