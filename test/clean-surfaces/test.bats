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
    rm -f ./*.output ./*.output.ac
}

################################################################################
# cleanSurfaces: writing an output file deletes the surfaces left with too few
# refs to draw anything. Every surface used to be tested against three, which
# is right for a polygon or a triangle strip but not for a line: a line is
# drawn from two refs, the reader accepts one without complaint, and so every
# 2 ref line was dropped from every file written, with nothing said.
#
# The minimum is now two for an open line and three for the rest: a closed
# line needs three to enclose anything.
################################################################################

# test1: a 2 ref open line beside a triangle. Both have to come through.
@test "test1" {
  $RUN_TEST acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test1.output.ac test1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

# test2: both sides of each minimum. A 1 ref line, a 2 ref closed line and a
# 2 ref polygon go; a 3 ref closed line and the triangle stay.
@test "test2" {
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test2.output.ac test2.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

################################################################################
# A poly with kids is outside the format, but articulated models are built
# that way -- a lever with its knob hung off it, so the knob moves with the
# lever -- and the hierarchy is left as it was read unless --fixPolyWithKids
# is given. The knob is as much a part of the model as the lever, so it gets
# the same treatment as any other object.
################################################################################

# test3: the knob holds a triangle and a 2 ref polygon. The polygon goes, as
# it would from any other object, and the lever keeps the knob.
@test "test3" {
  $RUN_TEST acclint -Wno-warnings test3.ac -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.output.ac test3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.ac
}

################################################################################
# A quad that is not flat is split into two triangles on the way out. Along
# 0-2, unless it is concave: then 0-2 can run outside it, and it is split along
# the diagonal through the reflex corner.
################################################################################

# test4: a dart, with its reflex corner at ref 3 and ref 1 lifted 1 mm. Split
# 1-3, into two triangles with the dart's own area of 1.5, wound the way it is.
# Split 0-2 it came out with 2.5: one triangle covering the notch, wound the
# other way.
@test "test4" {
  $RUN_TEST acclint -Wno-warnings test4.ac -o test4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.output.ac test4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.ac
}

################################################################################
