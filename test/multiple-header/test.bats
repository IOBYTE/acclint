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
# Two files joined end to end leave the second file's header line partway
# through. It was an invalid token, an error, so the file could not be written
# at all, not even with --fixMultipleWorlds, which joins the two worlds such a
# file has. It is a warning now, and what follows the line is read as the rest
# of the file. -o writes the one header at the top.
################################################################################

# test1.1: the second AC3Db line is a warning, not an error.
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

# test1.2: -Wno-multiple-header turns it off.
@test "test1.2" {
  $RUN_TEST acclint -Wno-multiple-header test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.3: -Wmultiple-header turns it back on after -Wno-warnings.
@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wmultiple-header test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.4: --fixMultipleWorlds joins the worlds, and b keeps green.
@test "test1.4" {
  $RUN_TEST acclint -Wno-warnings test1.ac --fixMultipleWorlds -o test1.4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.4.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.4.output.ac test1.4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.4.output.ac
}

# test1.5: the file written has one header and lints clean.
@test "test1.5" {
  $RUN_TEST acclint test1.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$output" = "" ]
}

################################################################################
# What follows a header was written for that header's version, so it is read
# as that version: a MAT block after an AC3Dc line is a material even in a
# file that began AC3Db. The file is written as the first header's version,
# with every material in that version's form. A second header of another
# version has a note pointing at the first.
################################################################################

# test2.1: AC3Db, then AC3Dc and a MAT block.
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

# test2.2: written as AC3Db, green as a MATERIAL line.
@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixMultipleWorlds -o test2.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
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

# test3.1: AC3Dc with a MAT block, then AC3Db and a MATERIAL line.
@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test3.2: written as AC3Dc, both materials as MAT blocks.
@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.ac --fixMultipleWorlds -o test3.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.2.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.2.output.ac test3.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.2.output.ac
}

# test3.3: the file written lints clean.
@test "test3.3" {
  $RUN_TEST acclint test3.result.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$output" = "" ]
}
