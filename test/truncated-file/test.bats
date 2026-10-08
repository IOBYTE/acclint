#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" && "${USE_VALGRIND:-true}" == "true" ]]; then
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
# A file cut short passed without a word wherever the cut fell after the last
# thing that counted something: the surfaces numsurf promised, the kids line
# every object ends with, or the world itself. Each is now said.
################################################################################

# test1: numsurf 3, one surface, and the end of the file, with no kids line.
# The surfaces are an error, the way kids turning up early is, and the file is
# not written (test1.2); -o used to write the one surface with numsurf 1 and
# kids 0. The missing kids line is a warning.
@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  rm -f test1.2.output.ac
  $RUN_TEST acclint test1.ac -o test1.2.output.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  [ ! -e test1.2.output.ac ]
}

################################################################################

# test2: a whole object, missing only its kids line at the end of the file.
# What is missing says it has no kids, so it is a warning, as an OBJECT where
# the kids line should be is, and the file is written with kids 0 (test2.2).
@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.2.output.ac test2.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.2.output.ac
}

################################################################################

# test3: the header and a material, and nothing after. A file with no object
# has nothing to draw: an error. -o wrote the header on its own.
@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.2" {
  rm -f test3.2.output.ac
  $RUN_TEST acclint test3.ac -o test3.2.output.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$actual" = "$expected" ]
  [ ! -e test3.2.output.ac ]
}

################################################################################
