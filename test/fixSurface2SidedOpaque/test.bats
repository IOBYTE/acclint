#!/usr/bin/env bats

################################################################################

@test "test1.1" {
  run acclint test1.ac --fixSurface2SidedOpaque -o test1.output.ac
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
  [ "$(cat test1.output.ac)" = "$(cat test1.result.ac)" ]
  rm test1.output.ac
}
