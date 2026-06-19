#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

################################################################################

@test "test1.1" {
  $RUN_TEST acclint test1.ac --fixSurface2SidedOpaque -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac --fixSurface2SidedOpaque -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.acc --fixSurface2SidedOpaque -o test3.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.acc)" = "$(cat test3.result.acc)" ]
  rm test3.output.acc
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint test4.acc --fixSurface2SidedOpaque -o test4.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.acc)" = "$(cat test4.result.acc)" ]
  rm test4.output.acc
}