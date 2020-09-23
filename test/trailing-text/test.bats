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
  run acclint -Wno-warnings -Wtrailing-text test1.ac
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

@test "test4.1" {
  run acclint test4.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

@test "test4.2" {
  run acclint -Wno-warnings test4.ac -o test4.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.ac)" = "$(cat test4.result.ac)" ]
  rm test4.output.ac
}

################################################################################

@test "test5.1" {
  run acclint test5.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test5.result)" ]
}

@test "test5.2" {
  run acclint -Wno-warnings test5.ac -o test5.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test5.output.ac)" = "$(cat test5.result.ac)" ]
  rm test5.output.ac
}

################################################################################

@test "test6.1" {
  run acclint test6.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test6.result)" ]
}

@test "test6.2" {
  run acclint -Wno-warnings test6.ac -o test6.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test6.output.ac)" = "$(cat test6.result.ac)" ]
  rm test6.output.ac
}

################################################################################

@test "test7.1" {
  run acclint test7.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test7.result)" ]
}

@test "test7.2" {
  run acclint -Wno-warnings test7.ac -o test7.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test7.output.ac)" = "$(cat test7.result.ac)" ]
  rm test7.output.ac
}

################################################################################

@test "test8.1" {
  run acclint test8.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test8.result)" ]
}

@test "test8.2" {
  run acclint -Wno-warnings test8.ac -o test8.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test8.output.ac)" = "$(cat test8.result.ac)" ]
  rm test8.output.ac
}
