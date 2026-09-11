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
# --fixAll turns on flatten, splitPolygon, splitSURF, splitMat,
# fixSurface2SidedOpaque, fixOverlapping2SidedSurface, combineTexture and
# combineObjects, and the order they run in is part of what they do: combining
# by texture after splitting, partitioning after combining, merging after
# partitioning.
#
# Each of those has a suite of its own that says what it does on its own. What
# is pinned here is that they still compose -- that turning one on has not
# quietly undone another. The fixture is built to need several of them: a quad
# to split, an object placed with loc for flatten to resolve, a 2 sided opaque
# surface to convert, and geometry spread far enough apart to land in different
# cells.
################################################################################

@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac --fixAll -o test1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.summary.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.ac test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

# test1.2: the same with a grid, which adds the partitioning and then the
# merge inside each cell. Two cells here, so two objects out rather than one.
@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac --fixAll --grid 50 -o test1.grid.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.grid.summary.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.grid.output.ac)"
  expected_file="$(tr -d '\r' < test1.grid.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.grid.output.ac test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.grid.output.ac
}

################################################################################

################################################################################
# test2: the same model with a transparent texture, which is a different path
# through combineTexture -- opaque geometry sharing a texture is merged there,
# transparent geometry is only gathered under a group so that each piece keeps
# a place of its own in the order it is drawn in.
#
# combineObjects leaves that alone. Transparent geometry is drawn back to
# front so that what is behind shows through, and a merged pair would have one
# place in that order for both halves. So the three objects stay three: with
# the grid, without it, and with the whole cell allowed. What holds them apart
# is transparency rather than the bound, which is why test2.3 says the same
# thing as test2.2 instead of undoing it.
#
# The rest of --fixAll is still visible here: the quad is split, the object
# placed with loc has been resolved, and the group is the one combineTexture
# made.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixAll -o test2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.summary.result)"
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.ac test2.1.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixAll --grid 50 -o test2.grid.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test2.grid.output.ac)"
  expected_file="$(tr -d '\r' < test2.grid.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.grid.output.ac test2.2.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.grid.output.ac
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixAll --grid 50 --combineObjects=100 -o test2.wide.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test2.wide.output.ac)"
  expected_file="$(tr -d '\r' < test2.wide.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.wide.output.ac test2.3.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.wide.output.ac
}

################################################################################
