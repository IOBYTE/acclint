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

# Nothing but the counts to go on: "g" asks for 2 and the world is left
# waiting, so the whole surplus comes off "g" -- the innermost count that can
# carry it.
#
# The counting runs whether or not anything is being fixed, so the warning is
# there either way (test1.1). What --fixKids decides is the tree that comes
# out: without it the file is written exactly as it was read, p2 still inside
# "g" (test1.2), and with it p2 belongs to the world (test1.3).
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
  $RUN_TEST acclint -Wno-warnings -Wno-errors test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.ac test1.2.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.fixed.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.ac test1.3.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

################################################################################

# A track segment's levels of detail. ___TKMN369_gl3 asks for 18 and so reads
# its two sibling levels of detail as its own children, which they cannot be:
# every ___TKMN369_* group belongs to TKMN369_g. It holds one object of its
# own when the next level of detail arrives, so that is what its count is.
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
  $RUN_TEST acclint -Wno-warnings -Wfixable-kids-count test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$actual" = "$expected" ]
}

# The tree that comes out: all three levels of detail under TKMN369_g, which
# is the tree the file describes rather than the one its counts produced.
@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################

# A ___TKMN group with no TKMN5 group anywhere above it waiting for children.
# Where it should have gone is then not something the names can say, so the
# counts are left exactly as they are -- and these add up, so nothing is
# reported at all.
@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
}

################################################################################

# ___TKMN1_gl0 is read as a child of the world because TKMN1_g had already
# taken the one child it asked for. Its count being too small is not a
# surplus to take off anything, and nothing says whether the fault is its own
# or ___TKMN1_gl1's, so this is left alone as well.
@test "test4.1" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
}

################################################################################

# Both at once: the names put ___TKMN9_gl1 right, and the surplus that is
# left over after that is one "misc" can account for on the counts alone.
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
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test5.ac -o test5.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

################################################################################

# What a real track file looks like: the level of detail that swallowed its
# siblings holds nothing of its own, so its count is 0 and the empty group is
# then dropped on the way out like any other.
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
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test6.ac -o test6.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test6.output.ac)"
  expected_file="$(tr -d '\r' < test6.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.ac
}

################################################################################

# The other half of the convention: a segment group is a child of the world,
# so "tribune" asking for 4 has taken a segment group and, behind it, the
# scenery that follows. Putting its count right hands all of that back to the
# world, which is then the 3 objects it asked for.
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
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test7.ac -o test7.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.output.ac)"
  expected_file="$(tr -d '\r' < test7.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test7.output.ac
}

################################################################################

# A segment group nested two deep in a file whose counts all add up. The world
# has every child it asked for, so there is no surplus to take off anything
# and nothing is said: only counts that are too large are put right, and a
# file that reconciles is never rearranged on the strength of a name.
@test "test8.1" {
  $RUN_TEST acclint test8.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test8.1.output
  fi
  [ "$output" = "" ]
}

@test "test8.2" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test8.ac -o test8.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test8.output.ac)"
  expected_file="$(tr -d '\r' < test8.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test8.output.ac
}
