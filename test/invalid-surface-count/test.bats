#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint -Wno-more-surf-than-specified test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  run acclint -Wno-errors test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  run acclint -Wno-errors -Winvalid-surface-count test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  run acclint -Wno-more-surf-than-specified --quiet test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
}

@test "test1.5" {
  run acclint -Wno-more-surf-than-specified --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
}

@test "test1.6" {
  run acclint -Wno-more-surf-than-specified --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
}

################################################################################

@test "test2" {
  run acclint -Wno-more-surf-than-specified test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

################################################################################

@test "test3" {
  run acclint -Wno-more-surf-than-specified test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}
