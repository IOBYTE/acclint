#!/usr/bin/env bats

################################################################################

# TODO invalid vertices breaks checks so ignore warnings for now

@test "test1.1" {
  run acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  run acclint -Wno-warnings -Wno-errors test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  run acclint -Wno-warnings -Wno-errors -Winvalid-vertex test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.3.result)" ]
}

@test "test1.4" {
  run acclint -Wno-warnings --quite test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  run acclint -Wno-warnings --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  run acclint -Wno-warnings --quite --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################
