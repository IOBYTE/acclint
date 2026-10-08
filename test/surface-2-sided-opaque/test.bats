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
  if [ "$output" != "" ]; then
    echo "$output" > test1.1.output
  fi
  [ "$output" = "" ]
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
  $RUN_TEST acclint -Wno-warnings -Wsurface-2-sided-opaque test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.3.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.4" {
  $RUN_TEST acclint --quiet -Wsurface-2-sided-opaque test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.4.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.5" {
  $RUN_TEST acclint --summary -Wsurface-2-sided-opaque test1.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test1.5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test1.5.output
  fi
  [ "$actual" = "$expected" ]
}

@test "test1.6" {
  $RUN_TEST acclint --quiet --summary -Wsurface-2-sided-opaque test1.ac
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
  if [ "$output" != "" ]; then
    echo "$output" > test2.1.output
  fi
  [ "$output" = "" ]
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
  $RUN_TEST acclint -Wno-warnings -Wsurface-2-sided-opaque test2.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test2.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test2.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test3.1" {
  $RUN_TEST acclint test3.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$output" = "" ]
}

@test "test3.2" {
  $RUN_TEST acclint -Wno-warnings test3.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test3.2.output
  fi
  [ "$output" = "" ]
}

@test "test3.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-2-sided-opaque test3.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################

@test "test4.1" {
  $RUN_TEST acclint test4.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
}

@test "test4.2" {
  $RUN_TEST acclint -Wno-warnings test4.acc
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.2.output
  fi
  [ "$output" = "" ]
}

@test "test4.3" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-2-sided-opaque test4.acc
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test4.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test4.3.output
  fi
  [ "$actual" = "$expected" ]
}

################################################################################
# A texture is transparent if any of its pixels is less than opaque, whatever
# kind of PNG it is. Only 8 bit RGBA used to be read: grey with alpha, a
# palette with a tRNS chunk -- usual for older foliage and fences -- 16 bit
# RGBA, and grey or RGB with tRNS were all taken for opaque, and their 2 sided
# surfaces reported and made single sided.
#
# test5.ac has one 2 sided surface for each texture in textures/. The ones
# named _t have a pixel less than opaque -- rgba16_nearly by one step in 65535
# -- and the ones named _o have none: pal_trns_o has a tRNS chunk, but its
# transparent entry is not used. Only the _o ones are opaque.
################################################################################

@test "test5.1" {
  $RUN_TEST acclint -Wno-warnings -Wsurface-2-sided-opaque test5.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test5.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test5.1.output
  fi
  [ "$actual" = "$expected" ]
}

# test5.2: and --fixSurface2SidedOpaque makes only the opaque ones single sided.
@test "test5.2" {
  $RUN_TEST acclint -Wno-warnings test5.ac --fixSurface2SidedOpaque -o test5.2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test5.2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test5.2.output.ac)"
  expected_file="$(tr -d '\r' < test5.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test5.2.output.ac test5.2.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test5.2.output.ac
}
