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
# A SURF that ends before its refs line. What comes instead was taken for an
# invalid token and read and lost with it: a SURF there took the surface it
# began along with it, and the surfaces after were each read as junk; a kids
# line there left the object to run on into the next one, and its kids line
# was reported missing. It is put back now to be read as what it is, and the
# surface is reported as missing refs, an error, at its SURF line.
################################################################################

# test1: the first of two surfaces has no refs, and the second follows it.
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
  $RUN_TEST acclint -Wno-errors -Wmissing-refs test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.5: -Wno-missing-refs suppresses the error.
@test "test1.5" {
  $RUN_TEST acclint -Wno-missing-refs test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$output" = "" ]
}

# test1.6: an error, so nothing is written.
@test "test1.6" {
  rm -f test1.6.output.ac
  run acclint test1.ac -o test1.6.output.ac
  [ "$status" -eq 1 ]
  [ ! -e test1.6.output.ac ]
}

# test1.7: with the error turned off the file is written, and the surface with
# no refs is left out of it as one with nothing to draw.
@test "test1.7" {
  $RUN_TEST acclint -Wno-missing-refs test1.ac -o test1.7.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.7.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.7.output.ac)"
  expected_file="$(tr -d '\r' < test1.7.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.7.output.ac test1.7.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.7.output.ac
}

# test2: the last surface of the first object has no refs, and the object's
# kids line follows it. The kids line is read as one, and the second object as
# the next object.
@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test3: the same with no mat and no kids line either: the next OBJECT follows
# the SURF. The missing kids line is reported as before, and the second object
# is still read as one.
@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
