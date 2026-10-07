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
  $RUN_TEST acclint test1.1.ac --splitPolygon -o test1.1.output.ac
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
  $RUN_TEST acclint test1.2.ac --splitPolygon -o test1.2.output.ac
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
  $RUN_TEST acclint test1.3.ac --splitPolygon -Wno-collinear-surface-vertices -o test1.3.output.ac
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
# The split fans from the first vertex, which only reproduces the original
# shape for a convex polygon. It used to be applied to every surface with
# more than three refs, whatever the surface was, and the three below are
# what that produced:
#
#   a triangle strip  -- a strip triangulates as (i-2, i-1, i) with the
#                        winding alternating, so fanning from one distant
#                        vertex kept only the first triangle and replaced
#                        39 of the other 40 with triangles that were never
#                        in the model. convertObjectToAc already converts
#                        strips correctly; -v 11 uses it.
#   a closed line     -- five refs came out as three separate closed lines,
#                        and a polyline the same way.
#   a concave polygon -- fans into triangles covering ground outside it.
#
# The strip and the lines are now left exactly as they were found, so their
# expected files are their own inputs written back out. The concave polygon,
# an L (test2.3), is cut by ear clipping instead, into four triangles that all
# lie inside it.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.1.acc --splitPolygon -o test2.1.output.acc
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test2.1.output.acc)"
  expected_file="$(tr -d '\r' < test2.1.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.1.output.acc test2.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.1.output.acc
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.2.ac --splitPolygon -o test2.2.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test2.2.output.ac)"
  expected_file="$(tr -d '\r' < test2.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.2.output.ac test2.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.2.output.ac
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings test2.3.ac --splitPolygon -o test2.3.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test2.3.output.ac)"
  expected_file="$(tr -d '\r' < test2.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.3.output.ac test2.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.3.output.ac
}

@test "test2.4" {
  $RUN_TEST acclint -Wno-warnings test2.4.ac --splitPolygon -o test2.4.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test2.4.output.ac)"
  expected_file="$(tr -d '\r' < test2.4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.4.output.ac test2.4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.4.output.ac
}

################################################################################
# The surface after a split polygon was never split itself: having inserted
# size - 3 triangles after the first, the loop skipped size - 2 surfaces and
# its own ++i stepped one past the next original. Three quads in a row came
# out as refs 3 3 4 3 3, and nothing said so.
#
# test3.1 is that case. test3.2 mixes sizes -- a pentagon inserts two
# triangles, a quad one -- and ends on a triangle, so a skip of the wrong
# length in either direction shows up as an unsplit polygon or a lost one.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.1.ac --splitPolygon -o test3.1.output.ac
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

@test "test3.2" {
  $RUN_TEST acclint test3.2.ac --splitPolygon -o test3.2.output.ac
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
# A poly with kids is outside the format, but articulated models are built
# that way -- a lever with its knob hung off it, so the knob moves with the
# lever -- and the hierarchy is left as it was read unless --fixPolyWithKids
# is given. The knob is as much a part of the model as the lever, so it gets
# the same treatment as any other object.
################################################################################

# test3.3: the knob holds a quad. It is split into two triangles.
@test "test3.3" {
  $RUN_TEST acclint -Wno-poly-with-kids test3.3.ac --splitPolygon -o test3.3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.3.output.ac)"
  expected_file="$(tr -d '\r' < test3.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.3.output.ac test3.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.3.output.ac
}

################################################################################
# What is concave is cut by ear clipping, and what is convex is fanned, into
# triangles with area. A concave polygon taken for convex -- at millimetre
# scale, or with its notch point doubled -- was fanned into a triangle that
# covered the notch. A ref that repeats the point before it is left out, and
# so is a triangle of three points on one line, which covers nothing.
################################################################################

# test4.1: the 1 mm arrowhead. Concave, so it is cut along the diagonal
# through its notch, into two triangles inside it.
@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings test4.1.ac --splitPolygon -o test4.1.output.ac
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

# test4.2: the arrowhead with its notch point doubled 1e-7 away. The doubled
# ref is left out, and the rest is cut the same way as test4.1.
@test "test4.2" {
  $RUN_TEST acclint -Wno-warnings test4.2.ac --splitPolygon -o test4.2.output.ac
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

# test4.3: a rectangle with a point doubled half way along one side. It comes
# out as the two triangles that cover it, and nothing with no area.
@test "test4.3" {
  $RUN_TEST acclint -Wno-warnings test4.3.ac --splitPolygon -o test4.3.output.ac
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
# The same goes for a concave polygon that is not quite flat.
################################################################################

# test4.4: an L with one corner lifted 1 mm. Concave, so it is cut into four
# triangles inside it, where it was fanned into triangles covering the notch.
@test "test4.4" {
  $RUN_TEST acclint -Wno-warnings test4.4.ac --splitPolygon -o test4.4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.4.output.ac)"
  expected_file="$(tr -d '\r' < test4.4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.4.output.ac test4.4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.4.output.ac
}

################################################################################

