#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  run acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  run acclint -Wno-warnings -Wmissing-normal test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint --quite test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  run acclint --summary test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  run acclint --quite --summary test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################
