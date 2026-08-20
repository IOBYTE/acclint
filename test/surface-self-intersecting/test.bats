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
    rm -f ./*.output
}

################################################################################

@test "test1.1" {
  $RUN_TEST acclint -Wno-surface-not-convex test1.ac
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
  $RUN_TEST acclint -Wno-warnings -Wsurface-self-intersecting test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test2" {
  $RUN_TEST acclint -Wno-surface-not-convex test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3" {
  $RUN_TEST acclint -Wno-surface-not-convex test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-surface-not-convex test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test5" {
  $RUN_TEST acclint -Wno-surface-not-convex test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: the second-line-segment skip loop re-fetched its
# lookahead point (p4) at the same ref index it had just reassigned to p3,
# instead of one ref past it. That made p3 and p4 spuriously collide on
# the very first skip, forcing an extra, unwarranted skip iteration (and
# therefore an extra, unwarranted shrink of the valid comparison range)
# every time the loop skipped a duplicate/collinear vertex at all. Here a
# duplicate vertex sits on one of the crossing polygon's edges; before the
# fix, that extra shrink pushed the valid range past the pair of segments
# that actually cross, so the intersection went undetected.
@test "test6" {
  $RUN_TEST acclint -Wno-surface-not-convex test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: the first-line-segment bootstrap (run once per outer
# j iteration) walked forward through duplicate/collinear vertices without
# wrapping mod the ref count, unlike every other fetch in this function.
# Before the fix, whenever that walk needed to continue past the physical
# end of refs -- even though wrapping around would immediately land on a
# perfectly valid vertex back at the start of the ref list -- it returned
# early instead, silently abandoning every remaining j iteration,
# including the one that would have found this polygon's actual crossing.
# A duplicate vertex placed early in refs (right after the first segment)
# is what forces that walk to need the wraparound.
@test "test7" {
  $RUN_TEST acclint -Wno-surface-not-convex test7.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
