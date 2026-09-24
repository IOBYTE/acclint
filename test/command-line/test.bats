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
# Missing required arguments -- getopt_long()/ya_getopt_long() set optopt to
# the option (or, for bundled short options, the specific letter within the
# bundle) that needed a value it didn't get. These tests lock in that each
# short and long option gets its own correct "Missing ..." message instead
# of falling through to a generic/wrong message.
################################################################################

# test1: missing -o argument
@test "test1" {
  $RUN_TEST acclint -o
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing output file" ]
}

# test2: missing -T argument
@test "test2" {
  $RUN_TEST acclint test1.ac -T
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing texture path" ]
}

# test3: missing -j argument
@test "test3" {
  $RUN_TEST acclint test1.ac -j
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing number of threads" ]
}

# test4: missing -v argument
@test "test4" {
  $RUN_TEST acclint test1.ac -v
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing output version" ]
}

# test5: missing -W argument
@test "test5" {
  $RUN_TEST acclint test1.ac -W
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing warning flag" ]
}

# test6: missing --merge argument
@test "test6" {
  $RUN_TEST acclint test1.ac --merge
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing merge file" ]
}

# test7: missing --dump argument
@test "test7" {
  $RUN_TEST acclint test1.ac --dump
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing dump type" ]
}

# test8: missing --removeObjects argument
@test "test8" {
  $RUN_TEST acclint test1.ac --removeObjects
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing removeObjects parameters" ]
}

################################################################################
# Bundled short options: a missing argument on a short option bundled with
# others (e.g. "-lT") must still be correctly identified via optopt, not
# misreported as an unrecognized option.
################################################################################

# test9: missing argument on bundled -lT
@test "test9" {
  $RUN_TEST acclint -lT
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing texture path" ]
}

# test10: missing argument on bundled -lW
@test "test10" {
  $RUN_TEST acclint -lW
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing warning flag" ]
}

################################################################################
# Unknown options: a genuinely unrecognized short option -- including one
# bundled with a valid short option -- must be reported by just its own
# character, not the whole bundle. Unrecognized long options fall back to
# the raw token since they don't set optopt.
################################################################################

# test11: unknown short option
@test "test11" {
  $RUN_TEST acclint -x test1.ac
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Unknown option: -x" ]
}

# test12: unknown short option bundled with a valid one
@test "test12" {
  $RUN_TEST acclint -lx test1.ac
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Unknown option: -x" ]
}

# test13: unknown long option
@test "test13" {
  $RUN_TEST acclint --bogus test1.ac
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Unknown option: --bogus" ]
}

################################################################################
# POSIXLY_CORRECT: getopt_long()/ya_getopt_long() both disable argv
# permutation when this environment variable is set, which would otherwise
# break the documented usage of placing options after the input file (e.g.
# "acclint file.ac --combineTexture -o new.ac"). acclint clears it at
# startup so option/positional ordering is unaffected by the caller's
# environment.
################################################################################

# test14: options after the input file work regardless of POSIXLY_CORRECT
@test "test14" {
  POSIXLY_CORRECT=1 $RUN_TEST acclint test1.ac -Wno-warnings
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

################################################################################
# Sanity: -o with a value still works normally after the case ':' rewrite.
################################################################################

# test15: -o with a value still works
@test "test15" {
  $RUN_TEST acclint test1.ac -Wno-warnings -o test_o.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ -f test_o.output.ac ]
  rm -f test_o.output.ac
}

################################################################################

# Missing required arguments, continued: --grid was the one option that wanted
# a value and had no message of its own, so leaving it off reported it as an
# unknown option instead.
################################################################################

# test16: missing --grid argument
@test "test16" {
  $RUN_TEST acclint test1.ac --grid
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Missing grid size" ]
}

################################################################################

# Values the parser will not take. The tests above cover an option given no
# argument at all; these cover one given an argument it cannot use. --grid and
# -v are already covered that way, by the grid and output-version suites.
################################################################################

# test17: a dump type that is not one of the three
@test "test17" {
  $RUN_TEST acclint test1.ac --dump bogus
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Invalid dump type: bogus" ]
}

# test18: fewer threads than one
@test "test18" {
  $RUN_TEST acclint test1.ac -j 0
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Invalid number of threads: 0" ]
}

# test19: one thread past the 256 the parser allows. test20 pins the other
# side of that boundary, so moving the limit cannot go unnoticed.
@test "test19" {
  $RUN_TEST acclint test1.ac -j 257
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Invalid number of threads: 257" ]
}

# test20: 256 threads is accepted
@test "test20" {
  $RUN_TEST acclint -Wno-warnings -Wno-errors test1.ac -j 256
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

# test21: a thread count that is not a number
@test "test21" {
  $RUN_TEST acclint test1.ac -j abc
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Invalid number of threads: abc" ]
}

# test22: a combine percent of nothing. The value has to be above zero for the
# share of the cell to mean anything.
@test "test22" {
  $RUN_TEST acclint test1.ac --combineObjects=0
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Invalid combine percent: 0" ]
}

# test23: an object type that is not group, poly or light
@test "test23" {
  $RUN_TEST acclint test1.ac --removeObjects bogus x
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Invalid removeObjects type: bogus" ]
}

# test24: a regex that will not compile. What follows the colon is the
# standard library's own wording and differs between implementations, so only
# the part acclint writes is checked.
@test "test24" {
  $RUN_TEST acclint test1.ac --removeObjects poly "["
  [ "$status" -ne 0 ]
  [[ "$(echo "${lines[0]}" | tr -d '\r')" == "Invalid removeObjects expression:"* ]]
}

################################################################################
# Input files: exactly one is required.
################################################################################

# test25: two files named on their own
@test "test25" {
  $RUN_TEST acclint test1.ac test1.ac
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "Multiple input files not supported: test1.ac" ]
}

# test26: none at all, with an option given so that the usage text is not
# printed for an empty command line instead
@test "test26" {
  $RUN_TEST acclint -Wno-warnings
  [ "$status" -ne 0 ]
  [ "$(echo "${lines[0]}" | tr -d '\r')" = "No input file specified" ]
}

################################################################################
# --version prints the version and stops. The number comes from config.h and
# changes with the release, so only the name is checked.
################################################################################

# test27: --version
@test "test27" {
  $RUN_TEST acclint --version
  [ "$status" -eq 0 ]
  [[ "$(echo "${lines[0]}" | tr -d '\r')" == "acclint "* ]]
}

################################################################################
