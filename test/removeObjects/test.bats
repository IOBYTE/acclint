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
  $RUN_TEST acclint test1.ac --removeObjects group group1 -o test1.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

@test "test1.2" {
  $RUN_TEST acclint test1.ac --removeObjects group group1 --removeObjects group group2 -o test1.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.2.output.ac)"
  expected_file="$(tr -d '\r' < test1.2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.2.output.ac
}

@test "test1.3" {
  $RUN_TEST acclint test1.ac --removeObjects poly poly1 -o test1.3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.3.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.3.output.ac
}

@test "test1.4" {
  $RUN_TEST acclint test1.ac --removeObjects poly poly1 --removeObjects poly poly3 -o test1.4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.4.output.ac)"
  expected_file="$(tr -d '\r' < test1.4.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.4.output.ac
}

@test "test1.5" {
  $RUN_TEST acclint test1.ac --removeObjects group 'group(1|2)' -o test1.5.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.5.output.ac)"
  expected_file="$(tr -d '\r' < test1.5.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.5.output.ac
}

@test "test1.6" {
  $RUN_TEST acclint test1.ac --removeObjects poly 'poly(1|3)' -o test1.6.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.6.output.ac)"
  expected_file="$(tr -d '\r' < test1.6.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.6.output.ac
}
################################################################################
