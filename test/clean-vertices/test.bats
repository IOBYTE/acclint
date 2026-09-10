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
    rm -f ./*.output ./*.output.acc ./*.output.ac
}

################################################################################
# cleanVertices: writing an output file collapses duplicate vertices onto one
# survivor. Two vertices at the same position are only the same vertex if
# they also agree about their normal, and .acc carries a normal per vertex.
#
# The comparison used to look at the normal of the first vertex only, which
# made the answer depend on which of the two came first in the file:
#
#   first has no normal  -> the test was skipped and they merged, so the
#                           second one's normal was silently thrown away
#   first has a normal   -> it was compared against the second one's default
#                           constructed {0,0,0} and they did not merge
#
# So the same geometry written out in a different order produced a different
# number of vertices. test1 and test2 are that pair: identical models, the
# two vertices swapped, and they must now agree.
################################################################################

# test1: the vertex WITHOUT the normal comes first. This is the case the old
# comparison merged, dropping a normal that no diagnostic ever mentioned.
@test "test1" {
  $RUN_TEST acclint -Wno-warnings test1.acc -o test1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.acc)"
  expected="$(tr -d '\r' < test1.result.acc)"
  if [ "$actual" != "$expected" ]; then
    cp test1.output.acc test1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test1.output.acc
}

# test2: the same two vertices the other way round. It passed before the fix
# as well -- that is the point. It is here so that test1 cannot be satisfied
# by making the merge order dependent in the opposite direction.
@test "test2" {
  $RUN_TEST acclint -Wno-warnings test2.acc -o test2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.acc)"
  expected="$(tr -d '\r' < test2.result.acc)"
  if [ "$actual" != "$expected" ]; then
    cp test2.output.acc test2.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test2.output.acc
}

# test3: both carry a normal and the normals differ. Same position, but they
# are not the same vertex and must not be merged -- merging would pick one
# normal arbitrarily and change the shading.
@test "test3" {
  $RUN_TEST acclint -Wno-warnings test3.acc -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test3.output.acc)"
  expected="$(tr -d '\r' < test3.result.acc)"
  if [ "$actual" != "$expected" ]; then
    cp test3.output.acc test3.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test3.output.acc
}

# test4: both carry the same normal, so they ARE the same vertex and must
# still merge -- 5 vertices in, 4 out. Guards against satisfying the three
# above by simply never merging anything that has a normal.
@test "test4" {
  $RUN_TEST acclint -Wno-warnings test4.acc -o test4.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test4.output.acc)"
  expected="$(tr -d '\r' < test4.result.acc)"
  if [ "$actual" != "$expected" ]; then
    cp test4.output.acc test4.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test4.output.acc
}

################################################################################
# Positions are compared with a tolerance, and tolerance equality is not
# transitive: 0, 3e-07 and 6e-07 against a threshold of 4.77e-07 give a == b
# and b == c but a != c. Deciding duplicates by walking pairs therefore takes
# the transitive closure of a relation that is not one.
#
# The three fixtures below share one shape -- three near-coincident vertices,
# each anchoring its own triangle so that merging cannot make a surface
# degenerate or make two surfaces identical -- and the three ways of getting
# this wrong each land on a different vertex count:
#
#   9   compares exactly, so nothing near-coincident merges at all
#   8   correct: {0, 3e-07} merge, 6e-07 is too far from the survivor
#   7   chains, collapsing all three onto a vertex that was never equal to
#       the third one
#
# So one output comparison separates all three.
################################################################################

# test5.1: the forward case. 8 vertices out, and the survivors must be the
# ends of the chain that are NOT within tolerance of each other.
@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings test5.ac -o test5.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test5.output.ac)"
  expected="$(tr -d '\r' < test5.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test5.output.ac test5.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test5.output.ac
}

# test5.2: the invariant that makes the grouping worth having -- a file that
# has been cleaned must lint clean. test5.ac reports two duplicate vertex
# warnings; whatever survives -o must report none, which is only true if
# every surviving pair is more than a tolerance apart. Merging by pairs left
# a warned-about pair in the output.
@test "test5.2" {
  acclint -Wno-warnings test5.ac -o test5.2.output.ac
  $RUN_TEST acclint test5.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.2.output
  fi
  [ "$output" = "" ]
  rm test5.2.output.ac
}

# test6.1: the same three vertices written in the opposite order. Which
# vertices survive is a property of the geometry, so it must not change --
# chaining picked whichever end of the chain the file happened to start from.
@test "test6.1" {
  $RUN_TEST acclint -Wno-warnings test6.ac -o test6.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test6.output.ac)"
  expected="$(tr -d '\r' < test6.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test6.output.ac test6.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test6.output.ac
}

################################################################################
