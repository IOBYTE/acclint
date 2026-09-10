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
    rm -f ./*.output ./*.output.ac
}

################################################################################
# --combineTexture gathers every poly that shares a texture into one object,
# then rebuilds the world as an OPAQUE group and a TRANSPARENT group.
#
# It reorganises the world in place through m_objects[0], which assumes there
# is a world to reorganise. A file with no OBJECT parses with no errors at
# all, so nothing stops it reaching this transform through -o.
################################################################################

# test1.1: the ordinary case. p0 and p2 share red.png and merge into one
# object of 6 vertices; p1 keeps blue.png and stays at 3.
@test "test1.1" {
  $RUN_TEST acclint test1.1.ac -T textures --combineTexture -o test1.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.1.output.ac test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

# test1.2: materials but no OBJECT. Indexing m_objects[0] on the empty
# object list read past the end of the vector.
@test "test1.2" {
  $RUN_TEST acclint test1.2.ac --combineTexture -Wno-unused-material -o test1.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.2.output.ac)"
  expected_file="$(tr -d '\r' < test1.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.2.output.ac test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.2.output.ac
}

# test1.3: nothing but the header. Same empty object list, reached by a
# different route, and the smallest input that can get here.
@test "test1.3" {
  $RUN_TEST acclint test1.3.ac --combineTexture -o test1.3.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.3.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.3.output.ac test1.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.3.output.ac
}

################################################################################
