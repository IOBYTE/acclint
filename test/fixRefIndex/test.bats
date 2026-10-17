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
# --fixRefIndex puts right a ref that names no vertex -- not a number, or a
# number past the last vertex -- when exactly one vertex fits it, and says
# which. A vertex fits when the edges the ref would make are the edges the
# surfaces around it have the other way round, and the surface it makes has
# a shape. When no vertex matches, a vertex no surface uses is tried. When
# none fits, or more than one does, the surface is dropped, and that is said
# too. It answers the invalid ref vertex index errors, so -o is not refused
# for them; they are still reported.
################################################################################

# test1.1: a cube with one corner of one face given as z. Only vertex 6 makes
# both edges match the faces around it.
@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac --fixRefIndex -o test1.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.1.output.ac test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

# test1.2: the cube written lints clean.
@test "test1.2" {
  $RUN_TEST acclint test1.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

# test1.3: without --fixRefIndex, -o is refused as before.
@test "test1.3" {
  $RUN_TEST acclint test1.ac -o test1.3.output.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

# test2.1: the same corner given as 9, past the last vertex.
@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixRefIndex -o test2.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.1.output.ac test2.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.1.output.ac
}

# test3.1: a lone triangle has no neighbours to match. Vertex 0 is the only
# vertex no surface uses, and it makes a triangle.
@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings test3.ac --fixRefIndex -o test3.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test3.1.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.1.output.ac test3.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.1.output.ac
}

# test4.1: two unused vertices both make a triangle. There is no telling
# which, so the surface is dropped.
@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings test4.ac --fixRefIndex -o test4.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test4.1.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.1.output.ac test4.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.1.output.ac
}

# test5.1: two triangle strips across a grid; a ref of the second, on the row
# the two share, is z. The first strip's edges say it is vertex 5.
@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings test5.acc --fixRefIndex -o test5.1.output.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test5.1.output.acc)"
  expected_file="$(tr -d '\r' < test5.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.1.output.acc test5.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.1.output.acc
}

# test5.2: the strips written lint clean.
@test "test5.2" {
  $RUN_TEST acclint test5.result.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.2.output
  fi
  [ "$output" = "" ]
}
