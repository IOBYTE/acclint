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
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wdifferent-surf test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint test1.ac --splitSURF -o test1.4.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.4.output.ac)"
  expected_file="$(tr -d '\r' < test1.4.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.4.output.ac
}

################################################################################

# What --splitSURF is for is state an object keeps one of and Speed Dreams
# takes from whichever surface it read last: shading, sidedness, material.
# Whether a surface is written as a polygon or as a triangle strip is not
# that, so the two surfaces below -- 0x30 and 0x34, agreeing about shading,
# sidedness and material and differing only in kind -- have every reason to
# stay in the one object, and must not be taken apart. Splitting on the whole
# SURF byte took them apart and undid what combineTexture and combineObjects
# had just done, for no gain: a polygon and a strip are one draw call either
# way. Which kind they are written as is settled when the file is written.
#
# It is still a mix on the way in, so "mixed surface types" reports it. That is
# the warning for the type, and it is a separate thing from the state this
# option splits on -- reported, and put right by writing rather than by
# splitting the object.
@test "test2" {
  $RUN_TEST acclint test2.acc --splitSURF -o test2.output.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.output.acc)"
  expected_file="$(tr -d '\r' < test2.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.acc test2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.acc
}

################################################################################

# The same object written as a .acc. What is reported is that the object
# changes state part way through, which is true of the file whoever reads it,
# so both formats are asked the same question and answer it the same way.
@test "test3" {
  $RUN_TEST acclint test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
