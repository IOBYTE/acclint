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
# --fixPolyWithKids: a poly with kids becomes a group, and its kids stay
# under it.
#
# A poly with no surfaces of its own is a group given the wrong type. Every
# TORCS speedway keeps its terrain under an empty poly "TERR", and the kc- cars
# hang their parts off an empty poly at the root. The fix types it as the group
# it is used as, keeping its name, loc, rot and crease, and drops any vertices
# it lists, which with no surfaces nothing uses.
#
# A poly with surfaces and kids is an articulated part: a lever with its knob
# hung off it, so that the knob moves with the lever. The group keeps the name,
# loc and rot, so whatever animates it by name still finds it and its kids are
# under the same transform as before. Its geometry moves to a new poly named
# "<name>-geometry", the group's first kid, with no loc or rot of its own, so
# it draws where it did.
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

# test3: a lever with surfaces of its own and a knob hung off it. The lever
# becomes a group holding its loc, with "lever-geometry" and the knob under it.
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
  $RUN_TEST acclint test3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  rm test3.output.ac
}

# test4: an arm with a hand hung off it and a finger off the hand, each a poly
# with surfaces and a loc, the arm also with a rot. The arm carries everything
# an object can, so each part can be seen to land on the right side: name,
# url, loc, rot, folded and data stay with the group; texture, texrep, texoff,
# crease, vertices and surfaces go to "arm-geometry". The hand under it is
# split the same way, the finger, with no kids, is left alone. The second poly
# at the root has no name, and neither does its geometry.
@test "test4" {
  $RUN_TEST acclint -Wno-warnings test4.ac --fixPolyWithKids -o test4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.output.ac test4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  $RUN_TEST acclint -Wno-missing-texture test4.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  rm test4.output.ac
}

################################################################################
