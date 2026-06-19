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
  $RUN_TEST acclint test1a.ac --merge test1b.ac -o test1.1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.1.result)" ]
  [ "$(cat test1.1.output.ac)" = "$(cat test1.1.result.ac)" ]
  rm test1.1.output.ac
}

@test "test1.2" {
  $RUN_TEST acclint test1a.ac --merge test1b.ac --merge test1c.ac -o test1.2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(cat test1.2.result)" ]
  [ "$(cat test1.2.output.ac)" = "$(cat test1.2.result.ac)" ]
  rm test1.2.output.ac
}

################################################################################
