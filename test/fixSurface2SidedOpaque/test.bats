#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.ac --fixSurface2SidedOpaque -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  run acclint test2.ac --fixSurface2SidedOpaque -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  run acclint test3.acc --fixSurface2SidedOpaque -o test3.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.acc)" = "$(cat test3.result.acc)" ]
  rm test3.output.acc
}

################################################################################

@test "test4.1" {
  run acclint test4.acc --fixSurface2SidedOpaque -o test4.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.acc)" = "$(cat test4.result.acc)" ]
  rm test4.output.acc
}
