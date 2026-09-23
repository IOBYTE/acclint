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
# A file whose kids counts ask for more objects than it holds is usually just
# a file that stops short, and the missing kids warning says so. This is the
# other case: a count further out is left waiting while a group nested inside
# it was satisfied, so that inner group holds objects the outer one was owed.
# Which objects, and whose, the counts do not say -- so the tree that was read
# is not the tree the file describes and no count can be put right.
#
# It is an error rather than a warning because writing the file would record
# the tree that was read with the counts corrected to match it, making the
# mistake permanent and leaving nothing to say it happened.
#
# test1.ac: the world takes its one child "a", "a" asks for two, and "b"
# nested inside "a" is satisfied by the poly. The count still waiting is "a",
# which is not the innermost one on the path to the end.
#
# The fixture is short a kids count and so warns about missing kids as well;
# -Wno-warnings keeps these about the error alone.
################################################################################

@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors -Wunfixable-kids-count test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-warnings --quiet test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint -Wno-warnings --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint -Wno-warnings --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# test2: the root is the only count left waiting. Nothing is above it, so
# there is nowhere else its children could have gone and every other count in
# the file was honoured exactly. What was read is the tree the file describes
# and the root simply asks for more than the file goes on to give it, which
# the missing kids warning already says. No error.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
# test3: a file that stops short. Both "a" and "b" are left waiting, but one
# is inside the next on the path to the end, which is what running out of
# input looks like -- nothing was taken from anybody. No error.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings test3.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
}

################################################################################
