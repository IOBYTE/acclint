#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.2" {
  run acclint -Wsurface-strip-degenerate test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.3" {
  run acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.4" {
  run acclint -Wno-warnings -Wsurface-strip-degenerate test1.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

################################################################################
