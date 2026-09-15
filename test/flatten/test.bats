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
  $RUN_TEST acclint test1.1.ac --flatten -o test1.1.output.ac
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
  $RUN_TEST acclint test1.2.ac --flatten -o test1.2.output.ac
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
  $RUN_TEST acclint test1.3.ac --flatten -o test1.3.output.ac
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

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.1.acc --flatten -o test2.1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.1.output.acc)"
  expected_file="$(tr -d '\r' < test2.1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.1.output.acc
}

@test "test2.2" {
  $RUN_TEST acclint test2.2.acc --flatten -o test2.2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.2.output.acc)"
  expected_file="$(tr -d '\r' < test2.2.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.2.output.acc
}

@test "test2.3" {
  $RUN_TEST acclint test2.3.acc --flatten -o test2.3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.3.output.acc)"
  expected_file="$(tr -d '\r' < test2.3.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.3.output.acc
}

################################################################################

# Flattening pushes each object's placement down into the geometry underneath
# it and then drops the loc and rot that said it. Two things were reached by
# the dropping but not by the pushing.
################################################################################

# test3.1: a light has no vertices for a placement to be pushed into, so
# clearing its loc threw the placement away and put it at the origin. It keeps
# where it is instead, with its ancestors' placement composed into it: the
# nested light under a group at x=10 comes out at x=11, and the group's own loc
# is gone as it should be.
@test "test3.1" {
  $RUN_TEST acclint test3.1.ac --flatten -o test3.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.1.output.ac)"
  expected_file="$(tr -d '\r' < test3.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.1.output.ac test3.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.1.output.ac
}

# test3.2: a poly can be a parent in this format, and its kids were the one
# branch the walk never entered -- the parent's vertices moved and the kid's
# did not, leaving the kid ten units from where it belongs.
@test "test3.2" {
  $RUN_TEST acclint test3.2.ac --flatten -o test3.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.2.output.ac)"
  expected_file="$(tr -d '\r' < test3.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.2.output.ac test3.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.2.output.ac
}

################################################################################
