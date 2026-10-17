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
  $RUN_TEST acclint test1.ac -Wno-warnings --fixRgbTexture -o test1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test1.output.ac)"
  expected_file="$(tr -d '\r' < test1.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test1.output.ac
}

################################################################################
# The rgb texture warning is given for a texture on any object, and only a
# poly's was renamed: one on a group was warned about and then written out as
# it was.
################################################################################

# test2.1: a group and the poly under it, both on test1.rgb. Both come out on
# test1.png.
@test "test2.1" {
  $RUN_TEST acclint test2.ac -Wno-warnings --fixRgbTexture -o test2.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test2.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test2.output.ac)"
  expected_file="$(tr -d '\r' < test2.result.ac)"
  [ "$actual_file" = "$expected_file" ]
  rm test2.output.ac
}

################################################################################
# A texture is only renamed to a .png that is there, and that lets light
# through where the .rgb texture does. It was renamed whether or not the .png
# existed, and the file written had a missing texture where it had one that
# loaded. A .png that is opaque where the .rgba is not, or the other way,
# draws the surface differently, and everything that sorts by transparency
# would put it with the wrong objects. Either way the texture is left as it
# was and the reason said, once for each texture.
################################################################################

# test3.1: gone.png does not exist; leaf.png has no alpha where leaf.rgba does
# (two objects use it, and it is said once); sign.png has alpha where
# sign.rgb has none. All three keep their rgb textures.
@test "test3.1" {
  $RUN_TEST acclint test3.ac -Wno-warnings --fixRgbTexture -o test3.1.output.ac
  [ "$status" -eq 0 ]
  actual="$(echo "$output" | tr -d '\r')"
  expected="$(tr -d '\r' < test3.result)"
  if [ "$actual" != "$expected" ]; then
    echo "$output" > test3.1.output
  fi
  [ "$actual" = "$expected" ]
  actual_file="$(tr -d '\r' < test3.1.output.ac)"
  expected_file="$(tr -d '\r' < test3.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test3.1.output.ac test3.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test3.1.output.ac
}

# test4.1: bush.rgba and bush.png both have alpha: renamed.
@test "test4.1" {
  $RUN_TEST acclint test4.ac -Wno-warnings --fixRgbTexture -o test4.1.output.ac
  [ "$status" -eq 0 ]
  if [ "$output" != "" ]; then
    echo "$output" > test4.1.output
  fi
  [ "$output" = "" ]
  actual_file="$(tr -d '\r' < test4.1.output.ac)"
  expected_file="$(tr -d '\r' < test4.result.ac)"
  if [ "$actual_file" != "$expected_file" ]; then
    cp test4.1.output.ac test4.1.actual.output
  fi
  [ "$actual_file" = "$expected_file" ]
  rm test4.1.output.ac
}
