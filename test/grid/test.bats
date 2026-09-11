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

# test4.1: a surface wider than the cell cannot be placed by its centre
# without dragging its cell's bounds out with it, so the count is reported
# rather than partitioning as if the grid had been honoured. The usual causes
# are a triangle strip or a large ground quad.
@test "test4.1" {
  $RUN_TEST acclint -Wno-warnings test4.ac --grid 10 -o test4.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
  rm test4.output.ac
}

# test1.3: and a model with nothing oversized says only how many cells it
# made -- the warning half must not appear when there is nothing to warn of.
@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings test1.ac --grid 10 -o test5.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
  rm test5.output.ac
}

################################################################################
# A surface is placed whole, in the cell holding its centre, so one that runs
# across the grid drags that cell's bounds out with it and the cell stops being
# able to reject anything. A triangle strip is the one kind of surface that can
# be divided without changing what is drawn, so it is: taken apart into its
# triangles, which are grouped by the cell each one's centre falls in and built
# back into a strip per group.
#
# A triangle straddling a boundary still has to go to one side of it, so a
# piece can overhang its cell by up to the width of one triangle. That is why
# the fixture's triangles are two units against a cell of ten -- the proportion
# a real model has, where triangles are metres and cells are hundreds of them.
################################################################################

# test5.1: one strip of twenty four triangles laid across twenty four units,
# so it spans three cells of ten. It comes back as three strips, one per cell,
# of twelve, twelve and six refs -- the same twenty four triangles, and four
# refs more in total, since each cut repeats the edge it was made on.
@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings test5.acc --grid 10 -o test5.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.1.output
  fi
  actual_file="$(tr -d '\r' < test5.output.acc)"
  expected_file="$(tr -d '\r' < test5.1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test5.output.acc
}

# test5.2: and the point of doing it -- a strip wider than a cell is what the
# oversized warning was reporting, so once it is divided there is nothing left
# to report and the message is the plain cell count.
@test "test5.2" {
  $RUN_TEST acclint -Wno-warnings test5.acc --grid 10 -o test5.2.output.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.2.output
  fi
  [ "$actual" = "$expected" ]
  rm test5.2.output.acc
}

# test6.1: the same strip scaled to sit inside a single cell. There is nothing
# to divide, so the surface is left exactly as it was -- one strip of twenty
# six refs -- rather than being taken apart and rebuilt for nothing. Only the
# grouping the grid does anyway is applied.
@test "test6.1" {
  $RUN_TEST acclint -Wno-warnings test6.acc --grid 10 -o test6.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test6.1.output
  fi
  actual_file="$(tr -d '\r' < test6.output.acc)"
  expected_file="$(tr -d '\r' < test6.1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test6.output.acc
}

################################################################################
