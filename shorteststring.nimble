# Package

version       = "0.1.0"
author        = "metagn"
description   = "word size strings"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"

when (NimMajor, NimMinor) >= (1, 4):
  when (compiles do: import nimbleutils):
    import nimbleutils

task docs, "build docs for all modules":
  when declared(buildDocs):
    buildDocs(gitUrl = "https://github.com/metagn/shorteststring")
  else:
    echo "docs task not implemented, need nimbleutils"

task tests, "run tests for multiple backends":
  when declared(runTests):
    runTests(optionCombos = @[
      "",
      "--gc:orc",
      "--gc:orc -d:useMalloc"
    ])
  else:
    echo "tests task not implemented, need nimbleutils"
