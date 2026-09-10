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

################################################################################
