#!/usr/bin/env bats

# The 60 second timeout is the point of this suite, not incidental: the bug
# it guards was a spin, not a crash, and a spin produces the right output
# eventually. Only a wall clock bound turns it into a failure. Measured
# headroom is about 100x -- the passing case runs in ~0.6s under valgrind,
# while a regression takes 20+ minutes on the same input.
#
# timeout(1) is GNU coreutils, so it is gated the same way valgrind already
# is in every other suite here. The Windows job still gets the output
# assertions, just without the wall clock bound.
setup() {
    if [[ "$(uname)" == "Linux" ]]; then
        export RUN_TEST="run timeout 60 valgrind --leak-check=full --error-exitcode=1 --quiet"
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
# numvert declares how many vertex lines follow, and the count is taken
# straight from the file with no upper bound. test1.ac declares two billion
# and supplies one, then ends.
#
# The read loop had no exit for running out of input: it kept iterating for
# the rest of the declared count doing nothing, roughly 28 seconds of no-op
# iterations for this seven line file, and reported nothing about the
# truncation. It now stops at end of input and reports the shortfall.
################################################################################

# test1.1: the shortfall is reported, and the run finishes inside the timeout.
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

# test1.2: -Wno-missing-vertex suppresses the message but must NOT bring the
# spin back -- the loop has to stop at end of input whether or not the
# diagnostic is enabled. Without the timeout above this case would pass
# either way, which is precisely why the timeout is here.
@test "test1.2" {
  $RUN_TEST acclint test1.ac -Wno-missing-vertex
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
