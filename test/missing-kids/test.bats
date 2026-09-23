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
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wmissing-kids test1.ac
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
  $RUN_TEST acclint -Wno-warnings test2.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Wmissing-kids test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings -Wmissing-kids test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: test4.ac's `kids 1` block is followed by a line that
# isn't an OBJECT token, with nothing after it. The recovery loop that
# scans forward for an OBJECT token used to call getLine() without
# checking whether it succeeded before looping back to try again, so once
# it ran out of input it looped calling getLine() forever instead of
# reporting "missing kids" and returning -- an unconditional hang on any
# file shaped like this one, not just a slow/large one. If this hangs
# instead of completing, that fix regressed.

@test "test4.1" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.2" {
  $RUN_TEST acclint -Wno-warnings test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.3" {
  $RUN_TEST acclint -Wno-warnings -Wmissing-kids test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# test5: a group that says it holds two objects when only one follows it. The
# one it takes instead belongs to the world, so what is read is "second" and
# its poly sitting inside "first", and the world left holding one object
# where it asked for two. Nothing is lost -- every object is still there --
# but the tree is not the one the file describes, and everything after the
# read works on the tree.
#
# The counts say where the mistake is: whatever is still waiting when the
# objects run out lies on the path to the last one read, and the surplus has
# to come off one of those. It comes off the innermost that can carry it and
# that has something above it still waiting, which is "first", and the same
# objects are then put back together in the same order.
#
# test5.3 is the one that matters: the tree that is written out, which is
# this one only when --fixKids asks for it. The counting runs either way and
# says what it found either way, but a read that is only being told what is
# wrong with a file leaves its tree alone (test5.4).
################################################################################

@test "test5.1" {
  $RUN_TEST acclint test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test5.2" {
  $RUN_TEST acclint -Wno-warnings test5.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.2.output
  fi
  [ "$output" = "" ]
}

@test "test5.3" {
  $RUN_TEST acclint -Wno-warnings --fixKids test5.ac -o test5.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.output.ac test5.3.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

@test "test5.4" {
  $RUN_TEST acclint -Wno-warnings test5.ac -o test5.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.as-read.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.output.ac test5.4.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

################################################################################
# test6: "first" says two and one object follows it, "second" says two and one
# object follows it, and the world says three and gets one. Three objects are
# asked for that the file does not hold, and no single count can account for
# all three -- either of the groups could have taken what belongs to the other,
# and a count that is too large by a little reads exactly like one that is
# right.
#
# So the objects stay where the read put them, and that is said out loud: this
# is not the tree the file describes, and which group took what cannot be
# worked out from the file. It is an error rather than a warning -- not
# something -Wno-warnings puts aside (test6.2) -- because writing it out would
# put this tree in a file of its own with the counts corrected to match it,
# making the mistake permanent and leaving nothing behind to say it happened.
# Nothing is written (test6.3).
#
# A file that merely stops short is a different thing and is left alone:
# test1, test2 and test3 are those, and they still only warn.
################################################################################

@test "test6.1" {
  $RUN_TEST acclint test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test6.2" {
  $RUN_TEST acclint -Wno-warnings test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test6.3" {
  $RUN_TEST acclint -Wno-warnings test6.ac -o test6.output.ac
  [ "$status" -ne 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.3.output
  fi
  [ "$actual" = "$expected" ]
  [ ! -f test6.output.ac ]
}

################################################################################

################################################################################
# test7: every group in the file takes exactly the children it asks for, and
# the world asks for four and gets two. Nothing is above the world, so there
# is nowhere else those two could have gone and no other count is in question:
# what was read is the tree the file describes, and the file simply stops
# short of what the world's own count asks for. So it warns like test1, test2
# and test3 rather than erroring like test6, and the file is written out with
# the count the world can honour (test7.3).
#
# Two counts left waiting is test6 again: then a group inside really may hold
# what one of them was owed, and the file does not say which.
################################################################################

@test "test7.1" {
  $RUN_TEST acclint test7.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test7.2" {
  $RUN_TEST acclint -Wno-warnings test7.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.2.output
  fi
  [ "$output" = "" ]
}

@test "test7.3" {
  $RUN_TEST acclint -Wno-warnings test7.ac -o test7.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.output.ac)"
  expected_file="$(tr -d '\r' < test7.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test7.output.ac test7.3.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test7.output.ac
}
