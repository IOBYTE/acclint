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
