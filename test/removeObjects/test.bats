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
  $RUN_TEST acclint test1.ac --removeObjects group group1 -o test1.1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.1.result)" ]
  [ "$(cat test1.1.output.ac)" = "$(cat test1.1.result.ac)" ]
  rm test1.1.output.ac
}

@test "test1.2" {
  $RUN_TEST acclint test1.ac --removeObjects group group1 --removeObjects group group2 -o test1.2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.2.result)" ]
  [ "$(cat test1.2.output.ac)" = "$(cat test1.2.result.ac)" ]
  rm test1.2.output.ac
}

@test "test1.3" {
  $RUN_TEST acclint test1.ac --removeObjects poly poly1 -o test1.3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.3.result)" ]
  [ "$(cat test1.3.output.ac)" = "$(cat test1.3.result.ac)" ]
  rm test1.3.output.ac
}

@test "test1.4" {
  $RUN_TEST acclint test1.ac --removeObjects poly poly1 --removeObjects poly poly3 -o test1.4.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.4.result)" ]
  [ "$(cat test1.4.output.ac)" = "$(cat test1.4.result.ac)" ]
  rm test1.4.output.ac
}

@test "test1.5" {
  $RUN_TEST acclint test1.ac --removeObjects group 'group(1|2)' -o test1.5.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.5.result)" ]
  [ "$(cat test1.5.output.ac)" = "$(cat test1.5.result.ac)" ]
  rm test1.5.output.ac
}

@test "test1.6" {
  $RUN_TEST acclint test1.ac --removeObjects poly 'poly(1|3)' -o test1.6.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.6.result)" ]
  [ "$(cat test1.6.output.ac)" = "$(cat test1.6.result.ac)" ]
  rm test1.6.output.ac
}
################################################################################
