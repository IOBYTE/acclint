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
  $RUN_TEST acclint -Wno-warnings -Wsurface-not-convex test1.ac
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

# Regression test: test3.ac is the same "arrowhead" pentagon as test1.ac
# (one genuine concave vertex, physical point (1,1,0)), just listed in the
# surface's refs starting two positions later. checkSurfacePolygonType()
# used to always measure its reference turn direction using whichever
# vertex happened to be second in the refs list, with no guarantee that
# vertex was actually convex; with this particular rotation that reference
# vertex WAS the polygon's one concave point, so every genuinely convex
# vertex compared unequal to it and got misreported as concave (and the
# real concave vertex was never flagged). The fix anchors the reference
# turn at the vertex with the lowest y (ties broken by lowest x), which is
# always a convex hull vertex regardless of how the refs happen to be
# rotated. If this reports the wrong vertex (anything other than the
# physical point (1,1,0), i.e. ref value "3 0 0") as concave, that fix
# regressed.

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
# Whether a corner turns is decided at the size of the model, not of a metre.
# collinear() used to floor its threshold at 1.0, which below a metre made it
# an absolute test of an area, so at millimetre scale every real corner passed
# as straight and was never measured. And a point doubled to within rounding
# is one point, as the duplicate check has it, not a corner of its own.
################################################################################

# test4: an arrowhead 1 mm long. Its notch is a reflex corner, so it is not
# convex -- and none of its corners are in line with their neighbours.
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

# test5: the same arrowhead at a metre, with the point of the notch doubled
# 1e-7 away. The doubled point is reported, and the notch is still concave.
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
# Polygons that are not quite flat are looked at too, projected onto their
# plane. Only coplanar ones were, so a concave polygon with any noise in it was
# never flagged concave, and everything that splits a polygon trusts the flag.
################################################################################

# test6: an L with one corner lifted 1 mm. Reported as not coplanar and as not
# convex, at the corner of the notch.
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
