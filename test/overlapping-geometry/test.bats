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

# Two one sided objects laid over a third. Nothing reports this unless the
# check is asked for, which is what test1.1 pins down.
@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Woverlapping-geometry test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Woverlapping-geometry test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet --summary -Woverlapping-geometry test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Two surfaces of one object overlapping each other. checkOverlapping2SidedSurface
# only ever compares surfaces of two different objects, and duplicateSurfaces
# and duplicateTriangles only match surfaces describing the same triangle, so
# a partial overlap inside one object is reported by this check alone.
@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Woverlapping-geometry test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test1.ac with both sides two sided. Enabling this check must not report
# what overlapping-2-sided-surface already reported, so test3.1 and test3.2
# expect the same output, and turning that check off hands the same pair to
# this one instead of losing it (test3.3).
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
  $RUN_TEST acclint -Woverlapping-geometry test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-overlapping-2-sided-surface -Woverlapping-geometry test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test2.ac with both surfaces two sided: still silent by default, because
# overlapping-2-sided-surface never looks inside a single object, so there is
# nothing for this check to defer to here.
@test "test4.1" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
}

@test "test4.2" {
  $RUN_TEST acclint -Woverlapping-geometry test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# What the check does not report: "upper" and "lower" are coplanar but only
# share an edge, and "through" passes through "lower" without being coplanar
# with it. trianglesOverlap only reports coplanar geometry, so penetrating
# geometry stays unreported -- moving "through" into the z = 0 plane is what
# makes it a warning.
@test "test5" {
  $RUN_TEST acclint -Woverlapping-geometry test5.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.output
  fi
  [ "$output" = "" ]
}

################################################################################

# The overlapping triangle here is the 3rd triangle of a 5-ref triangle-strip
# surface, not its 1st, so the notes have to name that triangle's refs rather
# than the surface's first three.
@test "test6.1" {
  $RUN_TEST acclint test6.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$output" = "" ]
}

@test "test6.2" {
  $RUN_TEST acclint -Woverlapping-geometry test6.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# The same triangle wound both ways: one surface faces away from the other
# rather than competing with it for the same pixels, which is how a one sided
# wall is given a second face. Covering the same area as well as facing the
# other way is what makes this a mirror rather than a partial overlap
# (test8), and test1/test6 are the same-facing pair of those two cases.
@test "test7.1" {
  $RUN_TEST acclint test7.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.1.output
  fi
  [ "$output" = "" ]
}

@test "test7.2" {
  $RUN_TEST acclint -Woverlapping-geometry test7.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Back to back like test7, but the smaller triangle only covers part of the
# larger one, so the two are not a mirrored pair of the same surface -- which
# is the distinction between reporting "back to back mirror" and plain "back
# to back".
@test "test8.1" {
  $RUN_TEST acclint test8.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test8.1.output
  fi
  [ "$output" = "" ]
}

@test "test8.2" {
  $RUN_TEST acclint -Woverlapping-geometry test8.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test8.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test8.2.output
  fi
  [ "$actual" = "$expected" ]
}
