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
# --grid puts the geometry into cells and leaves them side by side under the
# parent, which is a row of equals: a camera that can see none of them still
# asks each cell in turn.
#
# --quadTree orders those same cells instead. Four cells become one group, four
# of those become one group above them, and so on, so that a quarter of the
# model has bounds of its own and one question rejects every cell inside it.
# Nothing is divided differently and no geometry moves -- the cells are the
# cells --grid made, in a different arrangement.
#
# A group holding one thing is not made: it would name the same bounds as the
# thing inside it and reject nothing the thing does not reject itself. So a
# quarter holding a single cell is that cell, and a square whose cells all fall
# in one quarter is that quarter.
################################################################################

# test1.1: four cells at (0,0), (0,1), (1,0) and (3,3) of a grid of ten. The
# square that covers them is four cells across, so the top group is quad_0_0_4.
# Three of the cells fall in its first quarter, which becomes quad_0_0_2 and
# holds them; the fourth is alone in the far quarter, so that quarter is the
# cell itself rather than a group around it.
@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac --grid 10 --quadTree -o test1.output.ac
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

# test1.2: the same file with --grid alone, so test1.1 is pinning what
# --quadTree did rather than something --grid does anyway. Same four cells,
# side by side under the world.
@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac --grid 10 -o test1.flat.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.flat.summary.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.flat.output.ac)"
  expected_file="$(tr -d '\r' < test1.flat.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.flat.output.ac test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.flat.output.ac
}

################################################################################
# test2: everything in one cell. There is nothing to order, so no group is
# added and the summary says only how many cells there are -- a tree of one
# cell would be a group naming that cell's bounds a second time.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac --grid 10 --quadTree -o test2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.summary.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.ac test2.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################
# test3: an order for the cells only means something when there are cells, so
# asking for one without --grid is refused rather than quietly ignored.
################################################################################

@test "test3.1" {
  run acclint -Wno-warnings test1.ac --quadTree -o test3.bad.output.ac
  [ "$status" -ne 0 ]
  [ "$output" = "--quadTree needs --grid" ]
}

################################################################################
