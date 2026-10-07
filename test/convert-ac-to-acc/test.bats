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
# Converting .ac to .acc gives every vertex a normal, and turns the object
# into triangles on the way -- polygons are fanned, and a normal is worked out
# per vertex from the faces meeting there, honouring the object's crease
# angle.
#
# Those triangles are then strung back together into triangle strips, which is
# what the format is for. Only triangles that would share a SURF line can go
# on one strip: same material, and same shading and sidedness flags. The
# texture never enters into it, being a property of the object rather than of
# a surface, so every triangle in an object already shares it.
#
# A strip of a single triangle is no improvement on the triangle and costs a
# surface-strip-size warning, so it is written as a polygon instead. That is
# why the cubes below come out as six strips of two triangles rather than as
# twelve of anything, and why test5 -- whose two triangles meet at a corner
# rather than along an edge, and so cannot share a strip -- is unchanged by
# any of this.
################################################################################

@test "test1" {
  $RUN_TEST acclint test1.ac -o test1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.acc)"
  expected_file="$(tr -d '\r' < test1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.acc
}

################################################################################

@test "test2" {
  $RUN_TEST acclint test2.ac -o test2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.acc)"
  expected_file="$(tr -d '\r' < test2.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.acc
}

################################################################################

@test "test3" {
  $RUN_TEST acclint test3.ac -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.acc)"
  expected_file="$(tr -d '\r' < test3.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.acc
}

################################################################################

@test "test4" {
  $RUN_TEST acclint -Wno-different-uv test4.ac -o test4.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.acc)"
  expected_file="$(tr -d '\r' < test4.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.acc
}

################################################################################

@test "test5" {
  $RUN_TEST acclint test5.ac -o test5.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.acc)"
  expected_file="$(tr -d '\r' < test5.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.acc
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.ac -o test6.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test6.output.acc)"
  expected_file="$(tr -d '\r' < test6.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.acc
}

################################################################################

@test "test7.1" {
  $RUN_TEST acclint test7.ac -o test7.1.output.acc --noTriangleStrips
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.1.output.acc)"
  expected_file="$(tr -d '\r' < test7.1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test7.1.output.acc
}

@test "test7.2" {
  $RUN_TEST acclint test7.ac -o test7.2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.2.output.acc)"
  expected_file="$(tr -d '\r' < test7.2.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test7.2.output.acc
}

################################################################################
# test8: a fan -- eight triangles round one vertex. A strip crosses from
# triangle to triangle over the edge it just arrived at, and a fan turns the
# same way at every step, so a strip that may only alternate has to stop every
# second triangle: three surfaces for eight triangles.
#
# --stripSwaps repeats a couple of refs to turn the same way twice. The
# repeated refs make triangles with no area between them, which draw nothing,
# and the whole fan becomes one surface for two refs more than the three
# surfaces held between them.
#
# It is not what the writer does by default. Every model already in the wild
# is written without a repeated ref, and a reader that has never been given
# one is not worth surprising, so the strips stay alternating unless asked.
################################################################################

@test "test8.1" {
  $RUN_TEST acclint test8.ac --stripSwaps -o test8.1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test8.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test8.1.output.acc)"
  expected_file="$(tr -d '\r' < test8.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test8.1.output.acc
}

# test8.2: the same fan without the option -- three surfaces, and not a ref
# repeated anywhere.
@test "test8.2" {
  $RUN_TEST acclint test8.ac -o test8.2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test8.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test8.2.output.acc)"
  expected_file="$(tr -d '\r' < test8.plain.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test8.2.output.acc
}

################################################################################

# What gets smoothed with what is settled by the vertex each face names, not
# by where that vertex lies. Both corners below are two smooth faces meeting
# at twenty degrees, well inside the default forty-five degree crease, and the
# geometry of the two is identical. The first reaches its corner through two
# coincident vertices, which is the only way a .ac can ask for an edge the
# crease would round off, and both normals must survive. The second reaches
# its corner through one shared vertex and must come out blended. Matching on
# position instead read straight past the split and blended both.
@test "test9" {
  $RUN_TEST acclint test9.ac -o test9.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test9.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test9.output.acc)"
  expected_file="$(tr -d '\r' < test9.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test9.output.acc test9.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test9.output.acc
}

################################################################################
# Concave polygons. The fan from the first vertex used for a convex polygon
# covers ground outside a concave one, and the conversion had nothing else:
# every concave polygon was dropped, its vertices with it, and an object made
# of nothing else was left unconverted -- a raw polygon with no normals in a
# file that promises them. triangulatePolygon cuts a concave polygon into
# triangles by ear clipping, every one inside it and wound the way it is.
################################################################################

# test10: an 86 ref silhouette, concave all the way round. Being concave is
# the only thing wrong with it, so that is the only warning turned off: any
# other fails the test. It comes out as the 84 triangles an 86 corner polygon
# needs, strung into strips, with every normal facing the way the polygon
# does.
@test "test10" {
  $RUN_TEST acclint -Wno-surface-not-convex test10.ac -o test10.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test10.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test10.output.acc)"
  expected_file="$(tr -d '\r' < test10.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test10.output.acc test10.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test10.output.acc
}

# test11: an L, small enough to check by hand. Written as loose triangles so
# each can be read off: four, none of them reaching across the notch.
@test "test11" {
  $RUN_TEST acclint -Wno-surface-not-convex test11.ac --noTriangleStrips -o test11.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test11.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test11.output.acc)"
  expected_file="$(tr -d '\r' < test11.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test11.output.acc test11.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test11.output.acc
}

################################################################################
# A poly with kids is outside the format, but articulated models are built
# that way -- a lever with its knob hung off it, so the knob moves with the
# lever -- and the hierarchy is left as it was read unless --fixPolyWithKids
# is given. The knob is as much a part of the model as the lever, so it gets
# the same treatment as any other object.
################################################################################

# test12: the knob holds a quad. It is converted like the lever: normals on
# its vertices and its quad as a strip.
@test "test12" {
  $RUN_TEST acclint -Wno-poly-with-kids test12.ac -o test12.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test12.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test12.output.acc)"
  expected_file="$(tr -d '\r' < test12.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test12.output.acc test12.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test12.output.acc
}

################################################################################
