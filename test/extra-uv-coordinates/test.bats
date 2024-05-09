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
  run acclint -Wno-warnings -Wextra-uv-coordinates test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

################################################################################

@test "test2.1" {
  run acclint test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.2" {
  run acclint -Wno-warnings test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test2.3" {
  run acclint -Wno-warnings -Wextra-uv-coordinates test2.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

################################################################################

@test "test3.1" {
  run acclint test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.2" {
  run acclint -Wno-warnings test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test3.3" {
  run acclint -Wno-warnings -Wextra-uv-coordinates test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

################################################################################
