// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {SegWitUtils} from "../src/SegWitUtils.sol";

import {Test, console2} from "forge-std/Test.sol";

contract SegWitUtilsTest is Test {
    using SegWitUtils for bytes;

    function test_IsWitnessTxOut() public {
        bytes memory pkScript = hex"6a24aa21a9edaf8dcb9588f94a3adb462e80f1306d96ef6ffad72160b33cd5e90045d81e0d77";
        assert(pkScript.isWitnessCommitment());
    }

    function test_ExtractWitnessCommitmentFromTxOut() public {
        bytes memory outputVector = hex"020593cb260000000016001435f6de260c9f3bdee47524c473a6016c0c055cb90000000000000000266a24aa21a9edaf8dcb9588f94a3adb462e80f1306d96ef6ffad72160b33cd5e90045d81e0d77";
        bytes32 witnessCommitment = outputVector.extractWitnessCommitment();
        bytes32 coinbaseWitnessCommitment = hex"af8dcb9588f94a3adb462e80f1306d96ef6ffad72160b33cd5e90045d81e0d77";
        assertEq(coinbaseWitnessCommitment, witnessCommitment);
    }
}
