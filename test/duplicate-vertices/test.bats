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
  $RUN_TEST acclint -Wno-warnings -Wduplicate-vertices test1.ac
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

@test "test1.7" {
  $RUN_TEST acclint -Wno-warnings test1.ac -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.7.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.result.ac)"
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.result.ac)"
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.acc -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
  actual="$(tr -d '\r' < test3.output.acc)"
  expected="$(tr -d '\r' < test3.result.acc)"
  [ "$actual" = "$expected" ]
  rm test3.output.acc
}

################################################################################

# Regression test: three vertices where v0 is within epsilon of v1, and v1 is
# within epsilon of v2, but v0 is NOT within epsilon of v2 (Point3::equals()
# is a fuzzy epsilon comparison, not a true equivalence relation, so this
# chain is possible). checkDuplicateVertices used to skip using a vertex as
# a scan origin once it had itself been marked as someone else's duplicate,
# silently assuming equals() was transitive. That meant v1, having already
# been marked as a duplicate of v0, was never compared against v2, so the
# real v1/v2 duplicate was never reported. Both links of the chain must be
# reported: v1 as a duplicate of v0, and v2 as a duplicate of v1.
@test "test4" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-vertices test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# A .ac has no vertex normals: shading is worked out when the file is read, by
# averaging the faces that meet at a vertex, so splitting a vertex in two is
# the only way to state an edge the crease angle would otherwise smooth away.
# The first pair of coincident vertices is used by two smooth shaded faces that
# meet at about 20 degrees, well inside the default 45 degree crease, so the
# split is the only thing keeping that corner sharp and they are not the same
# vertex. The second pair is used by flat shaded faces, which take their
# normals from their own planes whatever meets them there, so the split does
# nothing and they are.
@test "test5" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-vertices test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# A .acc keeps the normal on the vertex and the texture coordinates on the ref,
# and Speed Dreams keeps one of each per vertex, so two vertices given
# different coordinates are two vertices however alike their records look. The
# first pair is given different coordinates and the second pair the same ones.
@test "test6" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-vertices test6.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# The same object as test5, written as a .acc and still stating no normals. A
# .acc adds normals to a .ac rather than requiring them, so a vertex written
# without one is shaded by the faces that meet at it exactly as a .ac vertex
# is, and the answer here has to be test5's answer: the smooth pair holding
# the twenty degree edge is not one vertex, the flat pair is. Asking the file
# name instead of the vertex got this wrong -- the same object kept its edge
# as a .ac and lost it as a .acc.
@test "test7" {
  $RUN_TEST acclint -Wno-warnings -Wduplicate-vertices test7.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.output
  fi
  [ "$actual" = "$expected" ]
}

# And it is not merged away either, so the edge survives being written.
@test "test7.1" {
  $RUN_TEST acclint -Wno-warnings test7.acc -o test7.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test7.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test7.output.acc)"
  expected_file="$(tr -d '\r' < test7.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test7.output.acc test7.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test7.output.acc
}

################################################################################
