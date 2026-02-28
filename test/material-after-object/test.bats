#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint -Wno-unused-material test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  run acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  run acclint -Wno-warnings -Wmaterial-after-object test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint -Wno-unused-material --quiet test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  run acclint -Wno-unused-material --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  run acclint -Wno-unused-material --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################
