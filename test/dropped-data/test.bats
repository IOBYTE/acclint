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
# A version 11 file writes each material on one MATERIAL line, which has no
# room for data: only a version 12 MAT block holds it. Writing version 11
# dropped a material's data without a word. It is a warning now, given when
# -o is going to write version 11, at the material's data line.
################################################################################

# test1.1: linting alone writes nothing, so nothing is dropped.
@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
}

# test1.2: -o keeps the file's version 12, and the data with it.
@test "test1.2" {
  $RUN_TEST acclint test1.ac -o test1.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.2.output.ac)"
  expected_file="$(tr -d '\r' < test1.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.2.output.ac test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.2.output.ac
}

# test1.3: -v 11 drops it, and says so.
@test "test1.3" {
  $RUN_TEST acclint test1.ac -v 11 -o test1.3.output.ac
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

# test1.4: -Wno-dropped-data turns it off.
@test "test1.4" {
  $RUN_TEST acclint -Wno-dropped-data test1.ac -v 11 -o test1.4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.4.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.4.output.ac test1.4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.4.output.ac
}

# test1.5: counted in the summary.
@test "test1.5" {
  $RUN_TEST acclint --summary test1.ac -v 11 -o test1.5.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.5.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.5.output.ac test1.5.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.5.output.ac
}

################################################################################
# test2: two files joined, AC3Db then AC3Dc with a MAT block holding data.
# The file is written as its first header's version, 11, so the data goes.
################################################################################

@test "test2" {
  $RUN_TEST acclint -Wno-warnings -Wdropped-data test2.ac --fixMultipleWorlds -o test2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.ac test2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################
# test3: a version 12 file with material data merged into a version 11 one.
# The merged materials are written as version 11 too, and the merge file's
# data line is the one pointed at.
################################################################################

@test "test3" {
  $RUN_TEST acclint test3.ac --merge test1.ac -o test3.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.output.ac test3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.ac
}
