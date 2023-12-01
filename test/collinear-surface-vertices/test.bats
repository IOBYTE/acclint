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
  run acclint -Wno-warnings -Wcollinear-surface-vertices test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  run acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.2" {
  run acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  run acclint test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.2" {
  run acclint -Wno-warnings test3.ac -o test3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.ac)" = "$(cat test3.result.ac)" ]
  rm test3.output.ac
}

################################################################################

@test "test4" {
  run acclint test4.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

################################################################################

@test "test5" {
  run acclint test5.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test5.result)" ]
}

################################################################################

@test "test6" {
  run acclint test6.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test6.result)" ]
}

################################################################################

@test "test7" {
  run acclint test7.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test7.result)" ]
}

################################################################################

@test "test8" {
  run acclint test8.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test8.result)" ]
}

################################################################################

@test "test9" {
  run acclint test9.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test9.result)" ]
}

################################################################################

@test "test10" {
  run acclint test10.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test10.result)" ]
}

################################################################################

@test "test11.1" {
  run acclint test11.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test11.result)" ]
}

@test "test11.2" {
  run acclint -Wno-warnings test11.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test11.3" {
  run acclint -Wno-warnings -Wcollinear-surface-vertices test11.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test11.result)" ]
}

@test "test11.4" {
  run acclint -Wno-warnings test11.ac -o test11.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test11.output.ac)" = "$(cat test11.result.ac)" ]
  rm test11.output.ac
}

################################################################################

@test "test12.1" {
  run acclint test12.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test12.result)" ]
}

@test "test12.2" {
  run acclint -Wno-warnings test12.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test12.3" {
  run acclint -Wno-warnings -Wcollinear-surface-vertices test12.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test12.result)" ]
}

@test "test12.4" {
  run acclint -Wno-warnings test12.ac -o test12.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test12.output.ac)" = "$(cat test12.result.ac)" ]
  rm test12.output.ac
}

