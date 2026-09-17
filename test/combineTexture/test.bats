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
# --combineTexture gathers every poly that shares a texture into one object,
# then rebuilds the world as an OPAQUE group and a TRANSPARENT group.
#
# It reorganises the world in place through m_objects[0], which assumes there
# is a world to reorganise. A file with no OBJECT parses with no errors at
# all, so nothing stops it reaching this transform through -o.
################################################################################

# test1.1: the ordinary case. p0 and p2 share red.png and merge into one
# object of 6 vertices; p1 keeps blue.png and stays at 3.
@test "test1.1" {
  $RUN_TEST acclint test1.1.ac -T textures --combineTexture -o test1.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.1.output.ac)"
  expected_file="$(tr -d '\r' < test1.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.1.output.ac test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.1.output.ac
}

# test1.2: materials but no OBJECT. Indexing m_objects[0] on the empty
# object list read past the end of the vector.
@test "test1.2" {
  $RUN_TEST acclint test1.2.ac --combineTexture -Wno-unused-material -o test1.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.2.output.ac)"
  expected_file="$(tr -d '\r' < test1.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.2.output.ac test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.2.output.ac
}

# test1.3: nothing but the header. Same empty object list, reached by a
# different route, and the smallest input that can get here.
@test "test1.3" {
  $RUN_TEST acclint test1.3.ac --combineTexture -o test1.3.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test1.3.output.ac)"
  expected_file="$(tr -d '\r' < test1.3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.3.output.ac test1.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.3.output.ac
}

################################################################################

# Sharing a texture is not on its own a reason to become one object. Merging
# puts every surface of one object into another, and an object's surfaces are
# expected to agree about their state: the .acc loader takes an object's state
# from what its surfaces say, and --splitSURF and --splitMat exist to give each
# state an object of its own. Combining on the texture name alone put those
# states back together again, and acclint went on to warn about the result.
################################################################################

# test2.1: three polys on red.png, the middle one two sided. Merging all three
# would make one object holding both 0x10 and 0x30 -- what --splitSURF undoes.
# p0 and p2 agree and become one object; p1 stays as it is.
@test "test2.1" {
  $RUN_TEST acclint test2.1.ac -T textures --combineTexture -o test2.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.1.output.ac)"
  expected_file="$(tr -d '\r' < test2.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.1.output.ac test2.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.1.output.ac
}

# test2.2: the same three polys, agreeing about SURF and differing in material.
# A material is state as much as the flags are, and is kept apart the same way.
@test "test2.2" {
  $RUN_TEST acclint test2.2.ac -T textures --combineTexture -o test2.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test2.2.output.ac)"
  expected_file="$(tr -d '\r' < test2.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.2.output.ac test2.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.2.output.ac
}

################################################################################
# Speed Dreams' .acc loader keeps the group tree only when some object name
# contains "__TKMN" (do_name in grloadac.cpp); without it grssgLoadAC3D flattens
# and re-stripifies the whole model, which costs every group bounding volume and
# so all culling, and throws away the strips written here. combineTexture
# replaces the groups the track arrived with, so the groups it writes carry the
# marker -- but only into a .acc, the only format whose loader reads it.
################################################################################

# test3.1: the test1.1 model written as a .acc. The groups are named for what
# they are, behind the marker the loader looks for.
@test "test3.1" {
  $RUN_TEST acclint test3.1.ac -T textures --combineTexture -o test3.1.output.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test3.1.output.acc)"
  expected_file="$(tr -d '\r' < test3.1.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.1.output.acc test3.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.1.output.acc
}

################################################################################

# An object's kids are objects in their own right and have to be treated as
# such: an object about to be put in a group or merged into another one takes
# no kids along, addObject copying vertices and surfaces and nothing else, so
# kids left attached to a merged object went out with it. flatten() bakes
# transforms but does not collapse the hierarchy, so a tree still arrives here
# whatever else has run.
################################################################################

# test4.1: p1 sits under a group beside p2 and merges into p0, which is outside
# that group and has the same texture and the same surface state. p2 is on
# blue.png and has to come through the walk on its own and be hoisted into
# OPAQUE as the texture group it is.
@test "test4.1" {
  $RUN_TEST acclint test4.1.ac -T textures --combineTexture -o test4.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test4.1.output.ac)"
  expected_file="$(tr -d '\r' < test4.1.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.1.output.ac test4.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.1.output.ac
}

################################################################################
# An object is see-through when its material's trans says so, not only when its
# texture has an alpha channel, and it is the seeing through that makes the
# order it is drawn in matter. Testing the texture alone sent this geometry to
# OPAQUE and merged it, which is what combineObjects is forbidden to do for
# exactly the same reason.
################################################################################

# test4.2: three polys on one opaque texture, the outer two on a material with
# trans 0.5. They go to TRANSPARENT, grouped together but each still its own
# object; only the opaque one is left in OPAQUE.
@test "test4.2" {
  $RUN_TEST acclint test4.2.ac -T textures --combineTexture -o test4.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test4.2.output.ac)"
  expected_file="$(tr -d '\r' < test4.2.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.2.output.ac test4.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.2.output.ac
}

################################################################################

# Texture coordinates live on the ref, so one vertex can be used with several
# sets of them -- and Speed Dreams' .acc loader does not keep them there. For
# an object of triangle strips it stores one pair per vertex (t0tab[vtx], in
# grloadac.cpp's do_refs) and the last ref to name a vertex decides. So two
# vertices used with different coordinates have to stay two vertices while a
# .acc is being written, however alike they otherwise are.
#
# Nothing that builds a track does this. Merging is what creates it: two
# objects that met along an edge each had their own vertex there, and once they
# are one object those vertices look like duplicates for cleanVertices to
# remove. 72 of them on alicante after combineTexture, on a file that arrived
# with none.
################################################################################

# test5.1: a and b meet at one corner and disagree about its uv. They merge
# into one object, and the corner stays two vertices -- six, not five. In a .ac
# it would merge, because there the coordinates stay on the ref.
@test "test5.1" {
  $RUN_TEST acclint test5.1.acc -T textures --combineTexture -o test5.1.output.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test5.1.output.acc)"
  expected_file="$(tr -d '\r' < test5.1.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.1.output.acc test5.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.1.output.acc
}

################################################################################
