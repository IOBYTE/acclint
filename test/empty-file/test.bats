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
# An empty file is a fatal error that no flag turns off: there is nothing to
# read and nothing to write. It was "missing AC3D", and a file holding only a
# UTF-8 BOM was "not AC3D file", which -Wno-errors turned off, so the file was
# refused with no word at all.
################################################################################

# test1.1: no bytes at all.
@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.2: -Wno-errors -Wno-warnings does not turn it off.
@test "test1.2" {
  $RUN_TEST acclint -Wno-errors -Wno-warnings test1.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test2.1: nothing but blank lines, which are skipped.
@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test2.2: -Wno-errors -Wno-warnings does not turn it off.
@test "test2.2" {
  $RUN_TEST acclint -Wno-errors -Wno-warnings test2.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test3.1: a UTF-8 BOM and nothing after it.
@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test3.2: -Wno-errors -Wno-warnings leaves the error, without the BOM warning.
@test "test3.2" {
  $RUN_TEST acclint -Wno-errors -Wno-warnings test3.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test4.1: a UTF-8 BOM followed only by blank lines.
@test "test4.1" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test4.2: -Wno-errors -Wno-warnings does not turn it off.
@test "test4.2" {
  $RUN_TEST acclint -Wno-errors -Wno-warnings test4.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$actual" = "$expected" ]
}
