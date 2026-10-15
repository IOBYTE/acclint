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
# --dump prints the object hierarchy: groups in every mode, polys with poly
# and surf, and their surfaces with surf. test1.ac has a light, a poly, and a
# group under the poly.
#
# A light is part of the hierarchy the way a group is, and is shown the same
# way in every mode. It was never shown at all.
#
# So is a poly with kids in group mode, where polys are not otherwise shown:
# the kids hang off it, and without its line "wheels" was shown under the
# light.
#
# Anything the format does not allow is tagged on its line, with the line the
# object starts on: here the poly with kids.
################################################################################

@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings --dump group test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings --dump poly test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings --dump surf test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test2: an object of a type the format does not have, OBJECT foo, holding a
# poly. It is listed with its kid under it, as a group would be. It was left
# out, and its kid was listed with no parent line.
@test "test2" {
  $RUN_TEST acclint -Wno-warnings --dump poly test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# test3: a file that breaks the spec in many ways. Every mode tags what is
# wrong: a group with geometry, a poly with kids, a world inside the world
# spelled World, a type that does not exist, two names, and a kids count the
# file cannot honour -- the declared and the found counts are both shown.
################################################################################

# test3.1: group mode, which leaves leaf polys out.
@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings --dump group test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test3.2: poly mode, everything.
@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings --dump poly test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test3.3: problems mode: only the tagged objects and the objects above them,
# each keeping its number among its siblings. "fine" and its poly are left
# out, and so is the poly door under body.
@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings --dump problems test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# test4: a file with nothing wrong in it says so.
################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-warnings --dump problems test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}
