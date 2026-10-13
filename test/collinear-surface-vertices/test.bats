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
  $RUN_TEST acclint -Wno-warnings -Wcollinear-surface-vertices test1.ac
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

@test "test1.7" {
  $RUN_TEST acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.7.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.result.ac)"
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

################################################################################

# test2 also doubles as a regression test for checkSurfaceSelfIntersecting:
# this polygon's 4 vertices are all exactly collinear, so every triple is
# flagged, and checkSurfaceSelfIntersecting's degenerate-vertex skip loops
# used to walk their ref index forward looking for a non-degenerate triple
# that could never exist. Before that walk wrapped mod the ref count, it
# eventually ran off the physical end of refs and returned; once it started
# wrapping (to correctly reach a valid vertex on the far side of a shorter
# duplicate/collinear run in other cases), a fully degenerate polygon like
# this one gave it nothing to ever find, and it spun forever instead of
# returning. If this hangs instead of completing, that loop-bound fix
# regressed.
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
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.result.ac)"
  [ "$actual" = "$expected" ]
  rm test2.output.ac
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
  $RUN_TEST acclint -Wno-warnings test3.ac -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test3.output.ac)"
  expected="$(tr -d '\r' < test3.result.ac)"
  [ "$actual" = "$expected" ]
  rm test3.output.ac
}

################################################################################

@test "test4" {
  $RUN_TEST acclint test4.ac
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
  $RUN_TEST acclint test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test7" {
  $RUN_TEST acclint test7.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test8" {
  $RUN_TEST acclint test8.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test8.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test8.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test9" {
  $RUN_TEST acclint test9.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test9.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test9.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test10" {
  $RUN_TEST acclint test10.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test10.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test10.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test11.1" {
  $RUN_TEST acclint test11.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test11.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test11.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test11.2" {
  $RUN_TEST acclint -Wno-warnings test11.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test11.2.output
  fi
  [ "$output" = "" ]
}

@test "test11.3" {
  $RUN_TEST acclint -Wno-warnings -Wcollinear-surface-vertices test11.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test11.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test11.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test11.4" {
  $RUN_TEST acclint -Wno-warnings test11.ac -o test11.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test11.4.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test11.output.ac)"
  expected="$(tr -d '\r' < test11.result.ac)"
  [ "$actual" = "$expected" ]
  rm test11.output.ac
}

################################################################################

@test "test12.1" {
  $RUN_TEST acclint test12.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test12.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test12.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test12.2" {
  $RUN_TEST acclint -Wno-warnings test12.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test12.2.output
  fi
  [ "$output" = "" ]
}

@test "test12.3" {
  $RUN_TEST acclint -Wno-warnings -Wcollinear-surface-vertices test12.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test12.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test12.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test12.4" {
  $RUN_TEST acclint -Wno-warnings test12.ac -o test12.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test12.4.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test12.output.ac)"
  expected="$(tr -d '\r' < test12.result.ac)"
  [ "$actual" = "$expected" ]
  rm test12.output.ac
}

################################################################################

# Regression test: same underlying issue as test2.1 (checkSurfaceSelfIntersecting's
# degenerate-vertex skip loops looking forever for a non-collinear triple that
# can't exist), but with 8 vertices instead of 4 to exercise later j iterations
# of the outer loop too, not just j=0/j=1.
@test "test13" {
  $RUN_TEST acclint test13.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test13.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test13.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# A corner is measured against the nearest refs either side of it that are
# somewhere else. Measured against whatever ref was next, A B B C asked only
# about A B B and B B C, both of which have two points in one place, and B was
# never found to be in line with A and C.
################################################################################

# test14: a rectangle with a point doubled half way along one side. The
# doubled ref is a duplicate, and the point is in line with the corners either
# side of it. The rectangle is not reported as not convex.
@test "test14" {
  $RUN_TEST acclint test14.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test14.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test14.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# A flagged ref is taken out by the cleanup on the way out, so a run of them
# goes all at once. Each corner of test15's curve -- a 300 m radius in 1 m
# segments, 20 km from the origin -- bends by 1.7 mm, inside the 2.4 mm
# collinear() allows at that distance. Measured against its neighbours each
# one passed on its own, all 49 were taken out together, and the curve was
# written as a straight edge a metre away from where it was.
#
# Each corner is now measured against the last corner kept, and only goes if
# every corner let go since then still lies on the line that replaces them, so
# no ref that is taken out is more than that tolerance from where the edge now
# runs. Every other corner of the curve is kept.
################################################################################

@test "test15" {
  $RUN_TEST acclint -Wno-warnings test15.ac -o test15.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test15.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test15.output.ac)"
  expected="$(tr -d '\r' < test15.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test15.output.ac test15.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test15.output.ac
}

################################################################################
# A collinear ref is a corner its own surface does not need, but another
# surface may. In test16 vertex 3 lies on the edge from 2 to 4 of the first
# surface, and is a corner of both of the others. Taking it out of the first
# one, as the cleanup on the way out did, left it in the middle of that
# surface's edge: a T-junction, which renders as a crack. It is kept, so the
# warning (test16.1) is still true of the file written (test16.2).
#
# The rest are the other side of that. Where the point is collinear in every
# surface it is in, it goes from all of them together, and no edge is left
# with a point in it (test17). A triangle with a point on its long edge has no
# area to fill a crack with: it goes as it did, and keeps no point for anyone
# else (test18). Both of these were already right, and are here so they stay
# right. Vertices at the same place are the same corner whatever their index:
# in test19 the other surfaces use a copy of vertex 3 with its own normal, and
# vertex 3 is kept just the same.
################################################################################

@test "test16.1" {
  $RUN_TEST acclint test16.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test16.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test16.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test16.2" {
  $RUN_TEST acclint -Wno-warnings test16.ac -o test16.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test16.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test16.2.output.ac)"
  expected="$(tr -d '\r' < test16.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test16.2.output.ac test16.2.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test16.2.output.ac
}

@test "test17" {
  $RUN_TEST acclint -Wno-warnings test17.ac -o test17.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test17.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test17.output.ac)"
  expected="$(tr -d '\r' < test17.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test17.output.ac test17.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test17.output.ac
}

@test "test18" {
  $RUN_TEST acclint -Wno-warnings test18.ac -o test18.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test18.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test18.output.ac)"
  expected="$(tr -d '\r' < test18.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test18.output.ac test18.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test18.output.ac
}

@test "test19" {
  $RUN_TEST acclint -Wno-warnings test19.acc -o test19.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test19.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test19.output.acc)"
  expected="$(tr -d '\r' < test19.result.acc)"
  if [ "$actual" != "$expected" ]; then
    cp test19.output.acc test19.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test19.output.acc
}

################################################################################
# A ref in line with the corners either side of it is redundant only if what
# it carries is what the edge between them would give it anyway: its texture
# coordinates, and in a .acc its vertex normal, interpolated along the edge.
# Judged on position alone, such a ref was reported and the clean took it out,
# and the texture or the shading along the edge changed with it.
################################################################################

# test20: a quad with a ref halfway along its top edge whose u is 0.9 where
# the edge gives 0.5. It is not reported (test20.1) and it is written
# (test20.2). It was reported and removed, and the texture was warped.
@test "test20.1" {
  $RUN_TEST acclint -Wno-missing-texture test20.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test20.1.output
  fi
  [ "$output" = "" ]
}

@test "test20.2" {
  $RUN_TEST acclint -Wno-missing-texture test20.ac -o test20.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test20.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test20.2.output.ac)"
  expected_file="$(tr -d '\r' < test20.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test20.2.output.ac test20.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test20.2.output.ac
}

# test20.3: the same ref with u 0.5, which the edge gives it. It is reported
# (test20.3) and removed (test20.4), as before.
@test "test20.3" {
  $RUN_TEST acclint -Wno-missing-texture test20.straight.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test20.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test20.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test20.4" {
  $RUN_TEST acclint -Wno-warnings test20.straight.ac -o test20.4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test20.4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test20.4.output.ac)"
  expected_file="$(tr -d '\r' < test20.4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test20.4.output.ac test20.4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test20.4.output.ac
}

# test21: a .acc quad with a ref halfway along its top edge whose vertex
# normal leans 37 degrees from the others. It is not reported and it is
# written; it was removed, normal and all.
@test "test21.1" {
  $RUN_TEST acclint -Wno-missing-texture test21.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test21.1.output
  fi
  [ "$output" = "" ]
}

@test "test21.2" {
  $RUN_TEST acclint -Wno-missing-texture test21.acc -o test21.2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test21.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test21.2.output.acc)"
  expected_file="$(tr -d '\r' < test21.2.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test21.2.output.acc test21.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test21.2.output.acc
}

# test22: two refs along the top edge, a third and two thirds of the way, with
# u at a third and two thirds. Each is what the edge from the corner before it
# to the corner after it gives it, and both go (test22.1). With the second at
# u 0.2, neither does: the first is not what the edge to the second gives it,
# nor is the second what the edge to the corner gives it (test22.2). Both
# were removed.
@test "test22.1" {
  $RUN_TEST acclint -Wno-warnings test22.ac -o test22.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test22.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test22.1.output.ac)"
  expected_file="$(tr -d '\r' < test22.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test22.1.output.ac test22.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test22.1.output.ac
}

@test "test22.2" {
  $RUN_TEST acclint -Wno-warnings test22.bent.ac -o test22.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test22.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test22.2.output.ac)"
  expected_file="$(tr -d '\r' < test22.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test22.2.output.ac test22.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test22.2.output.ac
}

################################################################################

# (2,1,0) is collinear in object "left", on the middle of its right edge, but
# it is a corner of object "right" beside it. Taken out, it leaves that corner
# in the middle of left's edge, a T-junction that renders as a crack. Only the
# object's own surfaces were asked whether they keep a point as a corner.
@test "test23.1" {
  $RUN_TEST acclint -Wno-warnings test23.ac -o test23.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test23.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test23.output.ac)"
  expected_file="$(tr -d '\r' < test23.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test23.output.ac test23.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test23.output.ac
}

# The same in one object of two materials, split by --splitMat before the
# clean: the neighbour is in an object of its own by then. Plain -o kept the
# point and --splitMat took it out.
@test "test24.1" {
  $RUN_TEST acclint -Wno-warnings test24.ac --splitMat -o test24.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test24.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test24.output.ac)"
  expected_file="$(tr -d '\r' < test24.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test24.output.ac test24.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test24.output.ac
}

################################################################################
