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
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-errors test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-ref-vertex-index test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test2" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-errors test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-ref-vertex-index test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.4" {
  $RUN_TEST acclint --quiet test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.5" {
  $RUN_TEST acclint --summary test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.6" {
  $RUN_TEST acclint --quiet --summary test3.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test4: a quad whose second ref has no number where its index should be, next
# to a ref that names vertex 0. The failed read left the index 0, so the ref
# was compared as vertex 0, and "duplicate surface vertices" was reported with
# the error. It names no vertex now. Its texture coordinates, 1 0, are still
# read, so a surface with them and no texture is reported too.
@test "test4" {
  $RUN_TEST acclint test4.ac -Wno-unused-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test5: a ref whose index is 2.5. It is not an index, and is reported as one
# that cannot be read. It was read as 2, the ".5" taken for its u and the rest
# shifted along, with only "trailing text" said.
@test "test5" {
  $RUN_TEST acclint test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test6: a ref whose index is -1. It cannot be read as an index. It was read
# into an unsigned index as 18446744073709551615 and reported as that.
@test "test6" {
  $RUN_TEST acclint test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# With the error turned off nothing refused -o, and a ref that names no
# vertex was written as the index it was read as: 18446744073709551615 for
# one that was not a number, or a vertex that is not there. The file written
# did not load. The surface cannot be drawn without the vertex, so it is
# dropped, and each one dropped is said.
################################################################################

# test7.1: the first surface is kept; the second has a ref that is not a
# number and the third one past the last vertex, and both go.
@test "test7.1" {
  $RUN_TEST acclint -Wno-invalid-ref-vertex-index test7.ac -o test7.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test7.1.output.ac)"
  expected_file="$(tr -d '\r' < test7.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test7.1.output.ac test7.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test7.1.output.ac
}

# test7.2: the file written lints clean.
@test "test7.2" {
  $RUN_TEST acclint test7.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.2.output
  fi
  [ "$output" = "" ]
}

# test7.3: with the error on, -o is still refused.
@test "test7.3" {
  $RUN_TEST acclint test7.ac -o test7.3.output.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.3.output
  fi
  [ "$actual" = "$expected" ]
}
