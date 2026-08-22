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

@test "test1.2" {
  $RUN_TEST acclint -Wno-warnings test1.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.2.output
  fi
  [ "$output" = "" ]
}

@test "test1.3" {
  $RUN_TEST acclint -Wno-warnings -Winvalid-material test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test2.1" {
  $RUN_TEST acclint test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.2" {
  $RUN_TEST acclint -Wno-warnings test2.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.2.output
  fi
  [ "$output" = "" ]
}

@test "test2.3" {
  $RUN_TEST acclint -Wno-warnings -Winvalid-material test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.4" {
  $RUN_TEST acclint --quiet test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.5" {
  $RUN_TEST acclint --summary test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test2.6" {
  $RUN_TEST acclint --quiet --summary test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings -Winvalid-material test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.4" {
  $RUN_TEST acclint --quiet test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.5" {
  $RUN_TEST acclint --summary test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test3.6" {
  $RUN_TEST acclint --quiet --summary test3.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.2" {
  $RUN_TEST acclint -Wno-warnings test4.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$output" = "" ]
}

@test "test4.3" {
  $RUN_TEST acclint -Wno-warnings -Winvalid-material test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.4" {
  $RUN_TEST acclint --quiet test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.5" {
  $RUN_TEST acclint --summary test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test4.6" {
  $RUN_TEST acclint --quiet --summary test4.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test5" {
  $RUN_TEST acclint test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test6" {
  $RUN_TEST acclint test6.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test6.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test6.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test7: MATERIAL line ends (trailing whitespace then EOF) right after rgb,
# with amb/emis/spec/shi/trans entirely absent. Exercises readTypeAndColor's
# EOF handling: this must produce the soft "invalid material: amb" warning,
# not a hard "error: reading amb". NOTE: test7.ac's second line has two
# trailing spaces after "1 1 1" -- they are required to reproduce this and
# must not be stripped by an editor/formatter.
@test "test7" {
  $RUN_TEST acclint test7.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test7.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test7.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test8: same as test7 but for the scalar fields -- MATERIAL line ends
# (trailing whitespace then EOF) right after shi, with trans entirely
# absent. Exercises readTypeAndValue's EOF handling. NOTE: test8.ac's second
# line has two trailing spaces after "shi 10" -- required, do not strip.
@test "test8" {
  $RUN_TEST acclint test8.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test8.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test8.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test9: MAT/ENDMAT format with a bare "rgb" line (token present, no value).
# Must produce only the "invalid material: rgb" warning -- no spurious
# "invalid token: rgb" error. Exercises readColor's EOF-return failbit fix.
@test "test9" {
  $RUN_TEST acclint test9.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test9.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test9.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test10: MAT/ENDMAT format with a bare "shi" line (token present, no
# value). Must produce only the "invalid material: shi" warning -- no
# spurious "invalid token: shi" error. Exercises readValue's EOF-return
# failbit fix.
@test "test10" {
  $RUN_TEST acclint test10.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test10.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test10.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test11: MAT/ENDMAT format with no name at all on the MAT line. Must
# produce "error: reading name" and still parse the rest of the block
# (rgb/amb/emis/spec/shi/trans/ENDMAT) cleanly, with no cascading errors.
# Exercises the missing-name check added to the multi-line readMaterial
# overload.
@test "test11" {
  $RUN_TEST acclint test11.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test11.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test11.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test12: single-line MATERIAL with a stray full number ("5") appearing
# where "shi" is expected. Must produce a soft "invalid material shi: extra
# number" warning (not a hard error), and that warning must be suppressed
# by -Wno-invalid-material. Exercises readTypeAndValue's stod-based
# extra-number handling and its m_invalid_material gating.

@test "test12.1" {
  $RUN_TEST acclint test12.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test12.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test12.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test12.2" {
  $RUN_TEST acclint -Wno-invalid-material test12.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test12.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test12.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
