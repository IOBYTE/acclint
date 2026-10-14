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
  $RUN_TEST acclint -Wno-extra-object test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wmultiple-world test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-extra-object --quiet test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint -Wno-extra-object --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint -Wno-extra-object --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.7" {
  $RUN_TEST acclint -Wno-extra-object test1.ac --fixMultipleWorlds -o test1.7.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.7.output
  fi
  [ "$actual" = "$expected" ]
  actual_ac="$(tr -d '\r' < test1.7.output.ac)"
  expected_ac="$(tr -d '\r' < test1.7.result.ac)"
  [ "$actual_ac" = "$expected_ac" ]
  rm test1.7.output.ac
}


################################################################################
# Two files joined end to end each bring their own materials, and the second
# file's surfaces number its materials from 0. --fixMultipleWorlds moves them
# past the first file's. It only counted materials on the lines directly above
# the second world, and refused the join when it found any: a blank line or a
# MAT block hid them, and the worlds were joined with the second file's
# surfaces still on the first file's materials -- its own were dropped as
# unused and object b came out red. Even a refused join wrote b red.
################################################################################

# test2.1: green directly above the second world. b gets mat 1, green kept.
@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixMultipleWorlds -o test2.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.1.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.1.output.ac test2.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.1.output.ac
}

# test2.2: the file written lints clean.
@test "test2.2" {
  $RUN_TEST acclint test2.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
}

# test3.1: a blank line between green and the second world.
@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings test3.ac --fixMultipleWorlds -o test3.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.1.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.1.output.ac test3.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.1.output.ac
}

# test3.2: the file written lints clean.
@test "test3.2" {
  $RUN_TEST acclint test3.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
}

# test4.1: AC3Dc, green a MAT block.
@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings test4.ac --fixMultipleWorlds -o test4.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.1.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.1.output.ac test4.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.1.output.ac
}

# test4.2: the file written lints clean.
@test "test4.2" {
  $RUN_TEST acclint test4.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$output" = "" ]
}

# test5.1: the second file uses mat 1 but has only green. There is no telling
# what it meant, and moved it would point past every material, so the join is
# refused and the file is written as it was.
@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings test5.ac --fixMultipleWorlds -o test5.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test5.1.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.1.output.ac test5.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.1.output.ac
}

################################################################################
# A world nested in another, spelled World. The multiple world check compared
# the type before it was lowercased, so only "should be lowercase" was said,
# and the second world was reported only once -o had written it lowercase.
################################################################################

# test6.1: both warnings, at line 19.
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
