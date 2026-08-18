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
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Woverlapping-2-sided-surface test1.ac
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

@test "test2" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test2.result)" ]
}

################################################################################

@test "test3" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test3.result)" ]
}

################################################################################

@test "test4" {
  $RUN_TEST acclint test4.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test4.result)" ]
}

################################################################################

# Regression test: the overlapping triangle here is the 3rd triangle of a
# 5-ref triangle-strip surface (stripB), not its 1st. This distinguishes
# triangle.refs[k] (the specific overlapping triangle's vertex refs) from
# surface.refs[k] (always the surface's first 3 refs) -- a bug that was
# invisible on plain 3-ref triangle surfaces because the two coincide there.
@test "test5" {
  $RUN_TEST acclint test5.acc
  [ "$status" -eq 0 ]
  [ "$output" = "$(tr -d '\r' < test5.result)" ]
}

################################################################################
