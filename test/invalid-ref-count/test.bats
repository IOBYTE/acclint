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
  run acclint -Wno-invalid-ref-count test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.4" {
  run acclint -Wno-warnings -Winvalid-ref-count test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.5" {
  run acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2" {
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
