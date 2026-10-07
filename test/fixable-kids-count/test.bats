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
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wfixable-kids-count test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
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

@test "test1.7" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.ac test1.7.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

@test "test1.8" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.fixed.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.ac test1.8.output
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

################################################################################
# Putting a count right hands whatever followed the object it moves to the
# groups further out, and a reading that leaves them nowhere to go loses them:
# buildObjects stops at the root once the root is full, and whatever is still
# to come is left out of the tree and out of the file, with nothing to say so.
# So a count is only put right if every object still has a place afterwards.
# Both files here lost objects that way, and every object now comes through.
################################################################################

# test9: ___TKMN1_gl1 asks for 4 and takes a, ___TKMN1_gl0 (with b), c and d.
# The names say ___TKMN1_gl0 belongs to TKMN1_g, but reading ___TKMN1_gl1 as 1
# to put it there leaves c and d after it with nowhere to go: TKMN1_g has room
# for one more and the world for none. The names are left aside and the counts
# decide, as they do in a file without track names: ___TKMN1_gl1 keeps a,
# ___TKMN1_gl0 and c, and d goes to TKMN1_g.
@test "test9.1" {
  $RUN_TEST acclint test9.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test9.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test9.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test9.2" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test9.ac -o test9.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test9.output.ac)"
  expected_file="$(tr -d '\r' < test9.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test9.output.ac test9.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test9.output.ac
}

# test10: the world asks for 2 and "track" holds both segment groups. The
# names say a segment group belongs to the world, but reading "track" as 0 to
# put TKMN1_g there leaves TKMN2_g with nowhere to go. The counts decide
# instead: one of the two is a count too many, and the innermost that can
# carry it is "track", so TKMN2_g goes to the world and nothing is lost.
@test "test10.1" {
  $RUN_TEST acclint test10.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test10.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test10.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test10.2" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors --fixKids test10.ac -o test10.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test10.output.ac)"
  expected_file="$(tr -d '\r' < test10.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test10.output.ac test10.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test10.output.ac
}

################################################################################
