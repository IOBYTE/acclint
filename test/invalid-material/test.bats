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
# with amb/emis/spec/shi/trans entirely absent. Each one must get the soft
# "invalid material: missing <field>" warning, not a hard "error: reading
# amb". Only amb used to be reported, as "invalid material: amb", and the
# rest passed over. NOTE: test7.ac's second line has two trailing spaces
# after "1 1 1" -- they are required to reproduce this and must not be
# stripped by an editor/formatter.
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
# absent: "invalid material: missing trans". NOTE: test8.ac's second line
# has two trailing spaces after "shi 10" -- required, do not strip.
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

# test13: MAT/ENDMAT block truncated by EOF -- the file ends before ENDMAT
# is found. Must produce an "error: missing ENDMAT" pointing at the MAT
# line (with a correct, non-blank caret line). Exercises the multi-line
# readMaterial overload's EOF-before-ENDMAT handling.
@test "test13" {
  $RUN_TEST acclint test13.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test13.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test13.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test14: single-line MATERIAL with a decimal comma in shi and trans
# ("shi 64,5  trans 0,75"). The value is read from the whole word, and the
# ",5" and ",75" left over after the number were ignored without a word:
# trans came out as 0, turning a 75% transparent material opaque. Each must
# now be reported as a missing separator, pointing at the comma, the way
# readColor already reports it for rgb/amb/emis/spec.
@test "test14" {
  $RUN_TEST acclint test14.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test14.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test14.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test15: the same decimal commas in a MAT/ENDMAT block, which reads shi and
# trans through readValue directly rather than through readTypeAndValue.
@test "test15" {
  $RUN_TEST acclint test15.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test15.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test15.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# A word where a keyword or a number was expected: either something in front
# of the keyword, which then follows it, or the keyword misspelt, with the
# numbers following it. Which of the two it was used to be decided by whether
# the word was being reported: with -Winvalid-material the keyword was never
# looked for and taken for the first number, and without it the next word was
# always taken, keyword or not. The same file was written two different ways,
# and only the warning should depend on the flag. Each test here writes the
# file with the warning on (.2) and off (.3), and both must be the same.
################################################################################

# test16: a material name of two words without quotes, "red paint". The name
# is "red", "paint" is reported, and rgb is 1 0.5 0.25 -- it was written as
# rgb 0 1 0.5 with the warning on, with two more warnings that were not true.
@test "test16.1" {
  $RUN_TEST acclint test16.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test16.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test16.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test16.2" {
  $RUN_TEST acclint test16.ac -o test16.2.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test16.2.output.ac)"
  expected_file="$(tr -d '\r' < test16.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test16.2.output.ac test16.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test16.2.output.ac
}

@test "test16.3" {
  $RUN_TEST acclint -Wno-invalid-material test16.ac -o test16.3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test16.3.output.ac)"
  expected_file="$(tr -d '\r' < test16.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test16.3.output.ac test16.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test16.3.output.ac
}

# test17: rgb and shi misspelt as rbg and shu. Each is reported, and the
# numbers after it are read as its value.
@test "test17.1" {
  $RUN_TEST acclint test17.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test17.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test17.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test17.2" {
  $RUN_TEST acclint test17.ac -o test17.2.output.ac
  [ "$status" -eq 0 ]
  actual_file="$(tr -d '\r' < test17.2.output.ac)"
  expected_file="$(tr -d '\r' < test17.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test17.2.output.ac test17.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test17.2.output.ac
}

@test "test17.3" {
  $RUN_TEST acclint -Wno-invalid-material test17.ac -o test17.3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test17.3.output.ac)"
  expected_file="$(tr -d '\r' < test17.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test17.3.output.ac test17.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test17.3.output.ac
}

################################################################################

# test18: a field missing from the middle of a MATERIAL line: "a" has no shi,
# "b" no emis. The keyword found in its place is the next field's, and is
# left for it. It used to be read past like a stray word and the numbers
# after it read into the missing field: a was written shi 1 trans 0, opaque
# where it is half transparent, and b's spec went into emis and its shi and
# trans were lost. The warning only depends on the flag, the file does not:
# test18.2 and test18.3 write the same file.
@test "test18.1" {
  $RUN_TEST acclint test18.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test18.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test18.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test18.2" {
  $RUN_TEST acclint test18.ac -o test18.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test18.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test18.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test18.2.output.ac)"
  expected_file="$(tr -d '\r' < test18.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test18.2.output.ac test18.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test18.2.output.ac
}

@test "test18.3" {
  $RUN_TEST acclint -Wno-invalid-material test18.ac -o test18.3.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test18.3.output.ac)"
  expected_file="$(tr -d '\r' < test18.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test18.3.output.ac test18.3.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test18.3.output.ac
}

################################################################################

# test19: a MATERIAL line that ends after rgb, with nothing after it -- not
# even the trailing spaces of test7. Each field it stops short of is missing,
# and said to be, as the version 12 reader says of a MAT block. It used to be
# passed over without a word.
@test "test19.1" {
  $RUN_TEST acclint test19.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test19.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test19.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test19.2" {
  $RUN_TEST acclint -Wno-invalid-material test19.ac -o test19.2.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test19.2.output.ac)"
  expected_file="$(tr -d '\r' < test19.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test19.2.output.ac test19.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test19.2.output.ac
}

################################################################################

# test20: two version 12 MAT blocks, neither with its ENDMAT. "a" is ended by
# the MAT that starts "b", and "b" by the OBJECT world. Each is reported at
# its own MAT line and the line that ended it is read as what it is. Each
# used to be taken for an invalid token: b's lines were lost, and with them
# the material the second poly uses, and the world was lost after "b" -- with
# -Wno-invalid-token (test20.2), with no word of a missing ENDMAT at all. The
# unused vertex in the second poly is there to show the world is read.
@test "test20.1" {
  $RUN_TEST acclint test20.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test20.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test20.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test20.2" {
  $RUN_TEST acclint -Wno-invalid-token test20.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test20.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test20.2.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

# test21: an unknown line, "shine 5", inside a MAT block. It is reported and
# passed over, and the block goes on: trans is read and ENDMAT ends it. It
# used to end the block there, and trans and ENDMAT were reported as stray
# tokens and trans lost: the file was written with trans 0.
@test "test21.1" {
  $RUN_TEST acclint test21.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test21.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test21.1.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test21.2" {
  $RUN_TEST acclint -Wno-invalid-token test21.ac -o test21.2.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test21.2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test21.2.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test21.2.output.ac)"
  expected_file="$(tr -d '\r' < test21.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test21.2.output.ac test21.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test21.2.output.ac
}

################################################################################
