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
# Each is now left exactly as it was found, so each expected file is its own
# input written back out.
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