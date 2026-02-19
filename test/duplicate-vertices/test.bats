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
  run acclint -Wno-warnings -Wduplicate-vertices test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint --quiet test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  run acclint --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  run acclint --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

@test "test1.7" {
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
  run acclint test3.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.2" {
  run acclint -Wno-warnings test3.acc -o test3.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.acc)" = "$(cat test3.result.acc)" ]
  rm test3.output.acc
}
