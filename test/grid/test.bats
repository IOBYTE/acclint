#!/usr/bin/env bats

setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run valgrind --leak-check=full --error-exitcode=1 --quiet"
    else
        export RUN_TEST="run"
    fi
}

setup_file() {
    rm -f ./*.output ./*.output.ac
}

################################################################################
# --grid regroups the hierarchy by where geometry sits rather than by what it
# is made of. combineTexture leaves objects grouped by texture, which is what
# the drawing wants and the opposite of what culling wants: the merged objects
# each span the whole model, so none of them can ever be rejected.
#
# A surface goes to the cell its centre lies in and is never divided, so the
# surface count cannot change -- only which object each one lives in, and
# which vertices that object has to carry.
#
# The grid is laid over the two widest axes. These fixtures are flat in y, so
# the cells are x by z and are named in that order.
################################################################################

# test1.1: one object with four triangles, 20 units apart, split by a 10 unit
# grid into four cells. Each cell keeps only the vertices its own triangle
# uses -- 12 vertices in, 3 per cell out.
@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.ac --grid 10 -o test1.output.ac
  [ "$status" -eq 0 ]
  actual="$(tr -d '\r' < test1.output.ac)"
  expected="$(tr -d '\r' < test1.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test1.output.ac test1.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test1.output.ac
}

# test1.2: the same file with a grid larger than the model. Everything lands
# in one cell, so the geometry must come back whole, wrapped in a single
# group -- an off by one in the cell arithmetic shows up here as a split.
@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac --grid 1000 -o test3.output.ac
  [ "$status" -eq 0 ]
  actual="$(tr -d '\r' < test3.output.ac)"
  expected="$(tr -d '\r' < test3.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test3.output.ac test1.2.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test3.output.ac
}

# test2.1: two objects that each already fit in one cell. Nothing is split;
# they are moved under the cell they belong to. This is the transparent side
# of a combineTexture model, where the objects are already small and only the
# grouping is missing.
@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.ac --grid 10 -o test2.output.ac
  [ "$status" -eq 0 ]
  actual="$(tr -d '\r' < test2.output.ac)"
  expected="$(tr -d '\r' < test2.1.result.ac)"
  if [ "$actual" != "$expected" ]; then
    cp test2.output.ac test2.1.actual.output
  fi
  [ "$actual" = "$expected" ]
  rm test2.output.ac
}

# test3.1: a grid size that is not a positive number is rejected rather than
# quietly ignored, because ignoring it would write an unpartitioned model
# under a name that says otherwise.
@test "test3.1" {
  run acclint -Wno-warnings test1.ac --grid 0 -o test4.output.ac
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "Invalid grid size: 0" ]
  run acclint -Wno-warnings test1.ac --grid abc -o test4.output.ac
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "Invalid grid size: abc" ]
  run acclint -Wno-warnings test1.ac --grid -5 -o test4.output.ac
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "Invalid grid size: -5" ]
}
