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
# A texture name can resolve to something that exists but is not a regular
# file. This directory holds a directory named "tex.png" for exactly that.
#
# std::filesystem::exists() is satisfied by a directory, and file_size() then
# throws filesystem_error on it. Nothing on the texture lookup path catches
# that, so it ended the run through std::terminate rather than any diagnostic.
#
# -T is required to reach the branch at all: the duplicate texture comparison
# only runs when there are alternate texture paths to compare against, so
# without -T none of this code is entered.
################################################################################

# test1.1: must not abort, and must say nothing -- the texture resolves, so
# there is no missing texture to report and nothing to compare sizes against.
@test "test1.1" {
  $RUN_TEST acclint test1.ac -T textures
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
}

# test1.2: the texture must still be recorded on the object. Abandoning the
# size comparison with a `continue` in the enclosing line loop instead of the
# texture path loop silently dropped it, which this pins.
@test "test1.2" {
  $RUN_TEST acclint test1.ac -T textures --dump poly
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.3: and it must survive into a written file.
@test "test1.3" {
  $RUN_TEST acclint test1.ac -T textures -o test1.3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.3.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.3.output.ac test1.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.3.output.ac
}

################################################################################
