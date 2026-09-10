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
    rm -f ./*.output ./*.output.ac
}

################################################################################
# cleanMaterials: writing an output file drops unused materials and collapses
# duplicates onto their first instance. Every surface must still resolve to
# the material it named in the input.
#
# Each surface's material index is remapped to where its representative --
# itself, or the first instance a duplicate collapsed onto -- lands once the
# unused entries are erased. Shifting by material position instead of by that
# representative index retargets a surface to the wrong material, which
# changes the model's colors with no warning printed.
################################################################################

# test1: the representative sits BEFORE the removed material, so it does not
# move and the index must NOT shift down.
#
#   0 X  used            -> survives at 0
#   1 A  used            -> survives at 1
#   2 B  unused          -> erased
#   3 A2 duplicate of A  -> collapses onto A, so its surface must name 1
#
# Shifting by position decremented the third surface from 1 to 0 and turned
# it from A (green) into X (red).
@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test1.output.ac test1.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

# test2: the representative sits AFTER the removed material, so it does move
# and the index MUST shift down. Guards against "fixing" test1 by simply
# never decrementing.
#
#   0 B  unused          -> erased
#   1 A  used            -> survives at 0
#   2 A2 duplicate of A  -> collapses onto A, so its surface must name 0
@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test2.output.ac test2.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

# The two below reach the same remap through the error paths rather than the
# happy one. Both used to index straight off a surface's material without
# asking whether the index was answerable, which is not caught by reading a
# file -- only by writing one, since the remap only runs on the way out.

# test3: a surface names a material the file never defined. That is reported
# as an error, but -Wno-invalid-material-index suppresses it, which leaves the
# error count at zero and lets the file reach the write path with the bad
# index intact. There is nothing to remap it to, so it has to be left alone.
#
#   0 A  used    -> survives at 0, and the remap table has 2 entries
#   1 B  unused  -> erased
#   surface 2 names mat 7
#
# Reading indexes[7] off the end of that table wrote a fabricated material
# number: the plain build turned "mat 7" into "mat 33", and valgrind reports
# the invalid read.
@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings -Wno-invalid-material-index test3.ac -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test3.output.ac)"
  expected="$(tr -d '\r' < test3.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test3.output.ac test3.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test3.output.ac
}

# test4: a surface with no mat line at all. That is only a warning, so the
# file reaches the write path by the ordinary route with an empty mat list,
# and taking back() of it read a wild address -- a deterministic segfault on
# the plain build, so this one fails everywhere rather than only under
# valgrind. The surface must come out still carrying no mat.
@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings test4.ac -o test4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test4.output.ac)"
  expected="$(tr -d '\r' < test4.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test4.output.ac test4.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test4.output.ac
}

################################################################################
