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
    rm -f ./*.output ./*.output.ac
}

################################################################################
# kids nests objects, and reading a child is a recursive call. The file says
# how deep the nesting goes, so the file also says how much stack to use.
# Nothing bounded it, so a deep enough file ran out of stack and died by
# signal before any diagnostic could be printed -- the one failure mode a
# linter cannot report on.
#
# Reading is now capped at 128 levels. The cap is a plain output difference,
# which is what makes this suite work without any ulimit trickery: remove the
# cap and the refusals below turn into silence, so the comparison fails on a
# machine where the file happens to fit in the stack, and the crash speaks for
# itself on one where it does not.
#
# The fixtures are generated, so the shapes are exact: 126 groups between the
# world and the leaf is 128 objects, the deepest that is allowed.
################################################################################

# test1.1: the deepest legitimate file. It must lint clean -- an off by one in
# the cap shows up here as a spurious error -- and it must still write out
# whole, since the guard sits on the read path that feeds the writer.
@test "test1.1" {
  $RUN_TEST acclint test1.1.ac -o test1.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.1.output.ac test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

# test1.2: one group deeper than test1.1, and nothing else different. This is
# the other half of the off by one: the first file that must be refused.
#
# -Wno-unused-material keeps the comparison on the nesting error. Refusing the
# file leaves its material unreferenced, which is true but is a consequence of
# the refusal rather than something this suite is pinning.
@test "test1.2" {
  $RUN_TEST acclint test1.2.ac -Wno-unused-material
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

# test1.3: 5000 groups, deep enough to exhaust the stack rather than merely
# exceed the cap -- it segfaults an unguarded build on Linux at the stock 8MB
# and on Windows at 1MB. It must produce the same single error as test1.2, and
# exactly one of them: the descent is restarted after the refusal, so an error
# reported per attempt rather than per file shows up here as a flood.
@test "test1.3" {
  $RUN_TEST acclint test1.3.ac -Wno-unused-material
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
