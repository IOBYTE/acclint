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

@test "test1" {
  $RUN_TEST acclint test1.ac --splitSURF -Wno-different-surf -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
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
