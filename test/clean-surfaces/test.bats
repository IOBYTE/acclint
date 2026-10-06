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
    rm -f ./*.output ./*.output.ac
}

################################################################################
# cleanSurfaces: writing an output file deletes the surfaces left with too few
# refs to draw anything. Every surface used to be tested against three, which
# is right for a polygon or a triangle strip but not for a line: a line is
# drawn from two refs, the reader accepts one without complaint, and so every
# 2 ref line was dropped from every file written, with nothing said.
#
# The minimum is now two for an open line and three for the rest: a closed
# line needs three to enclose anything.
################################################################################

# test1: a 2 ref open line beside a triangle. Both have to come through.
@test "test1" {
  $RUN_TEST acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test1.output.ac test1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

# test2: both sides of each minimum. A 1 ref line, a 2 ref closed line and a
# 2 ref polygon go; a 3 ref closed line and the triangle stay.
@test "test2" {
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test2.output.ac test2.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

################################################################################
