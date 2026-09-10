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
# kids nests objects, and reading a child is a recursive call, so the file
# decides how much stack to use. Nothing bounded it, and a deep enough file
# ran out of stack and died by signal before any diagnostic could be printed
# -- the one failure mode a linter cannot report on.
#
# Reading is now capped at MAX_OBJECT_LEVEL. The two fixtures sit either side
# of it and differ by exactly one group, so an off by one in the cap fails one
# of them whichever way it slips.
#
# No ulimit trickery is needed to make this a regression test: remove the cap
# and test1.2 parses silently instead of erroring, which is a plain output
# mismatch on any machine.
#
# Neither fixture is deep enough to threaten anything that opens it. An
# earlier version used 5000 levels here to make an unguarded build crash
# rather than merely misreport, which was belt and braces -- the output
# comparison already catches it -- and a file that deep crashes any reader
# that recurses, including modelling tools that might index this directory.
# Keep these shallow.
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

# test1.2: one group deeper than test1.1 and nothing else different, so this
# is the first file that must be refused -- and refused exactly once. The
# descent is restarted after a refusal, so an error reported per attempt
# rather than per file shows up here as a flood.
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

################################################################################
