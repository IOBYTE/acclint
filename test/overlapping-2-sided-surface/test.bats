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
  run acclint -Wno-warnings -Woverlapping-2-sided-surface test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

################################################################################

@test "test2" {
  run acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}
