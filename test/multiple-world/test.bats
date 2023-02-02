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
  run acclint -Wno-warnings -Wmultiple-world test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint test1.ac -o test1.4.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
  [ "$(cat test1.4.output.ac)" = "$(cat test1.4.result.ac)" ]
  rm test1.4.output.ac
}

################################################################################

