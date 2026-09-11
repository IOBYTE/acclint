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
# Converting .ac to .acc gives every vertex a normal, and turns the object
# into triangles on the way -- polygons are fanned, and a normal is worked out
# per vertex from the faces meeting there, honouring the object's crease
# angle.
#
# Those triangles are then strung back together into triangle strips, which is
# what the format is for. Only triangles that would share a SURF line can go
# on one strip: same material, and same shading and sidedness flags. The
# texture never enters into it, being a property of the object rather than of
# a surface, so every triangle in an object already shares it.
#
# A strip of a single triangle is no improvement on the triangle and costs a
# surface-strip-size warning, so it is written as a polygon instead. That is
# why the cubes below come out as six strips of two triangles rather than as
# twelve of anything, and why test5 -- whose two triangles meet at a corner
# rather than along an edge, and so cannot share a strip -- is unchanged by
# any of this.
################################################################################

@test "test1" {
  $RUN_TEST acclint test1.ac -o test1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.acc)"
  expected_file="$(tr -d '\r' < test1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.acc
}

################################################################################

@test "test2" {
  $RUN_TEST acclint test2.ac -o test2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.acc)"
  expected_file="$(tr -d '\r' < test2.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.acc
}

################################################################################

@test "test3" {
  $RUN_TEST acclint test3.ac -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.acc)"
  expected_file="$(tr -d '\r' < test3.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.acc
}

################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-different-uv test4.ac -o test4.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.acc)"
  expected_file="$(tr -d '\r' < test4.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.acc
}

################################################################################

@test "test5" {
  $RUN_TEST acclint test5.ac -o test5.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.acc)"
  expected_file="$(tr -d '\r' < test5.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.acc
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.ac -o test6.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test6.output.acc)"
  expected_file="$(tr -d '\r' < test6.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.acc
}

################################################################################