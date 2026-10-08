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
  $RUN_TEST acclint -Wno-errors -Winvalid-kids-count test1.ac
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

@test "test2.2" {
  $RUN_TEST acclint -Wno-errors test2.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-kids-count test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.4" {
  $RUN_TEST acclint --quiet test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.5" {
  $RUN_TEST acclint --summary test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.6" {
  $RUN_TEST acclint --quiet --summary test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test3: "kids x" in a group followed by two objects, where the world asks for
# two. The recovery takes both for the group's, and the kids count it settles
# on is then one too many. That is reported at the kids line, and said to be
# a count the reading took rather than one the file gave. It was "kids count
# of 2", given at the last line of the file with nothing under the caret.
@test "test3" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test4: the world's "kids x" followed by its one kid and a line of junk. The
# recovery took the junk for the end of the kids and reported it, and then
# the world went on to read it as a line of its own and reported it again.
@test "test4" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}

# test5: the same with a second kids line in place of the junk. The kids end
# the object, as they do when there is a count, so the line after them is not
# read as the world's own kids line, and is reported once, by what reads it.
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
