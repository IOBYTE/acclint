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

# test1: a triangle whose three uv coordinates are all the same point.
# checkSurfaceZeroAreaUV is off by default, so the plain run produces no
# output; explicitly enabling it (either alone or via -Wno-warnings plus
# the individual flag) should report the zero area uv mapping.

@test "test1.1" {
  $RUN_TEST acclint test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wsurface-zero-area-uv test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$output" = "" ]
}

@test "test1.4" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-zero-area-uv test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test2: an ordinary triangle whose uv coordinates form a real (non-zero
# area) mapping. Even with the check explicitly enabled, this must never
# warn.

@test "test2" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-zero-area-uv test2.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
}

################################################################################

# test3: the triangle's 3D vertex positions are already degenerate (a
# repeated vertex, zero real-world area), and its uv coordinates happen to
# be degenerate too. checkSurfaceZeroAreaUV deliberately skips triangles
# that are already degenerate in 3D -- that's the job of the existing
# degenerate-triangle checks -- so this must not additionally report a
# zero area uv mapping.

@test "test3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-zero-area-uv test3.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
}

################################################################################

# test4: the triangle's uv coordinates are three distinct points, but all
# three lie exactly on one line (the middle one sits exactly halfway
# between the other two) -- a real (non-repeated) 3D triangle mapped onto
# a zero-area sliver in uv space. This must warn just like the
# all-coincident case in test1: "distinct points" alone isn't enough to
# have real area.

@test "test4" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-zero-area-uv test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test5: a .acc triangle strip surface (only reachable in non-.ac files,
# since .ac has no triangle strips) with two triangles: the first has a
# real uv mapping, the second's uv coordinates are exactly collinear (the
# third vertex sits exactly on the midpoint of the other two in uv space).
# Only the second triangle should be reported.

@test "test5" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-zero-area-uv test5.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test6: same degenerate-uv triangle as test1, but the surface has no
# texture line at all (object.textures is empty). A zero area uv mapping
# is only meaningful when there's an actual texture being mapped, so this
# must not warn even with the check explicitly enabled.

@test "test6" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-zero-area-uv test6.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.output
  fi
  [ "$output" = "" ]
}

################################################################################
