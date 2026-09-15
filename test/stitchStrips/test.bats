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
# Every surface is something for the renderer to be told about. Two triangle
# strips drawn one after the other can be told as one: repeating the last ref
# of the first and the first ref of the second makes the triangles that span
# the seam degenerate -- three refs with no area between them, which draws
# nothing -- so one surface holds what two used to.
#
# --stitchStrips does that. It costs two refs, or three where the second strip
# would otherwise begin on an odd triangle and come out wound the wrong way
# round, since a strip swaps the first two refs of every odd triangle.
#
# Only strips already next to each other are joined, and only when they say the
# same thing about themselves, so the same triangles are drawn in the same
# order as before. Strips exist only in a .acc, so that is the only place this
# applies -- including the strips made while converting an .ac.
################################################################################

# test1.1: two objects, two strips each. In "even" the first strip has four
# refs, so two are added and the second strip starts at position six. In "odd"
# it has five, and a third ref is added to move the second strip off the odd
# position it would otherwise start on.
@test "test1.1" {
  $RUN_TEST acclint -Wno-warnings test1.acc --stitchStrips -o test1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.acc)"
  expected_file="$(tr -d '\r' < test1.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.output.acc test1.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.acc
}

# test1.2: the same file without the option, so test1.1 is pinning what
# --stitchStrips did rather than something the writer does anyway.
@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.acc -o test1.plain.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.plain.output.acc)"
  expected_file="$(tr -d '\r' < test1.plain.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test1.plain.output.acc test1.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test1.plain.output.acc
}

################################################################################
# test2: two strips that must stay apart. In "separated" a polygon sits between
# them, and joining across it would draw the strips before the polygon instead
# of around it. In "states" the second strip has a different material, so one
# surface could not describe both. The file is compared against itself written
# without the option: nothing changed.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint -Wno-warnings test2.acc --stitchStrips -o test2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.acc)"
  expected_file="$(tr -d '\r' < test2.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test2.output.acc test2.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.acc
}

################################################################################
# test3: an .ac has no strips at all -- they are made while writing the .acc.
# Stitching happens after that, so the strips the conversion just made are
# joined too: two quads, one strip each, one surface out.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint -Wno-warnings test3.ac --stitchStrips -o test3.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.acc)"
  expected_file="$(tr -d '\r' < test3.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.output.acc test3.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.acc
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.ac -o test3.plain.output.acc
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.plain.output.acc)"
  expected_file="$(tr -d '\r' < test3.plain.result.acc)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.plain.output.acc test3.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.plain.output.acc
}

################################################################################
# test4: --noTriangleStrips takes the strips apart, so there would be nothing
# left to join. Asking for both is refused rather than quietly ignored.
################################################################################

@test "test4.1" {
  run acclint -Wno-warnings test1.acc --noTriangleStrips --stitchStrips -o test4.bad.output.acc
  [ "$status" -ne 0 ]
  [ "$output" = "--stitchStrips cannot be used with --noTriangleStrips" ]
}

################################################################################
