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
# An object of a .acc may not hold both polygons and triangle strips. In
# ssggraph a strip surface records only its ref count, in striplist, and
# throws its own arrays away, while a polygon surface leaves its refs in the
# object's index array and takes no place in striplist;
# cgrVtxTable::draw_geometry_array then walks the index array in runs of the
# strip counts, so every strip after the first polygon is drawn through the
# wrong vertices. In osggraph SurfaceBin::isTriangleStrip tests the flags of
# the surface that created the bin and endPrimitive applies that verdict to
# everything in it, so whichever kind came first, the rest are decoded as it.
#
# This is not "different SURF" and does not have the same remedy. A state mix
# means the object is drawn with one surface's sidedness or shading; a type
# mix means it is drawn through the wrong vertices altogether. The object is
# not split for it -- the two surfaces agree about everything an object keeps
# one of -- the types are unified when the file is written instead.
#
# The object below is one polygon and one strip, agreeing about shading,
# sidedness and material. It stays one object, it is reported on the way in,
# and it is written as two strips.
################################################################################

@test "test1.1" {
  $RUN_TEST acclint test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Wmixed-surface-types test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary test1.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

# Writing it unifies the types: one object still, and both surfaces strips.
# Three refs draw the same triangle either way, so nothing about the geometry
# changes.
@test "test1.7" {
  $RUN_TEST acclint -Wno-warnings test1.acc -o test1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.7.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.acc)"
  expected_file="$(tr -d '\r' < test1.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.acc test1.7.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.acc
}

# What was written is no longer a mix, so linting it again says nothing.
@test "test1.8" {
  $RUN_TEST acclint test1.result.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.8.output
  fi
  [ "$output" = "" ]
}

################################################################################
