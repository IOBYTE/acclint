#!/usr/bin/env bats

################################################################################

@test "test1" {
  run acclint test1.ac -o test1.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.acc
}

################################################################################

@test "test2" {
  run acclint test2.ac -o test2.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.acc
}

################################################################################

@test "test3" {
  run acclint test3.ac -o test3.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.ac)" = "$(cat test3.result.ac)" ]
  rm test3.output.acc
}

################################################################################

@test "test4" {
  run acclint -Wno-different-uv test4.ac -o test4.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.ac)" = "$(cat test4.result.ac)" ]
  rm test4.output.acc
}

################################################################################
