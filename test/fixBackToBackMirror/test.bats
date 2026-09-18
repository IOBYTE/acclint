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

# The two faces of one quad written as two single sided surfaces: same
# positions wound the other way, same uv where they meet. One two sided
# surface says the same thing.
@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac --fixBackToBackMirror -o test1.output.ac
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

################################################################################

# test1 with the back face's uv running the other way, which is how a sign
# is textured to read correctly from both sides. One surface holds one uv
# coordinate per ref, so merging would throw the back face's mapping away:
# the file has to come out unchanged.
@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac --fixBackToBackMirror -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################

# Both halves of the vertex normal question in one file. "same" shares its
# vertices, so there is one normal per position and merging keeps it.
# "opposed" gives each face coincident vertices of its own with opposite
# normals -- which is what a back to back pair in a .acc normally looks like
# -- and one surface cannot hold both sets, so it stays as it is.
@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings test3.acc --fixBackToBackMirror -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.acc)"
  expected_file="$(tr -d '\r' < test3.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.acc
}

################################################################################

# The other two things the one surface left could only say once: "mat" has a
# different material on each face, "shade" has one face smooth and the other
# flat. Neither merges.
@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings test4.ac --fixBackToBackMirror -o test4.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.output.ac
}

################################################################################

# The same mirrored pair split over two objects. Merging would mean taking a
# surface out of an object that has its own matrix, texture and material and
# would be left holding nothing, so this is left alone -- --flatten first is
# what brings such a pair into one object. Note that nothing warns about this
# file by default either: the cross object pair is what overlappingGeometry
# reports, and that is off unless asked for.
@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings test5.ac --fixBackToBackMirror -o test5.output.ac
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

# Each face with coincident vertices of its own and no normals to tell them
# apart, which is the common .ac version of the same mistake. The merge only
# keeps one face's refs, so the other's four vertices are left unused and the
# clean that follows collects them: 8 vertices in, 4 out.
@test "test6.1" {
  $RUN_TEST acclint -Wno-warnings test6.ac --fixBackToBackMirror -o test6.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test6.output.ac)"
  expected_file="$(tr -d '\r' < test6.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.ac
}
