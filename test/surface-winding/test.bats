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
# .acc states which way a surface faces twice: once in the normals stored at
# its vertices, and once in the order of its refs. These two warnings report
# that the file's two statements no longer agree with each other.
#
# Neither says which side is meant to be drawn -- the format does not record
# that, and a wall you are meant to see the far side of through a window, a
# roof seen from inside, and a wall modelled with no thickness are all
# indistinguishable from a mistake. They are off by default and there is no
# fixer: what they are for is a generated model somebody has since edited by
# hand, where the geometry has moved and the normals have not.
#
# They are separate warnings because they mean different things. A surface
# consistently wound the other way from its normals is ordinary wherever thin
# panels are modelled, since the back face of one inherits the front's
# normals. A surface that agrees in places and opposes in others is the
# anomalous one, so it can be asked for on its own.
################################################################################

# test1: a strip wound the other way from its normals all the way along.
@test "test1.1" {
  $RUN_TEST acclint test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-opposed test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.3: the other warning must not pick this up. The two are reported
# separately so that either can be asked for without the other.
@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-mixed test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test2: the same strip folded, so one triangle opposes its normals and the
# other agrees.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-mixed test2.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-opposed test2.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test3: a polygon rather than a strip. .acc stores normals for those too, so
# the comparison applies the same way -- the polygon is fanned from its first
# ref to get triangles to compare.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-opposed test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# test4: a panel thin enough that its two sides share vertices, so the normal
# stored at a shared corner points away from this face. Averaging the three
# says nothing about which way the face is meant to point, so a triangle whose
# own vertices disagree with each other is not counted at all. Without that,
# every thin panel in a model reports.
################################################################################

@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-mixed -Wsurface-winding-opposed test4.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test5: normals at right angles to the face they belong to. Perpendicular is
# not disagreement -- it carries no statement about which side faces out -- so
# nothing is reported. Rounding decides the sign of a dot product that close
# to zero, which would make the warning come and go.
################################################################################

@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-mixed -Wsurface-winding-opposed test5.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test6: .ac, which has no per vertex normals, so there is no second statement
# to compare the winding against and the check does not apply.
################################################################################

@test "test6.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-winding-mixed -Wsurface-winding-opposed test6.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
