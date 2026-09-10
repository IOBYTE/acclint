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
# --splitMat moves surfaces into one object per material.
#
# Only surfaces[0] is checked for a material before the split begins, so the
# erase loops must not assume every other surface has one. A surface with no
# "mat" line names no material to split on, so it stays with the original
# object and is not copied into any of the split off objects.
################################################################################

# test1.1: a surface with no "mat" line and nothing to split on. Every
# surface that does name a material names the same one, so no split happens
# and both surfaces stay on "p" -- the second still without a "mat" line.
# Reading mats[0] on that surface ran past the end of an empty vector.
@test "test1.1" {
  $RUN_TEST acclint test1.1.ac --splitMat -Wno-missing-mat -Wno-unused-material -o test1.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.1.output.ac test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

# test1.2: an ordinary split with every surface naming a material. Guards
# against a guard that is too eager and drops surfaces it should keep.
@test "test1.2" {
  $RUN_TEST acclint test1.2.ac --splitMat -Wno-different-mat -o test1.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.2.output.ac)"
  expected_file="$(tr -d '\r' < test1.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.2.output.ac test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.2.output.ac
}

# test1.3: both at once -- a real split, with a mat-less surface present.
# The mat-less surface must land on "p" exactly once: not dropped, and not
# duplicated into "p-split1".
@test "test1.3" {
  $RUN_TEST acclint test1.3.ac --splitMat -Wno-different-mat -Wno-missing-mat -o test1.3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.3.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.3.output.ac test1.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.3.output.ac
}

################################################################################
