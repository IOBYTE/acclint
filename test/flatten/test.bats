#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.1.ac --flatten -o test1.1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.1.output.ac)" = "$(cat test1.1.result.ac)" ]
  rm test1.1.output.ac
}

@test "test1.2" {
  run acclint test1.2.ac --flatten -o test1.2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.2.output.ac)" = "$(cat test1.2.result.ac)" ]
  rm test1.2.output.ac
}

@test "test1.3" {
  run acclint test1.3.ac --flatten -o test1.3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.3.output.ac)" = "$(cat test1.3.result.ac)" ]
  rm test1.3.output.ac
}

################################################################################

@test "test2.1" {
  run acclint test2.1.acc --flatten -o test2.1.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.1.output.acc)" = "$(cat test2.1.result.acc)" ]
  rm test2.1.output.acc
}

@test "test2.2" {
  run acclint test2.2.acc --flatten -o test2.2.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.2.output.acc)" = "$(cat test2.2.result.acc)" ]
  rm test2.2.output.acc
}

@test "test2.3" {
  run acclint test2.3.acc --flatten -o test2.3.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.3.output.acc)" = "$(cat test2.3.result.acc)" ]
  rm test2.3.output.acc
}

################################################################################
