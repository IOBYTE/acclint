#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

################################################################################

@test "test1" {
  $RUN_TEST acclint test1.ac -o test1.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.acc)" = "$(cat test1.result.acc)" ]
  rm test1.output.acc
}

################################################################################

@test "test2" {
  $RUN_TEST acclint test2.ac -o test2.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.acc)" = "$(cat test2.result.acc)" ]
  rm test2.output.acc
}

################################################################################

@test "test3" {
  $RUN_TEST acclint test3.ac -o test3.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.acc)" = "$(cat test3.result.acc)" ]
  rm test3.output.acc
}

################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-different-uv test4.ac -o test4.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test4.output.acc)" = "$(cat test4.result.acc)" ]
  rm test4.output.acc
}

################################################################################

@test "test5" {
  $RUN_TEST acclint test5.ac -o test5.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test5.output.acc)" = "$(cat test5.result.acc)" ]
  rm test5.output.acc
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.ac -o test6.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test6.output.acc)" = "$(cat test6.result.acc)" ]
  rm test6.output.acc
}

################################################################################