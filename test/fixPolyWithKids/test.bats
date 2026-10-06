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
# --fixPolyWithKids: a poly with kids and no surfaces of its own is a group
# given the wrong type. Every TORCS speedway keeps its terrain under an empty
# poly "TERR", and the kc- cars hang their parts off an empty poly at the
# root. The fix types it as the group it is used as, keeping its name, loc,
# rot and crease, and drops any vertices it lists, which with no surfaces
# nothing uses.
#
# A poly with surfaces and kids is a different thing: articulated models hang
# a moving part off the part it moves with, and it is left alone.
#
# The written file is linted again in each test: the fix must leave nothing
# behind to warn about -- no poly with kids, no missing surfaces, no group
# with geometry.
################################################################################

# test1: an empty poly at the root holding the parts, one of which is itself
# an empty poly holding more. Both become groups; the root keeps its loc and
# crease.
@test "test1" {
  $RUN_TEST acclint -Wno-warnings test1.ac --fixPolyWithKids -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.ac test1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  $RUN_TEST acclint test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  rm test1.output.ac
}

# test2: an empty poly that still lists two vertices. They go with the type,
# rather than leave a group with geometry.
@test "test2" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixPolyWithKids -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.ac test2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  $RUN_TEST acclint test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  rm test2.output.ac
}

# test3: a lever with surfaces of its own and a knob hung off it. Not the
# mistake this fixes, so it is written exactly as it would be without the
# option, and still warned about.
@test "test3" {
  $RUN_TEST acclint -Wno-warnings test3.ac --fixPolyWithKids -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.output.ac test3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  $RUN_TEST acclint -Wno-warnings -Wpoly-with-kids test3.output.ac
  [ "$status" -eq 0 ]
  [[ "$(echo "${lines[0]}" | tr -d '\r')" == *"warning: poly with kids" ]]
  rm test3.output.ac
}

################################################################################
