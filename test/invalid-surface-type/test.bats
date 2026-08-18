#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

################################################################################

@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.result)" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-errors test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-surface-type test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.result)" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.4.result)" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.5.result)" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test1.6.result)" ]
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.result)" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-errors test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-errors -Winvalid-surface-type test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.result)" ]
}

@test "test2.4" {
  $RUN_TEST acclint --quiet test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.4.result)" ]
}

@test "test2.5" {
  $RUN_TEST acclint --summary test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.5.result)" ]
}

@test "test2.6" {
  $RUN_TEST acclint --quiet --summary test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.6.result)" ]
}

################################################################################

# Regression test: an "invalid surface type" error prints its flags value in
# hex (std::hex) -- this file has a second invalid-surface-type error later
# in the same run, whose file:line prefix must still print in decimal. If
# std::hex leaks onto the shared std::cerr stream without a std::dec reset,
# every line number after the first error (here, "26") gets corrupted into
# hex ("1a").
@test "test3" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test3.result)" ]
}

################################################################################
