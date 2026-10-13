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
# A triangle strip is drawn as one surface with one sidedness flag, so every
# triangle in it has to fold the same way. One that is wound the other way
# leaves a gap the size of that triangle -- but only on a single sided
# surface, since a 2 sided one draws the reversed face anyway.
#
# test1.acc is a flat strip of ten refs with two of them swapped, so the strip
# folds back over itself and two triangles face down while the rest face up.
################################################################################

# test1.1: nothing else in the fixture is worth a diagnostic, so the check
# below is reporting the hole and not some side effect of the geometry.
@test "test1.1" {
  $RUN_TEST acclint test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
}

# test1.2: the hole itself. Off by default, so it has to be asked for.
@test "test1.2" {
  $RUN_TEST acclint -Wsurface-strip-hole test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$output" = "" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-hole test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint --quiet -Wsurface-strip-hole test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint --summary -Wsurface-strip-hole test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.7" {
  $RUN_TEST acclint --quiet --summary -Wsurface-strip-hole test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.7.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# test2: two strips concatenated into one surface, which is done by inserting
# degenerate triangles between them. They carry no area, so they draw nothing
# and have no facing, and the triangles on either side of them belong to
# different pieces of the model.
#
# The check used to skip a degenerate triangle while keeping the normal of the
# triangle before it, so the first triangle of the second piece was compared
# against the last triangle of the first piece -- across the join -- and the
# seam was reported as a hole. Both pieces here are wound consistently, so
# there is nothing to report.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-hole test2.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test3: test1's geometry with the surface left 2 sided. The reversed triangle
# is still there, but both of its faces are drawn, so there is no hole to see
# and nothing to report. This is what makes --fixSurface2SidedOpaque able to
# create one: clearing that flag is what turns the reversal into a gap.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-hole test3.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test4: a strip lifted out of a real Speed Dreams track, folding round a box
# corner: its neighbours meet at close to 90 degrees. It is one surface facing
# one way, and its vertex normals agree with every triangle. The check used to
# report a hole here, by rounding: the condition it tested could only be true
# when a fold came within a hair of 90 degrees.
################################################################################

@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-strip-hole test4.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
