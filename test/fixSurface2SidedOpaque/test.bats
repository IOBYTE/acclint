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
  $RUN_TEST acclint test1.ac --fixSurface2SidedOpaque -o test1.output.ac
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
  $RUN_TEST acclint test2.ac --fixSurface2SidedOpaque -o test2.output.ac
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
  $RUN_TEST acclint test3.acc --fixSurface2SidedOpaque -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.acc)"
  expected_file="$(tr -d '\r' < test3.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.acc
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint test4.acc --fixSurface2SidedOpaque -o test4.output.acc
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
# A polygon is a single face, so clearing its 2 sided flag can only change
# which side is drawn. A triangle strip is one surface carrying one flag for
# all of its triangles, and those can disagree with each other -- and a 2
# sided surface is what has been hiding that. .acc stores a normal per vertex,
# which says which way each triangle is meant to face, so the strip is only
# converted when they all agree.
################################################################################

# test5: one triangle of the strip is wound against the normals its vertices
# carry and the other is not. No choice of side is right for both, so the
# surface keeps the second side -- hiding the reversed triangle is the one
# thing it is still doing. Converting it would open a hole the size of that
# triangle.
@test "test5.1" {
  $RUN_TEST acclint test5.acc --fixSurface2SidedOpaque -o test5.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.acc)"
  expected_file="$(tr -d '\r' < test5.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.acc
}

################################################################################

# test6: every triangle is wound against the normals its vertices carry, so
# the strip looks like it is simply facing the wrong way. It is still left
# alone. Which side of a surface is meant to be drawn is a modelling decision
# the geometry does not record: a wall you are meant to see the far side of
# through a window, a roof seen from inside a building, and a wall modelled
# with no thickness at all are all indistinguishable from a mistake here, so
# nothing is turned over on this evidence.
@test "test6.1" {
  $RUN_TEST acclint test6.acc --fixSurface2SidedOpaque -o test6.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test6.output.acc)"
  expected_file="$(tr -d '\r' < test6.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.acc
}

################################################################################

# test7: a panel thin enough that its two sides share vertices, so the normal
# stored at a shared corner points away from this face rather than along it.
# Averaging the three is then meaningless -- and it averages out in favour of
# the face here, so a version that trusts the mean converts this and gets it
# wrong. A triangle whose own vertices disagree with each other is not counted
# at all, which leaves nothing here to judge the strip by, so it keeps both
# sides. Across a real track 68% of the strips this measure called suspect had
# a triangle like this in them, against 2.6% of triangles overall.
@test "test7.1" {
  $RUN_TEST acclint test7.acc --fixSurface2SidedOpaque -o test7.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.output.acc)"
  expected_file="$(tr -d '\r' < test7.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test7.output.acc
}