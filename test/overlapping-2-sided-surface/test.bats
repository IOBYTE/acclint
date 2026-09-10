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
  $RUN_TEST acclint -Wno-warnings -Woverlapping-2-sided-surface test1.ac
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

@test "test2" {
  $RUN_TEST acclint test2.ac
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
  $RUN_TEST acclint test3.ac
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
  $RUN_TEST acclint test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
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
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# Regression test: trianglesOverlap() -> AC3D::coplanar() -> Plane::equals()
# used to require the two planes' normals to point in the same direction.
# Two triangles that are genuinely coplanar but listed with opposite vertex
# winding (extremely common between independently-authored objects, and not
# an indicator of anything wrong) produce anti-parallel normals, so
# coplanar() incorrectly reported "not coplanar" and trianglesOverlap()
# bailed out before ever testing for an actual overlap. "back" here is a
# small triangle entirely inside "front", wound in the opposite direction
# and sharing no vertices with it, so this only exercises the coplanarity
# check (not the shared-vertex handling covered by test7/test8).
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

# Regression test: the vendored Moeller coplanar-triangle overlap test only
# checks a single vertex of each triangle (vertex 0) for point-in-triangle
# containment, and deliberately ignores edges that exactly share 1 or 2
# vertices so a shared vertex/edge isn't mistaken for an edge crossing. That
# combination missed a genuine overlap where two triangles share an edge and
# the *other* (non-shared) vertex of one triangle lands inside the other --
# there's no edge crossing to detect, and the vertex that matters isn't
# vertex 0. "back" here shares an edge with "front", and its third vertex
# lies squarely inside "front".
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

# Regression guard: "back" shares an edge with "front" (like test7), but its
# third vertex lies on the opposite side of that edge -- the two triangles
# are simply adjacent (as two triangles splitting a quad would be), not
# overlapping. This must NOT warn; it guards against a fix for test6/test7
# overcorrecting into false positives for ordinary shared-edge adjacency.
@test "test8" {
  $RUN_TEST acclint test8.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test8.output
  fi
  [ "$output" = "" ]
}

################################################################################

################################################################################
# The four below exist for the culling that decides which object and surface
# pairs are worth comparing at all. Culling is invisible when it is right --
# it only ever removes work -- so what these pin is that it does not remove
# an answer. Each was checked against a deliberately broken build, and each
# catches a different one:
#
#   test9   a cull that skips a pair unless BOTH sides are two sided
#   test10  per surface bounds that do not line up with the surfaces
#   test11  a box test that compares without the tolerance
#
# test12 catches none of those. It is here because an object carrying no
# triangles at all reaches the same loops with empty vectors, and that is
# worth a valgrind run rather than an output comparison.
################################################################################

# test9: only one of the pair is two sided. The pair is reportable, so the
# "neither side is two sided" rejection must not fire -- it is an AND, and
# turning it into an OR loses this warning entirely.
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

# test10: the first object owns a second surface 1000 units away, so its own
# box is far too wide to reject the pair and only the per surface boxes can.
# Those are held in a vector indexed in step with the surfaces, and this is
# what notices if the two ever stop lining up: reverse them and the near
# surface gets tested against the far one's box and is thrown away.
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

# test11: the two triangles are 3e-07 apart in z, inside the 4.77e-07 the
# comparison allows at this magnitude, so they overlap and are reported. The
# boxes do not touch in z, though, so a cull that drops the tolerance rejects
# the pair before the triangles are ever compared and the warning disappears.
@test "test11" {
  $RUN_TEST acclint test11.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test11.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test11.output
  fi
  [ "$actual" = "$expected" ]
}

# test12: an object whose only surface is a two point line sits between the
# overlapping pair. It produces no triangles, so it reaches the pair loops
# with an empty triangle list and a default box, and must neither disturb the
# pair either side of it nor read anything it should not. The valgrind run
# the harness wraps this in is the half that matters.
@test "test12" {
  $RUN_TEST acclint test12.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test12.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test12.output
  fi
  [ "$actual" = "$expected" ]
}
