# beacon_chain
# Copyright (c) 2020-2024 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import std/os except dirExists
import std/strformat
import confutils
import testutils/fuzzing_engines

const
  gitRoot = thisDir() / ".."
  fixturesDir = gitRoot / "vendor" / "nim-eth2-scenarios" / "tests-v1.0.1" / "mainnet" / "phase0" / "ssz_static"

  fuzzingTestsDir = gitRoot / "tests" / "fuzzing"
  fuzzingCorpusesDir = fuzzingTestsDir / "corpus"

cli do (testname {.argument.}: string,
        fuzzer = defaultFuzzingEngine):

  if not dirExists(fixturesDir):
    echo "Please run `make test` first in order to download the consensus spec ETH2 test vectors"
    quit 1

  if not dirExists(fixturesDir / testname):
    echo testname, " is not a recognized SSZ type name (type names are case-sensitive)"
    quit 1

  let corpusDir = fuzzingCorpusesDir / testname

  rmDir corpusDir
  mkDir corpusDir

  var inputIdx = 0
  template nextInputName: string =
    inc inputIdx
    "input" & $inputIdx

  for file in walkDirRec(fixturesDir / testname):
    if splitFile(file).ext == ".ssz":
      # TODO Can we create hard links here?
      cpFile file, corpusDir / nextInputName()

  let testProgram = fuzzingTestsDir / &"ssz_decode_{testname}.nim"
  exec &"""ntu fuzz --fuzzer={fuzzer} --corpus="{corpusDir}" "{testProgram}" """
