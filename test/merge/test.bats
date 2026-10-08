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

@test "test1.1" {
  $RUN_TEST acclint test1a.ac --merge test1b.ac -o test1.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

@test "test1.2" {
  $RUN_TEST acclint test1a.ac --merge test1b.ac --merge test1c.ac -o test1.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.2.output.ac)"
  expected_file="$(tr -d '\r' < test1.2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.2.output.ac
}

################################################################################
# A poly with kids is outside the format, but articulated models are built
# that way -- a lever with its knob hung off it, so the knob moves with the
# lever -- and the hierarchy is left as it was read unless --fixPolyWithKids
# is given. The knob is as much a part of the model as the lever, so it gets
# the same treatment as any other object.
################################################################################

# test2: the merged file's lever and knob both use its only material, which
# follows test2a's in the output. Both are renumbered to point at it.
@test "test2" {
  $RUN_TEST acclint test2a.ac --merge test2b.ac -o test2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.ac test2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################
# A merge file is read the way the input file is: with the same -W and
# -Wno- settings, --quiet, -T, --fixKids and -j, and refused the same way when
# it has errors. It used to be read with the defaults whatever was asked for,
# and its errors were counted and then ignored.
################################################################################

# test3: test3b has a ref to vertex 5 of 3, an error, and test3b on its own
# would not be written. Merged, it was, with exit 0. Now nothing is written.
@test "test3" {
  rm -f test3.output.ac
  $RUN_TEST acclint test1a.ac --merge test3b.ac -o test3.output.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.output
  fi
  [ "$actual" = "$expected" ]
  [ ! -e test3.output.ac ]
}

# test4: test4b has an unused vertex, and -Wno-unused-vertex is given. The
# warning was reported for the merge file anyway.
@test "test4" {
  $RUN_TEST acclint -Wno-unused-vertex test1a.ac --merge test4b.ac -o test4.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test4.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.output.ac test4.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.ac
}

################################################################################
# A merge file in the other format is converted as it is merged, straight to
# the format being written: both files go there once each, and nothing goes
# through the other file's format on the way. It used to be taken as it was --
# strips and six-number vertex lines in a .ac, a .ac's objects in a .acc with
# no normals, MAT blocks under an AC3Db header -- and the file written was not
# one either format allows.
################################################################################

# test5: a .acc with a triangle strip, merged into a .ac and written as one.
# The strip is written as triangles and the vertices without normals.
@test "test5" {
  $RUN_TEST acclint -Wno-warnings test5a.ac --merge test5b.acc -o test5.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test5.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.output.ac test5.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.ac
}

# test6: the same two the other way round, written as a .acc. The .ac's
# objects are given normals and the .acc keeps its own.
@test "test6" {
  $RUN_TEST acclint -Wno-warnings test5b.acc --merge test5a.ac -o test6.output.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test6.output.acc)"
  expected_file="$(tr -d '\r' < test6.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test6.output.acc test6.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.acc
}

# test7: a version 12 file, merged into a version 11 one. Its MAT block is
# written as a MATERIAL line.
@test "test7" {
  $RUN_TEST acclint -Wno-warnings test5a.ac --merge test7b.ac -o test7.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test7.output.ac)"
  expected_file="$(tr -d '\r' < test7.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test7.output.ac test7.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test7.output.ac
}

################################################################################
# Every surface is pointed at the material it used and every object is put
# where it was, the merged world's transform folded into its kids'.
################################################################################

# test8: test8b's group "b" has geometry of its own, on blue. Only a poly's
# surfaces were moved past the materials already there, so the group kept
# mat 0 and was drawn red, test8a's material 0.
@test "test8" {
  $RUN_TEST acclint -Wno-warnings test8a.ac --merge test8b.ac -o test8.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test8.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test8.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test8.output.ac)"
  expected_file="$(tr -d '\r' < test8.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test8.output.ac test8.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test8.output.ac
}

# test9: test9b's world is placed 100 along x, and test9a's world 10 along x
# and turned a quarter. The other world was dropped, and its kid moved by
# 100. Its loc and rot are now the other world's and the inverse of this
# one's, so flattened it is where it was in test9b.
@test "test9" {
  $RUN_TEST acclint -Wno-warnings test9a.ac --merge test9b.ac -o test9.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test9.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test9.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test9.output.ac)"
  expected_file="$(tr -d '\r' < test9.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test9.output.ac test9.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test9.output.ac
}

# test10: test10b's surface has no mat line, so it is drawn with test10b's
# material 0. It is given mat 1, which is that material now, rather than left
# to mean test8a's material 0.
@test "test10" {
  $RUN_TEST acclint -Wno-warnings test8a.ac --merge test10b.ac -o test10.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test10.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test10.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test10.output.ac)"
  expected_file="$(tr -d '\r' < test10.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test10.output.ac test10.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test10.output.ac
}

################################################################################
# A merge takes one world from each file. --fixMultipleWorlds joins the two
# worlds of a file that is two concatenated, and it ran after the merge, which
# had already been refused: a file with two worlds could not be merged, as
# the merge file or as the one merged into, whatever was asked. It runs on
# both before they are merged.
################################################################################

# test11: test11b is test8a and a second world concatenated.
@test "test11" {
  $RUN_TEST acclint -Wno-warnings test8a.ac --merge test11b.ac --fixMultipleWorlds -o test11.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test11.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test11.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test11.output.ac)"
  expected_file="$(tr -d '\r' < test11.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test11.output.ac test11.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test11.output.ac
}

# test12: the same file, merged into.
@test "test12" {
  $RUN_TEST acclint -Wno-warnings test11b.ac --merge test8b.ac --fixMultipleWorlds -o test12.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test12.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test12.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test12.output.ac)"
  expected_file="$(tr -d '\r' < test12.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test12.output.ac test12.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test12.output.ac
}

# test13: without --fixMultipleWorlds it is still refused, and it is said
# why. "Couldn't merge" was all there was.
@test "test13" {
  rm -f test13.output.ac
  $RUN_TEST acclint -Wno-warnings test8a.ac --merge test11b.ac -o test13.output.ac
  [ "$status" -eq 1 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test13.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test13.output
  fi
  [ "$actual" = "$expected" ]
  [ ! -e test13.output.ac ]
}

################################################################################
