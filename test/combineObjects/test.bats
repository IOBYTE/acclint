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
    rm -f ./*.output ./*.output.ac ./*.output.acc
}

################################################################################
# Every object is a draw call. A model that has been combined by texture and
# then partitioned into cells ends up with many small objects that say exactly
# the same thing about themselves, and each one costs a call of its own.
#
# --combineObjects merges the ones that sit side by side under the same parent
# and match. Nothing moves in the tree, so whatever grouping put an object
# where it is -- by texture, or by grid cell -- still decides what can be
# rejected before drawing; only the number of objects inside each group falls.
#
# Two objects match when everything the object says about itself is the same:
# the texture set and its mapping, loc and rot, and the rest. Material and
# shading belong to the surface rather than the object, but the set of those
# combinations is part of the test as well, so that a merge never leaves an
# object holding a mix its parts did not already have -- which is what would
# undo --splitMat and --splitSURF.
################################################################################

# test1.1: two objects, same texture, same material, same flags. One object
# out, holding both triangles.
@test "test1.1" {
  $RUN_TEST acclint test1.ac --combineObjects -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

# test1.2: the same file without the option, so test1.1 is pinning what
# --combineObjects did rather than something the writer does anyway.
@test "test1.2" {
  $RUN_TEST acclint test1.ac -o test1.plain.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.plain.output.ac)"
  expected_file="$(tr -d '\r' < test1.plain.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.plain.output.ac
}

################################################################################
# test2, test3, test4: one thing differs each time, so nothing may be merged.
# Each is compared against the same file written WITHOUT the option, which is
# the statement being made: the option changed nothing.
#
#   test2  a different texture
#   test3  a different material -- surface state, but still a state change
#          between the two, so merging them would put a mix in one object
#   test4  a different loc, which places the vertices somewhere else
################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac --combineObjects -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

@test "test3.1" {
  $RUN_TEST acclint test3.ac --combineObjects -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.ac
}

@test "test4.1" {
  $RUN_TEST acclint test4.ac --combineObjects -o test4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  actual_file="$(tr -d '\r' < test4.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.ac
}

################################################################################
# test5: a group sitting between two objects that would otherwise merge. The
# group stays where it is -- merging it would flatten the tree and take its
# children's grouping with it -- and the two objects either side of it merge
# with each other. The two inside the group merge with each other as well, and
# not across it, which is the property that keeps a grid cell able to reject
# what it holds.
################################################################################

@test "test5.1" {
  $RUN_TEST acclint test5.ac --combineObjects -o test5.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

################################################################################

################################################################################
# Two objects that say the same thing can still sit at opposite ends of
# whatever holds them -- two buildings in one grid cell -- and merging those
# gives a single object as wide as the cell, which a camera at either end then
# draws in full. So with --grid a merged object is held within a share of the
# cell size, 25 per cent unless another is given.
#
# The limit is measured across the ground, not in three dimensions: a camera
# standing on a track takes in the whole height at once, so how tall the result
# is says nothing about what it costs to draw.
#
# Without --grid there is no cell to take a share of, and nothing bounds the
# merge -- that is test1, where two objects ninety units apart merge freely.
################################################################################

# test6.1: two objects ninety units apart in a cell of a hundred. The default
# allows twenty five, so they stay apart.
@test "test6.1" {
  $RUN_TEST acclint -Wno-warnings test6.ac --grid 100 --combineObjects -o test6.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test6.output.ac)"
  expected_file="$(tr -d '\r' < test6.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test6.output.ac test6.1.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.ac
}

# test6.2: the same pair with the whole cell allowed. Ninety one units across
# fits inside a hundred, so now they merge -- which is what the default is
# there to prevent.
@test "test6.2" {
  $RUN_TEST acclint -Wno-warnings test6.ac --grid 100 --combineObjects=100 -o test6.merged.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test6.merged.output.ac)"
  expected_file="$(tr -d '\r' < test6.merged.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test6.merged.output.ac test6.2.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test6.merged.output.ac
}

# test6.3: a share of the cell only means something when there is a cell, so
# asking for one without --grid is refused rather than quietly ignored.
@test "test6.3" {
  run acclint -Wno-warnings test6.ac --combineObjects=25 -o test6.bad.output.ac
  [ "$status" -ne 0 ]
  [ "$output" = "--combineObjects percent needs --grid" ]
}

################################################################################
