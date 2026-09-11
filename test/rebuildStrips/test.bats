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
# --rebuildStrips takes each triangle strip apart and builds strips again out
# of the triangles that were in it. It is here so that makeTriangleStrips() --
# the inverse of getTriangleStrip() -- is reachable and can be tested, since
# splitting a strip is the same operation with some of the triangles dropped
# in between.
#
# What identifies a position in a strip is the whole ref and not just the
# vertex index it names, because a strip holds one ref per position: two
# triangles using the same vertex with different texture coordinates cannot
# share it.
################################################################################

# test1: a strip that is already one run of triangles. Rebuilding it can only
# produce the same strip, and the surface is left alone rather than rewritten,
# so the file comes back unchanged.
@test "test1.1" {
  $RUN_TEST acclint test1.acc --rebuildStrips -o test1.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.acc)"
  expected_file="$(tr -d '\r' < test1.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.acc
}

################################################################################
# test2: two runs concatenated into one surface by degenerate triangles, which
# is how a generator packs several strips into one SURF. They carry no area
# and draw nothing, so they are not carried over and the surface comes back as
# the two runs that were really in it -- 10 refs of which 2 were connectors,
# against 8 refs over two surfaces.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.acc --rebuildStrips -o test2.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.acc)"
  expected_file="$(tr -d '\r' < test2.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.acc
}

# test2.2: the same file written without the option, so that test2.1 is
# pinning what --rebuildStrips did rather than something the writer does
# anyway.
@test "test2.2" {
  $RUN_TEST acclint test2.acc -o test2.plain.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.plain.output.acc)"
  expected_file="$(tr -d '\r' < test2.plain.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.plain.output.acc
}

################################################################################
# test3: .ac has no triangle strips -- every surface is a polygon -- so there
# is nothing for the option to do and the file is passed through.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac --rebuildStrips -o test3.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test3.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test3.output.ac
}

################################################################################
