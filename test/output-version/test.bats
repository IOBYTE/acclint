#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

# Delete any *.output debug files left over from a previous run before
# running any tests in this file.
setup_file() {
    rm -f ./*.output
}

################################################################################

@test "test1.1" {
  $RUN_TEST acclint test1.ac -o test1.output.ac -v 11
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.1.result.ac)"
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

@test "test1.2" {
  $RUN_TEST acclint test1.ac -o test1.output.ac -v 12
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.2.result.ac)"
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac -o test2.output.ac -v 11
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.1.result.ac)"
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

@test "test2.2" {
  $RUN_TEST acclint test2.ac -o test2.output.ac -v 12
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.2.result.ac)"
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac -o test3.output.ac -v
  [ "$status" -ne 0 ]
}

@test "test3.2" {
  $RUN_TEST acclint test3.ac -o test3.output.ac -v 10
  [ "$status" -ne 0 ]
}

################################################################################
