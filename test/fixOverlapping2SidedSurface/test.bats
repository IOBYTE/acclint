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
  $RUN_TEST acclint -Wno-overlapping-2-sided-surface test1.ac --fixOverlapping2SidedSurface -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-overlapping-2-sided-surface test2.ac --fixOverlapping2SidedSurface -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-overlapping-2-sided-surface test3.ac --fixOverlapping2SidedSurface -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.ac
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint -Wno-overlapping-2-sided-surface test4.acc --fixOverlapping2SidedSurface -o test4.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.acc)"
  expected_file="$(tr -d '\r' < test4.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.acc
}

################################################################################
# Clearing the two sided flag is done one surface at a time, so an object with
# two of them and only one of them overlapped comes out holding a mix -- and an
# object is expected not to hold a mix. The .acc loader takes the cull face for
# a whole strip object from whichever surface it read last (current_flags, in
# grloadac.cpp's setup_vertex_table_states), so the surfaces that disagree are
# drawn with the wrong sidedness. Splitting again after the fix is what puts
# the object back to one state apiece.
################################################################################

# test5.1: front has two two sided surfaces and back overlaps only the first of
# them. That one and back are fixed; the second stays two sided and leaves in
# an object of its own rather than sitting in a mixed one.
@test "test5.1" {
  $RUN_TEST acclint -Wno-overlapping-2-sided-surface test5.ac --fixOverlapping2SidedSurface -o test5.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.output.ac test5.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

################################################################################
