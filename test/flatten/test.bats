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
# it and then drops the loc and rot that said it. What has to hold is that
# everything the dropping reaches the pushing reaches too, at every depth and
# whatever is found there.
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

# test3.2: placements compose all the way down. "shallow" sits under one group
# at x=10 and "deep" under a further group at y=5 inside it, so the two have to
# come out ten apart in x and five apart in y, and both locs have to be gone. A
# walk that pushed only the nearest ancestor's placement, or dropped a loc on
# the way down without carrying it, leaves "deep" somewhere it does not belong.
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
# A kid's own placement comes first, then its parents'. They were composed the
# other way round, which put a parent's rot before the kid's loc, so a kid with
# a loc under a rotated group was baked somewhere else -- and so was a light.
# The tests above only ever moved things, and a move commutes with a move.
################################################################################

# test4.1: a group at x=10 turned 90 degrees, holding two triangles that are
# the same triangle in the group's frame: A written where it is, B written one
# unit back and given loc 1 0 0. They come out as the same triangle.
@test "test4.1" {
  $RUN_TEST acclint test4.1.ac --flatten -o test4.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.1.output.ac)"
  expected_file="$(tr -d '\r' < test4.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.1.output.ac test4.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.1.output.ac
}

# test4.2: a light and a triangle's first corner at the same point in the
# frame of the same rotated group. They come out at the same point.
@test "test4.2" {
  $RUN_TEST acclint test4.2.ac --flatten -o test4.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.2.output.ac)"
  expected_file="$(tr -d '\r' < test4.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.2.output.ac test4.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.2.output.ac
}

# test4.3: a group with geometry of its own. Its loc is baked into its kid, and
# into its own vertices too: they were left where they were while the loc
# that placed them was thrown away.
@test "test4.3" {
  $RUN_TEST acclint -Wno-group-with-geometry test4.3.ac --flatten -o test4.3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.3.output.ac)"
  expected_file="$(tr -d '\r' < test4.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.3.output.ac test4.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.3.output.ac
}

################################################################################
