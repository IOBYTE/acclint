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
# .acc files may hold triangle strips, and acclint writes them: converting a
# .ac produces strips, and a .acc that already had them keeps them.
# --noTriangleStrips asks for the same geometry written as separate triangles
# instead, for a reader that does not handle strips or to compare against a
# file written without them.
#
# It is a property of the file being written, not a conversion, so it applies
# whichever way the .acc was arrived at: a .ac being converted is not stripped
# in the first place, and a .acc that came in with strips has them taken
# apart.
################################################################################

# test1.1: .ac in, .acc out, triangles asked for. Each of the cube's twelve
# triangles gets its own surface.
@test "test1.1" {
  $RUN_TEST acclint test1.ac --noTriangleStrips -o test1.output.acc
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

# test1.2: the same conversion without the option, so test1.1 is pinning what
# --noTriangleStrips did rather than something the converter does anyway. Six
# strips of two triangles against twelve separate triangles.
@test "test1.2" {
  $RUN_TEST acclint test1.ac -o test1.strips.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.strips.output.acc)"
  expected_file="$(tr -d '\r' < test1.strips.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.strips.output.acc
}

################################################################################
# test2: .acc in and .acc out. Nothing is being converted, so the strip in the
# input is taken apart on the way out.
################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.acc --noTriangleStrips -o test2.output.acc
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

@test "test2.2" {
  $RUN_TEST acclint test2.acc -o test2.strips.output.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.strips.output.acc)"
  expected_file="$(tr -d '\r' < test2.strips.result.acc)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.strips.output.acc
}

################################################################################
# test3: two runs concatenated into one surface by degenerate triangles. Once
# the runs are separate triangles there is nothing left for a connector to
# join, so they are not written out -- four triangles from a ten ref surface.
################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.acc --noTriangleStrips -o test3.output.acc
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
# test4: .ac output cannot hold strips whatever is asked for, so the option
# makes no difference to it. Both runs are compared against the same file.
################################################################################

@test "test4.1" {
  $RUN_TEST acclint test2.acc -o test4.output.ac
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

@test "test4.2" {
  $RUN_TEST acclint test2.acc --noTriangleStrips -o test4.noStrips.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.noStrips.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test4.noStrips.output.ac
}

################################################################################
