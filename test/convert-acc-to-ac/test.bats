#!/usr/bin/env bats

################################################################################

@test "test1" {
  run acclint test1.acc -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2" {
  run acclint test2.acc -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3" {
  run acclint test3.acc -o test3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.ac)" = "$(cat test3.result.ac)" ]
  rm test3.output.ac
}

################################################################################

@test "test4" {
  run acclint -Wno-different-uv test4.acc -o test4.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.ac)" = "$(cat test4.result.ac)" ]
  rm test4.output.ac
}

################################################################################

@test "test5" {
  run acclint test5.acc -o test5.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test5.output.ac)" = "$(cat test5.result.ac)" ]
  rm test5.output.ac
}

################################################################################

@test "test6" {
  run acclint test6.acc -o test6.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test6.output.ac)" = "$(cat test6.result.ac)" ]
  rm test6.output.ac
}

################################################################################

@test "test7" {
  run acclint test7.acc -Wno-duplicate-vertices -o test7.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test7.output.ac)" = "$(cat test7.result.ac)" ]
  rm test7.output.ac
}

################################################################################
