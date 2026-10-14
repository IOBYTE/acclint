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
# The format starts with a world: the first OBJECT is the world and every
# other object is under it. A file whose first OBJECT is anything else has no
# world, and used to pass without a word. It is a warning now, given at that
# first OBJECT before anything about its contents, and -o writes the file with
# a world added that holds all the top-level objects, so the output starts
# with one and lints clean.
################################################################################

# test1.1: a lone poly with no world.
@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.2: -Wno-missing-world turns it off.
@test "test1.2" {
  $RUN_TEST acclint -Wno-missing-world test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

# test1.3: -Wmissing-world turns it back on after -Wno-warnings.
@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wmissing-world test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.4: -o puts the poly in a new world.
@test "test1.4" {
  $RUN_TEST acclint test1.ac -o test1.4.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.4.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.4.output.ac test1.4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.4.output.ac
}

# test1.5: the file written has its world and lints clean.
@test "test1.5" {
  $RUN_TEST acclint test1.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$output" = "" ]
}

################################################################################
# Two top-level objects and no world: the warning is given once, at the first,
# and the extra OBJECT warning still points at the second. -o puts both in
# the new world, which also leaves nothing extra.
################################################################################

# test2.1: lint.
@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test2.2: -o puts both objects in one world of 2 kids.
@test "test2.2" {
  $RUN_TEST acclint test2.ac -o test2.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.2.output.ac test2.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.2.output.ac
}

# test2.3: the file written lints clean.
@test "test2.3" {
  $RUN_TEST acclint test2.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$output" = "" ]
}

################################################################################
# Files that are not missing a world.
################################################################################

# test3.1: the poly is under a world, so there is nothing to say.
@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
}

# test4.1: an OBJECT with no type is an invalid object type, and no missing
# world on top: there is no type to say it is not a world.
@test "test4.1" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test5.1: a first object spelled World is a world, with its own warning, and
# not a missing one.
@test "test5.1" {
  $RUN_TEST acclint test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test5.2: -o writes it lowercase and adds no second world.
@test "test5.2" {
  $RUN_TEST acclint test5.ac -o test5.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test5.2.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.2.output.ac test5.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.2.output.ac
}

################################################################################
# A file with no OBJECT at all has no world either, and is most likely cut
# off. It was an error with no flag and no summary line, which stopped -o.
# It is a missing world now, with a hint that the file may be truncated, and
# -o writes a world with no kids: a file that loads and draws nothing.
################################################################################

# test6.1: nothing but the header.
@test "test6.1" {
  $RUN_TEST acclint test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test6.2: -Wno-missing-world turns it off like any other missing world.
@test "test6.2" {
  $RUN_TEST acclint -Wno-missing-world test6.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.2.output
  fi
  [ "$output" = "" ]
}

# test6.3: -o writes the empty world.
@test "test6.3" {
  $RUN_TEST acclint test6.ac -o test6.3.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.3.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test6.3.output.ac)"
  expected_file="$(tr -d '\r' < test6.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test6.3.output.ac test6.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test6.3.output.ac
}

# test6.4: the file written lints clean.
@test "test6.4" {
  $RUN_TEST acclint test6.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.4.output
  fi
  [ "$output" = "" ]
}
