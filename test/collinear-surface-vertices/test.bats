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
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wcollinear-surface-vertices test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.result)" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test2.result)" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test2.output.ac)" = "$(cat test2.result.ac)" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test3.result)" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.ac -o test3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test3.output.ac)" = "$(cat test3.result.ac)" ]
  rm test3.output.ac
}

################################################################################

@test "test4" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test4.result)" ]
}

################################################################################

@test "test5" {
  $RUN_TEST acclint test5.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test5.result)" ]
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test6.result)" ]
}

################################################################################

@test "test7" {
  $RUN_TEST acclint test7.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test7.result)" ]
}

################################################################################

@test "test8" {
  $RUN_TEST acclint test8.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test8.result)" ]
}

################################################################################

@test "test9" {
  $RUN_TEST acclint test9.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test9.result)" ]
}

################################################################################

@test "test10" {
  $RUN_TEST acclint test10.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test10.result)" ]
}

################################################################################

@test "test11.1" {
  $RUN_TEST acclint test11.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test11.result)" ]
}

@test "test11.2" {
  $RUN_TEST acclint -Wno-warnings test11.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test11.3" {
  $RUN_TEST acclint -Wno-warnings -Wcollinear-surface-vertices test11.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test11.result)" ]
}

@test "test11.4" {
  $RUN_TEST acclint -Wno-warnings test11.ac -o test11.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test11.output.ac)" = "$(cat test11.result.ac)" ]
  rm test11.output.ac
}

################################################################################

@test "test12.1" {
  $RUN_TEST acclint test12.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test12.result)" ]
}

@test "test12.2" {
  $RUN_TEST acclint -Wno-warnings test12.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test12.3" {
  $RUN_TEST acclint -Wno-warnings -Wcollinear-surface-vertices test12.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test12.result)" ]
}

@test "test12.4" {
  $RUN_TEST acclint -Wno-warnings test12.ac -o test12.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test12.output.ac)" = "$(cat test12.result.ac)" ]
  rm test12.output.ac
}
