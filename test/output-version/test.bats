#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.ac -o test1.output.ac -v 11
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.1.result.ac)" ]
  rm test1.output.ac
}

@test "test1.2" {
  run acclint test1.ac -o test1.output.ac -v 12
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.2.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  run acclint test2.ac -o test2.output.ac -v 11
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.1.result.ac)" ]
  rm test2.output.ac
}

@test "test2.2" {
  run acclint test2.ac -o test2.output.ac -v 12
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  run acclint test3.ac -o test3.output.ac -v
  [ "$status" -ne 0 ]
}

@test "test3.2" {
  run acclint test3.ac -o test3.output.ac -v 10
  [ "$status" -ne 0 ]
}

################################################################################

