#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint -Wno-overlapping-2-sided-surface test1.ac --fixOverlapping2SidedSurface -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  run acclint -Wno-overlapping-2-sided-surface test2.ac --fixOverlapping2SidedSurface -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  run acclint -Wno-overlapping-2-sided-surface test3.ac --fixOverlapping2SidedSurface -o test3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.ac)" = "$(cat test3.result.ac)" ]
  rm test3.output.ac
}

################################################################################

@test "test4.1" {
  run acclint -Wno-overlapping-2-sided-surface test4.acc --fixOverlapping2SidedSurface -o test4.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.acc)" = "$(cat test4.result.acc)" ]
  rm test4.output.acc
}
