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

@test "test1" {
  $RUN_TEST acclint test1.acc -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

################################################################################

@test "test2" {
  $RUN_TEST acclint test2.acc -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################

@test "test3" {
  $RUN_TEST acclint test3.acc -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.ac
}

################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-different-uv test4.acc -o test4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.ac
}

################################################################################

@test "test5" {
  $RUN_TEST acclint test5.acc -o test5.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.acc -o test6.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test6.output.ac)"
  expected_file="$(tr -d '\r' < test6.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.ac
}

################################################################################

@test "test7" {
  $RUN_TEST acclint test7.acc -Wno-duplicate-vertices -o test7.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.output.ac)"
  expected_file="$(tr -d '\r' < test7.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test7.output.ac
}

################################################################################