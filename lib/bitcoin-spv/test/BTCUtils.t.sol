// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {BTCUtilsScript} from "../script/BTCUtils.s.sol";

contract BTCUtilsTest is Test {
    BTCUtilsScript public instance;

    function setUp() public {
        instance = new BTCUtilsScript();
    }

    function test_GetLastBytes() public {
        bytes memory res = instance.lastBytes(hex"00112233", 2);
        assertEq(res, hex"2233");
    }

    function test_RevertIfSliceIsLargerThanTheByteArray() public {
        vm.expectRevert("Underflow during subtraction.");
        instance.lastBytes(hex"00", 2);
    }

    struct ReverseEndiannessTest {
        bytes input;
        bytes output;
    }

    function test_ReversesEndianness() public {
        ReverseEndiannessTest[2] memory testCases = [
            ReverseEndiannessTest({
                input: hex"00112233",
                output: hex"33221100"
            }),
            ReverseEndiannessTest({
                input: hex"0123456789abcdef",
                output: hex"efcdab8967452301"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes memory res = instance.reverseEndianness(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct BytesToUintTest {
        bytes input;
        uint output;
    }

    function test_ConvertsBigEndianBytesToIntegers() public {
        BytesToUintTest[6] memory testCases = [
            BytesToUintTest({
                input: hex"00",
                output: 0
            }),
            BytesToUintTest({
                input: hex"ff",
                output: 255
            }),
            BytesToUintTest({
                input: hex"ff00",
                output: 65280
            }),
            BytesToUintTest({
                input: hex"01",
                output: 1
            }),
            BytesToUintTest({
                input: hex"0001",
                output: 1
            }),
            BytesToUintTest({
                input: hex"0100",
                output: 256
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            uint res = instance.bytesToUint(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    function test_ImplementsBitcoinsHash160() public {
        bytes memory input = hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes memory output = hex"1b60c31dba9403c74d81af255f0c300bfed5faa3";

        bytes memory res1 = instance.hash160(input);
        assertEq(res1, output);

        bytes20 res2 = instance.hash160View(input);
        assertEq(res2, bytes20(output));
    }

    struct Hash256Test {
        bytes input;
        bytes32 output;
    }

    function test_ImplementsBitcoinsHash256() public {
        Hash256Test[2] memory testCases = [
            Hash256Test({
                input: hex"00",
                output: hex"1406e05881e299367766d313e26c05564ec91bf721d31726bd6e46e60689539a"
            }),
            Hash256Test({
                input: hex"616263",
                output: hex"4f8b42c22dd3729b519ba6f68d2da7cc5b2d606d05daed5ad5128cc03e6c6358"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes32 res1 = instance.hash256(testCases[i].input);
            assertEq(res1, testCases[i].output);

            bytes32 res2 = instance.hash256View(testCases[i].input);
            assertEq(res2, testCases[i].output);
        }
    }

    struct Hash256MerkleStepTest {
        bytes inputLeft;
        bytes inputRight;
        bytes32 output;
    }

    function test_ImplementsHash256MerkleStep() public {
        Hash256MerkleStepTest[2] memory testCases = [
            Hash256MerkleStepTest({
                inputLeft: hex"00",
                inputRight: hex"00",
                output: hex"407feb4a4b8303baf4f84e29a209e0dcfd62e81f88c8edb7675c5a95d90e5c90"
            }),
            Hash256MerkleStepTest({
                inputLeft: hex"00",
                inputRight: hex"ff",
                output: hex"63e16be7c46701e1275e7e5c79732685b824520343c51a86a7bb48a044878823"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes32 res = instance._hash256MerkleStep(testCases[i].inputLeft, testCases[i].inputRight);
            assertEq(res, testCases[i].output);
        }
    }

    function test_ExtractsASequenceFromAWitnessInputAsLEAndInt() public {
        bytes memory input = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff";
        
        bytes4 res1 = instance.extractSequenceLEWitness(input);
        bytes4 output1 = hex"ffffffff";
        assertEq(res1, output1);

        uint res2 = instance.extractSequenceWitness(input);
        uint output2 = 4294967295;
        assertEq(res2, output2);
    }

    function test_ExtractsASequenceFromALegacyInputAsLEAndInt() public {
        bytes memory input = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba3000000000203232323232323232323232323232323232323232323232323232323232323232ffffffff";
        
        bytes4 res1 = instance.extractSequenceLELegacy(input);
        bytes4 output1 = hex"ffffffff";
        assertEq(res1, output1);

        uint res2 = instance.extractSequenceLegacy(input);
        uint output2 = 4294967295;
        assertEq(res2, output2);
    }

    function test_ErrorsOnBadVarintsInExtractSequenceLegacy() public {
        vm.expectRevert("Bad VarInt in scriptSig");
        bytes memory input = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba3000000000";
        instance.extractSequenceLegacy(input);
    }

    function test_ExtractsAnOutpointAsBytes() public {
        bytes memory input = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff";
        bytes memory output = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba3000000000";

        bytes memory res = instance.extractOutpoint(input);
        assertEq(res, output);
    }

    function test_ExtractsAnOutpointTxid() public {
        bytes memory input = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000001eeffffffff";
        bytes32 output = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba30";

        bytes32 res = instance.extractInputTxIdLE(input);
        assertEq(res, output);
    }

    function test_ExtractsAnOutpointTxIndexLE() public {
        bytes memory input = hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000001eeffffffff";
        bytes32 output = hex"00000000";

        bytes32 res = instance.extractTxIndexLE(input);
        assertEq(res, output);
    }

    struct ExtractHashTest {
        bytes input;
        bytes output;
    }

    function test_ExtractsTheHashFromAStandardOutput() public {
        ExtractHashTest[3] memory testCases = [
            ExtractHashTest({
                input: hex"4897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c18",
                output: hex"a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c18"
            }),
            ExtractHashTest({
                input: hex"00000000000000001976a914000000000000000000000000000000000000000088ac",
                output: hex"0000000000000000000000000000000000000000"
            }),
            ExtractHashTest({
                input: hex"000000000000000017a914000000000000000000000000000000000000000087",
                output: hex"0000000000000000000000000000000000000000"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes memory res = instance.extractHash(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct ExtractValueTest {
        bytes input;
        bytes8 outputRaw;
        uint output;
    }

    function test_ExtractsTheValueAsLEAndInt() public {
        ExtractValueTest[2] memory testCases = [
            ExtractValueTest({
                input: hex"4897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c18",
                outputRaw: hex"4897070000000000",
                output: 497480
            }),
            ExtractValueTest({
                input: hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                outputRaw: hex"0000000000000000",
                output: 0
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes8 res1 = instance.extractValueLE(testCases[i].input);
            assertEq(res1, testCases[i].outputRaw);

            uint res2 = instance.extractValue(testCases[i].input);
            assertEq(res2, testCases[i].output);

        }
    }

    struct DetermineInputLengthTest {
        bytes input;
        uint output;
    }

    function test_DeterminesInputLength() public {
        DetermineInputLengthTest[5] memory testCases = [
            DetermineInputLengthTest({
                input: hex"7bb2b8f32b9ebf13af2b0a2f9dc03797c7b77ccddcac75d1216389abfa7ab3750000000000ffffffffaa15ec17524f1f7bd47ab7caa4c6652cb95eec4c58902984f9b4bcfee444567d0000000000ffffff",
                output: 41
            }),
            DetermineInputLengthTest({
                input: hex"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd040000000000000000",
                output: 41
            }),
            DetermineInputLengthTest({
                input: hex"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0400000002000000000000",
                output: 43
            }),
            DetermineInputLengthTest({
                input: hex"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd040000000900000000000000000000000000",
                output: 50
            }),
            DetermineInputLengthTest({
                input: hex"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd04000000fdff0000000000",
                output: 298
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            uint res = instance.determineInputLength(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    function test_ExtractsOpReturnDataBlobs() public {
        bytes memory input1 = hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211";
        bytes memory output = hex"edb1b5c2f39af0fec151732585b1049b07895211";

        bytes memory res = instance.extractOpReturnData(input1);
        assertEq(res, output);

        vm.expectRevert("Slice out of bounds");
        bytes memory input2 = hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b078952";
        instance.extractOpReturnData(input2);
    }

    struct ExtractInputAtIndexTest {
        bytes inputVin;
        uint inputIndex;
        bytes output;
    }

    function test_ExtractsInputsAtSpecifiedIndices() public {
        ExtractInputAtIndexTest[6] memory testCases = [
            ExtractInputAtIndexTest({
                inputVin: hex"011746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                inputIndex: 0,
                output: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff"
            }),
            // 3-byte VarInt
            ExtractInputAtIndexTest({
                inputVin: hex"FD01001746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                inputIndex: 0,
                output: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff"
            }),
            // 5-byte VarInt
            ExtractInputAtIndexTest({
                inputVin: hex"FE010000001746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                inputIndex: 0,
                output: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff"
            }),
            // 9-byte VarInt
            ExtractInputAtIndexTest({
                inputVin: hex"FF01000000000000001746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                inputIndex: 0,
                output: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff"
            }),
            ExtractInputAtIndexTest({
                inputVin: hex"027bb2b8f32b9ebf13af2b0a2f9dc03797c7b77ccddcac75d1216389abfa7ab3750000000000ffffffffaa15ec17524f1f7bd47ab7caa4c6652cb95eec4c58902984f9b4bcfee444567d0000000000ffffffff",
                inputIndex: 0,
                output: hex"7bb2b8f32b9ebf13af2b0a2f9dc03797c7b77ccddcac75d1216389abfa7ab3750000000000ffffffff"
            }),
            ExtractInputAtIndexTest({
                inputVin: hex"027bb2b8f32b9ebf13af2b0a2f9dc03797c7b77ccddcac75d1216389abfa7ab3750000000000ffffffffaa15ec17524f1f7bd47ab7caa4c6652cb95eec4c58902984f9b4bcfee444567d0000000000ffffffff",
                inputIndex: 1,
                output: hex"aa15ec17524f1f7bd47ab7caa4c6652cb95eec4c58902984f9b4bcfee444567d0000000000ffffffff"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes memory res = instance.extractInputAtIndex(
                testCases[i].inputVin,
                testCases[i].inputIndex
            );
            assertEq(res, testCases[i].output);
        }
    }

    struct ExtractInputAtIndexErrorTest {
        bytes inputVin;
        uint inputIndex;
        bytes errorMessage;
    }

    function test_ExtractInputErrorsOnBadVin() public {
        ExtractInputAtIndexErrorTest[6] memory testCases = [
            // Read overrun, index is greater than the number of inputs
            ExtractInputAtIndexErrorTest({
                inputVin: hex"027bb2b8f32b9ebf13af2b0a2f9dc03797c7b77ccddcac75d1216389abfa7ab3750000000000ffffffffaa15ec17524f1f7bd47ab7caa4c6652cb95eec4c58902984f9b4bcfee444567d0000000000ffffffff",
                inputIndex: 3,
                errorMessage: "Vin read overrun"
            }),
            // Read Overrun at beginning of vin
            ExtractInputAtIndexErrorTest({
                inputVin: hex"ff",
                inputIndex: 3,
                errorMessage: "Read overrun during VarInt parsing"
            }),
            // Read overrun, index is greater than the number of inputs
            ExtractInputAtIndexErrorTest({
                inputVin: hex"027bb2b8f32b9ebf13af2b0a2f9dc03797c7b77ccddcac75d1216389abfa7ab3750000000000ffffffffaa15ec17524f1f7bd47ab7caa4c6652cb95eec4c58902984f9b4bcfee444560000000000ffffffff",
                inputIndex: 3,
                errorMessage: "Vin read overrun"
            }),
            // Bad VarInt in scriptsig of input being extracted
            ExtractInputAtIndexErrorTest({
                inputVin: hex"01000000000000000000000000000000000000000000000000000000000000000000000000FF",
                inputIndex: 0,
                errorMessage: "Bad VarInt in scriptSig"
            }),
            // Bad VarInt in scriptsig of input being extracted
            ExtractInputAtIndexErrorTest({
                inputVin: hex"02000000000000000000000000000000000000000000000000000000000000000000000000FF",
                inputIndex: 1,
                errorMessage: "Bad VarInt in scriptSig"
            }),
            // Bad VarInt in scriptsig of input being extracted
            ExtractInputAtIndexErrorTest({
                inputVin: hex"01000000000000000000000000000000000000000000000000000000000000000000000000FC",
                inputIndex: 0,
                errorMessage: "Slice out of bounds"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            vm.expectRevert(testCases[i].errorMessage);
            instance.extractInputAtIndex(
                testCases[i].inputVin,
                testCases[i].inputIndex
            );
        }
    }

    struct IsLegacyInputTest {
        bytes input;
        bool output;
    }

    function test_SortsLegacyFromWitnessInputs() public {
        IsLegacyInputTest[2] memory testCases = [
            IsLegacyInputTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: false
            }),
            IsLegacyInputTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000001eeffffffff",
                output: true
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.isLegacyInput(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct ExtractScriptSigTest {
        bytes input;
        bytes output;
    }

    function test_ExtractsTheScriptSigFromInputs() public {
        ExtractScriptSigTest[4] memory testCases = [
            ExtractScriptSigTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: hex"00"
            }),
            ExtractScriptSigTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000001eeffffffff",
                output: hex"01ee"
            }),
            ExtractScriptSigTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba3000000000fd0100eeffffffff",
                output: hex"fd0100ee"
            }),
            ExtractScriptSigTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba3000000000fe01000000eeffffffff",
                output: hex"fe01000000ee"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes memory res = instance.extractScriptSig(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    function test_ErrorsOnBadVarintsInExtractScriptSig() public {
        vm.expectRevert("Bad VarInt in scriptSig");
        instance.extractScriptSig(hex"ff");
    }

    struct ExtractScriptSigLenTest {
        bytes input;
        uint output1;
        uint output2;
    }

    function test_ExtractsTheLengthOfTheVarIntAndScriptSigFromInputs() public {
        ExtractScriptSigLenTest[3] memory testCases = [
            ExtractScriptSigLenTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output1: 0,
                output2: 0
            }),
            ExtractScriptSigLenTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000001eeffffffff",
                output1: 0,
                output2: 1
            }),
            ExtractScriptSigLenTest({
                input: hex"1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba3000000000FF0000000000000000ffffffff",
                output1: 8,
                output2: 0
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            (uint256 res1, uint256 res2) = instance.extractScriptSigLen(testCases[i].input);
            assertEq(res1, testCases[i].output1);
            assertEq(res2, testCases[i].output2);
        }
    }

    struct ValidateVinTest {
        bytes input;
        bool output;
    }

    function test_ValidatesVinLengthBasedOnStatedSize() public {
        ValidateVinTest[9] memory testCases = [
            ValidateVinTest({
                input: hex"011746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: true
            }),
            // Non-minimal VarInt encoding
            ValidateVinTest({
                input: hex"FF01000000000000001746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: true
            }),
            ValidateVinTest({
                input: hex"FF1746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: false
            }),
            ValidateVinTest({
                input: hex"001746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: false
            }),
            ValidateVinTest({
                input: hex"011746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffff",
                output: false
            }),
            ValidateVinTest({
                input: hex"011746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffffEEEE",
                output: false
            }),
            ValidateVinTest({
                input: hex"021746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: false
            }),
            // 0 inputs
            ValidateVinTest({
                input: hex"001746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff",
                output: false
            }),
            // Read overrun
            ValidateVinTest({
                input: hex"FF",
                output: false
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.validateVin(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct ValidateVoutTest {
        bytes input;
        bool output;
    }

    function test_ValidatesVoutLengthBasedOnStatedSize() public {
        ValidateVoutTest[11] memory testCases = [
            ValidateVoutTest({
                input: hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                output: true
            }),
            // Non-minimal VarInt Encoding
            ValidateVoutTest({
                input: hex"FF02000000000000004897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                output: true
            }),
            ValidateVoutTest({
                input: hex"FF4897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                output: false
            }),
            ValidateVoutTest({
                input: hex"004897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                output: false
            }),
            ValidateVoutTest({
                input: hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b078952",
                output: false
            }),
            ValidateVoutTest({
                input: hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b0789521111111111111111",
                output: false
            }),
            ValidateVoutTest({
                input: hex"024897070000000000ff0020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                output: false
            }),
            ValidateVoutTest({
                input: hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000",
                output: false
            }),
            ValidateVoutTest({
                input: hex"004897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000",
                output: false
            }),
            // Read overrun
            ValidateVoutTest({
                input: hex"FF",
                output: false
            }),
            // Read overrun
            ValidateVoutTest({
                input: hex"010102030405060708FF",
                output: false
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.validateVout(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct DetermineOutputLengthTest {
        bytes input;
        uint output;
    }

    function test_DeterminesOutputLengthProperly() public {
        DetermineOutputLengthTest[8] memory testCases = [
            DetermineOutputLengthTest({
                input: hex"00000000000000002200",
                output: 43
            }),
            DetermineOutputLengthTest({
                input: hex"00000000000000001600",
                output: 31
            }),
            DetermineOutputLengthTest({
                input: hex"0000000000000000206a",
                output: 41
            }),
            DetermineOutputLengthTest({
                input: hex"000000000000000002",
                output: 11
            }),
            DetermineOutputLengthTest({
                input: hex"000000000000000000",
                output: 9
            }),
            DetermineOutputLengthTest({
                input: hex"000000000000000088",
                output: 145
            }),
            DetermineOutputLengthTest({
                input: hex"0000000000000000fc",
                output: 261
            }),
            // Non-minimal VarInt encoding
            DetermineOutputLengthTest({
                input: hex"0000000000000000FFfc00000000000000",
                output: 269
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            uint res = instance.determineOutputLength(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct ExtractOutputAtIndexTest {
        bytes inputVout;
        uint inputIndex;
        bytes output;
    }

    function test_ExtractsOutputsAtSpecifiedIndices() public {
        ExtractOutputAtIndexTest[7] memory testCases = [
            ExtractOutputAtIndexTest({
                inputVout: hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                inputIndex: 0,
                output: hex"4897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c18"
            }),
            ExtractOutputAtIndexTest({
                inputVout: hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                inputIndex: 1,
                output: hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211"
            }),
            // 3-byte VarInt
            ExtractOutputAtIndexTest({
                inputVout: hex"FD02004897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                inputIndex: 1,
                output: hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211"
            }),
            // 5-byte VarInt
            ExtractOutputAtIndexTest({
                inputVout: hex"FE020000004897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                inputIndex: 1,
                output: hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211"
            }),
            // 9-byte VarInt
            ExtractOutputAtIndexTest({
                inputVout: hex"FF02000000000000004897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211",
                inputIndex: 1,
                output: hex"0000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211"
            }),
            ExtractOutputAtIndexTest({
                inputVout: hex"024db6000000000000160014455c0ea778752831d6fc25f6f8cf55dc49d335f040420f0000000000220020aedad4518f56379ef6f1f52f2e0fed64608006b3ccaff2253d847ddc90c91922",
                inputIndex: 0,
                output: hex"4db6000000000000160014455c0ea778752831d6fc25f6f8cf55dc49d335f0"
            }),
            ExtractOutputAtIndexTest({
                inputVout: hex"024db6000000000000160014455c0ea778752831d6fc25f6f8cf55dc49d335f040420f0000000000220020aedad4518f56379ef6f1f52f2e0fed64608006b3ccaff2253d847ddc90c91922",
                inputIndex: 1,
                output: hex"40420f0000000000220020aedad4518f56379ef6f1f52f2e0fed64608006b3ccaff2253d847ddc90c91922"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bytes memory res = instance.extractOutputAtIndex(
                testCases[i].inputVout,
                testCases[i].inputIndex
            );
            assertEq(res, testCases[i].output);
        }
    }

    struct ExtractOutputAtIndexErrorTest {
        bytes inputVout;
        uint inputIndex;
        bytes errorMessage;
    }

    function test_ErrorsWhileExtractingOutputsAtSpecifiedIndices() public {
        ExtractOutputAtIndexErrorTest[8] memory testCases = [
            // Read overrun during VarInt parsing
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"ff",
                inputIndex: 1,
                errorMessage: "Read overrun during VarInt parsing"
            }),
            // Bad VarInt in scriptPubKey
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"010101010101010101ff",
                inputIndex: 0,
                errorMessage: "Bad VarInt in scriptPubkey"
            }),
            // Read overrun, index is greater than the number of outputs
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"010101010101010101ff",
                inputIndex: 1,
                errorMessage: "Vout read overrun"
            }),
            // Bad VarInt inside loop
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"020101010101010101ff",
                inputIndex: 1,
                errorMessage: "Bad VarInt in scriptPubkey"
            }),
            // Read overrun, index is greater than the number of outputs
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"024db6000000000000160014455c0ea778752831d6fc25f6f8cf55dc49d335f040420f0000000000220020aedad4518f56379ef6f1f52f2e0fed64608006b3ccaff2253d847ddc90c91922",
                inputIndex: 3,
                errorMessage: "Vout read overrun"
            }),
            // Bad VarInt in scriptPubkey
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"014db6000000000000ff",
                inputIndex: 0,
                errorMessage: "Bad VarInt in scriptPubkey"
            }),
            // Bad VarInt in scriptPubkey
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"024db6000000000000160014455c0ea778752831d6fc25f6f8cf55dc49d335f040420f0000000000FF",
                inputIndex: 1,
                errorMessage: "Bad VarInt in scriptPubkey"
            }),
            // Invalid vout
            ExtractOutputAtIndexErrorTest({
                inputVout: hex"024db6000000000000160014455c0ea778752831d6fc25f6f8cf55dc49d335f040420f0000000000FB",
                inputIndex: 1,
                errorMessage: "Slice out of bounds"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            vm.expectRevert(testCases[i].errorMessage);
            instance.extractOutputAtIndex(
                testCases[i].inputVout,
                testCases[i].inputIndex
            );
        }
    }

    function test_ExtractsARootFromAHeader() public {
        bytes memory input = hex"0100000055bd840a78798ad0da853f68974f3d183e2bd1db6a842c1feecf222a00000000ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d51b96a49ffff001d283e9e70";
        bytes32 output = hex"ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d";

        bytes32 res = instance.extractMerkleRootLE(input);
        assertEq(res, output);
    }

    function test_ExtractsTheTargetFromAHeader() public {
        bytes memory input = hex"0100000055bd840a78798ad0da853f68974f3d183e2bd1db6a842c1feecf222a00000000ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d51b96a49ffff001d283e9e70";
        bytes32 output = hex"00000000ffff0000000000000000000000000000000000000000000000000000";

        uint res = instance.extractTarget(input);
        assertEq(res, uint(output));
    }

    function test_ExtractsThePrevBlockHash() public {
        bytes memory input = hex"0100000055bd840a78798ad0da853f68974f3d183e2bd1db6a842c1feecf222a00000000ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d51b96a49ffff001d283e9e70";
        bytes32 output = hex"55bd840a78798ad0da853f68974f3d183e2bd1db6a842c1feecf222a00000000";

        bytes32 res = instance.extractPrevBlockLE(input);
        assertEq(res, output);
    }

    function test_ExtractsATimestampFromAHeader() public {
        bytes memory input = hex"0100000055bd840a78798ad0da853f68974f3d183e2bd1db6a842c1feecf222a00000000ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d51b96a49ffff001d283e9e70";
        uint output = 1231731025;

        uint res = instance.extractTimestamp(input);
        assertEq(res, output);
    }

    struct VerifyHash256MerkleTest {
        bytes inputProof;
        uint inputIndex;
        bool output;
    }

    function test_VerifiesABitcoinMerkleRoot() public {
        VerifyHash256MerkleTest[8] memory testCases = [
            VerifyHash256MerkleTest({
                inputProof: hex"82501c1178fa0b222c1f3d474ec726b832013f0a532b44bb620cce8624a5feb1169e1e83e930853391bc6f35f605c6754cfead57cf8387639d3b4096c54f18f4ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d",
                inputIndex: 0,
                output: true
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"169e1e83e930853391bc6f35f605c6754cfead57cf8387639d3b4096c54f18f482501c1178fa0b222c1f3d474ec726b832013f0a532b44bb620cce8624a5feb1ff104ccb05421ab93e63f8c3ce5c2c2e9dbb37de2764b3a3175c8166562cac7d",
                inputIndex: 1,
                output: true
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"6c1320f4552ba68f3dbdd91f9422405f779b779e21678448e8035c21c1e2edd67a6190a846e318878be71565841d90a78e9e617b2d859d5e0767c13de427be4a2a6a6d55b17316d45ac11c4e613c38b293db606bace5062470d783471cc66c180455e6472ce92d32179994c3d44b75dd9834e1e7438cf9ab5be1ef6edf1e4a8d361dda470aca6e97c3b4056d4b329beba9ffd6a26c86a2a3f8f9ad31826b69ee49693027a439b3149853907afe87031f3bcf484b8bdd2e047d579d2ee2569c16769a33473b652d1d365886f9f9fba64fdea23ab16306ae1484ed632dcd381e5132c401084bc783478306202844b9cf34aff6ab24182206caa6eebc3e016fa373986d08ac9ae256ddda2deedc6662fd8f8a300ecdd38db2c5d6d2765a7515531e7f96f0310f9493cf79be3e60f63d8a6fa0c62ea59312731fd5b71b261abd99f5b908b3166d53532c9557a0f6ce9bc18f7b7619b2257043052a7ff2e5030e838f2e9edcc0f7273fa273a6b3ce2112dbd686f060b5f61deb1abc7247edf1bd6cd7ca4a6c5cfaedbc5905ef4f0511b143a0672ce4fa2dc1ed8852e077e0184febca",
                inputIndex: 4,
                output: true
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6e35a0d6de94b656694589964a252957e4673a9fb1d2f8b4a92e3f0a7bb654fddb94e5a1e6d7f7f499fd1be5dd30a73bf5584bf137da5fdd77cc21aeb95b9e35788894be019284bd4fbed6dd6118ac2cb6d26bc4be4e423f55a3a48f2874d8d02a65d9c87d07de21d4dfe7b0a9f4a23cc9a58373e9e6931fefdb5afade5df54c91104048df1ee999240617984e18b6f931e2373673d0195b8c6987d7ff7650d5ce53bcec46e13ab4f2da1146a7fc621ee672f62bc22742486392d75e55e67b09960c3386a0b49e75f1723d6ab28ac9a2028a0c72866e2111d79d4817b88e17c821937847768d92837bae3832bb8e5a4ab4434b97e00a6c10182f211f592409068d6f5652400d9a3d1cc150a7fb692e874cc42d76bdafc842f2fe0f835a7c24d2d60c109b187d64571efbaa8047be85821f8e67e0e85f2f5894bc63d00c2ed9d640296ef123ea96da5cf695f22bf7d94be87d49db1ad7ac371ac43c4da4161c8c2",
                inputIndex: 281,
                output: true
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"54269907e95e412ef574056ea5b0e0debd2290193879e5c295caea777f0ae8b2602ac17ae2e219873600eb2b6fb301f31894121b475f19d394d92122de353e3e47254a20aa67eb76e73f284b11fb1d0e101100753d8ab7818961220cdd26860f756c859e76151b1d368a7f102649eca20ff00bf3e664a1dfa420af1f81077c94c8b9827f337f48d24a0f556bace3a35439451c788b4ba0453de5c8c3fd7e841003b7dd274c3b118e94b2286c725b61e72432a305593e91bf7c0fe1c423d4cb0a21a4fa31617fd9938a1b57649466837632a44faf6f36704a01a39a2e7a545ec3a1e6309f5aadca2171cac2beff0896c6a251c877ad42d1c414293bd7e36a02c5b5415b45f1a13f4a01926f28017ba01b2cca53ec53224acb2934d43499a83a18d3a0d186fe6c8e85faa6bde57b521af40617cb24d59b50933eda6d64a5d6ffc1b3cf4f35d6040e60a67c3f270ef7e237066cf2118d7767a6161ec4f1ff24ac70a2f0d7763665a84f267898e93e5ec693ddb4938aa2d9caca11b1462bc6b772a8743c578ec3d89fd330b90126d2f758e9319c4d3232aed3545bda2fbcb9d39af17209f58088422fc42c5849f910c29ec174fbf89bf4fb25b5600d024773ee5a5e",
                inputIndex: 781,
                output: true
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"00",
                inputIndex: 0,
                output: false
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
                inputIndex: 0,
                output: true
            }),
            VerifyHash256MerkleTest({
                inputProof: hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
                inputIndex: 0,
                output: false
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.verifyHash256Merkle(
                testCases[i].inputProof,
                testCases[i].inputIndex
            );
            assertEq(res, testCases[i].output);
        }
    }

    struct DetermineVarIntDataLengthTest {
        bytes input;
        uint output;
    }

    function test_DeterminesVarIntDataLengthsCorrectly() public {
        DetermineVarIntDataLengthTest[4] memory testCases = [
            DetermineVarIntDataLengthTest({
                input: hex"01", // 1
                output: 0
            }),
            DetermineVarIntDataLengthTest({
                input: hex"fd", // 253
                output: 2
            }),
            DetermineVarIntDataLengthTest({
                input: hex"fe", // 254
                output: 4
            }),
            DetermineVarIntDataLengthTest({
                input: hex"ff", // 255
                output: 8
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            uint res = instance.determineVarIntDataLength(testCases[i].input);
            assertEq(res, testCases[i].output);
        }
    }

    struct ParseVarIntTest {
        bytes input;
        uint outputNumBytes;
        uint outputEncodedInt;
    }

    function test_ParsesVarInts() public {
        ParseVarIntTest[4] memory testCases = [
            ParseVarIntTest({
                input: hex"01",
                outputNumBytes: 0,
                outputEncodedInt: 1
            }),
            ParseVarIntTest({
                input: hex"ff0000000000000000",
                outputNumBytes: 8,
                outputEncodedInt: 0
            }),
            ParseVarIntTest({
                input: hex"fe03000000",
                outputNumBytes: 4,
                outputEncodedInt: 3
            }),
            ParseVarIntTest({
                input: hex"fd0001",
                outputNumBytes: 2,
                outputEncodedInt: 256
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            (uint resNumBytes, uint resEncodedInt) = instance.parseVarInt(testCases[i].input);
            assertEq(resNumBytes, testCases[i].outputNumBytes);
            assertEq(resEncodedInt, testCases[i].outputEncodedInt);
        }
    }

    struct ParseVarIntErrorTest {
        bytes input;
    }

    function test_ReturnsErrorForInvalidVarInts() public {
        ParseVarIntErrorTest[3] memory testCases = [
            ParseVarIntErrorTest({
                input: hex"fd01"
            }),
            ParseVarIntErrorTest({
                input: hex"fe010000"
            }),
            ParseVarIntErrorTest({
                input: hex"ff01000000000000"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            (uint resNumBytes, uint resEncodedInt) = instance.parseVarInt(testCases[i].input);
            assertEq(resNumBytes, uint(bytes32(hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")));
            assertEq(resEncodedInt, 0);
        }
    }

    struct BlockHeader {
        bytes blockHash;
        uint version;
        bytes prevBlock;
        bytes merkleRoot;
        uint timestamp;
        bytes nBits;
        bytes nonce;
        uint difficulty;
        bytes blockHex;
        uint height;
    }

    struct RetargetAlgorithmTest {
        BlockHeader[3] input;
        uint output;
    }

    function test_CalculatesConsensusCorrectRetargets() public {
        RetargetAlgorithmTest[10] memory testCases = [
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"000000000000000000043c0b1ba0e06f1569ff7cebca6a78a84f4025712067ae",
                        version: 541065216,
                        prevBlock: hex"00000000000000000015a08d0a60237487070fe0d956d5fb5fd9d21ad6d7b2d3",
                        merkleRoot: hex"d192743a2c190a7421f92fefe92505579d7b8eda568cacee13b25751ac704c66",
                        timestamp: 1545175965,
                        nBits: hex"f41e3717",
                        nonce: hex"21bae3e7",
                        difficulty: 5106422924659,
                        blockHex: hex"00004020d3b2d7d61ad2d95ffbd556d9e00f07877423600a8da015000000000000000000d192743a2c190a7421f92fefe92505579d7b8eda568cacee13b25751ac704c669d83195cf41e371721bae3e7",
                        height: 554400
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000008f4f64baaa9b28d4476f2a000c459df492d5664320b12",
                        version: 536870912,
                        prevBlock: hex"0000000000000000002089653c6ee3ecd6ecca09b937a9cab9da14ea8b387dbc",
                        merkleRoot: hex"7c0900cf1a9b40411141859b98bf95fb9d414f49044e08acff21fa54506022a4",
                        timestamp: 1546275302,
                        nBits: hex"f41e3717",
                        nonce: hex"d2864679",
                        difficulty: 5106422924659,
                        blockHex: hex"00000020bc7d388bea14dab9caa937b909caecd6ece36e3c6589200000000000000000007c0900cf1a9b40411141859b98bf95fb9d414f49044e08acff21fa54506022a4e6492a5cf41e3717d2864679",
                        height: 556415
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000002a531985d49cdb5adcd1db0578845a233a3a2cfdefdf8f",
                        version: 536870912,
                        prevBlock: hex"00000000000000000008f4f64baaa9b28d4476f2a000c459df492d5664320b12",
                        merkleRoot: hex"5cb4b52150fe7dec217b74db424e442ef8b24105c244ebaeb59f638db9c48ef3",
                        timestamp: 1546276809,
                        nBits: hex"a5183217",
                        nonce: hex"b412a530",
                        difficulty: 5618595848853,
                        blockHex: hex"00000020120b3264562d49df59c400a0f276448db2a9aa4bf6f4080000000000000000005cb4b52150fe7dec217b74db424e442ef8b24105c244ebaeb59f638db9c48ef3c94f2a5ca5183217b412a530",
                        height: 556416
                    })
                ],
                output: 5618595848853
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"0000000000000000002a531985d49cdb5adcd1db0578845a233a3a2cfdefdf8f",
                        version: 536870912,
                        prevBlock: hex"00000000000000000008f4f64baaa9b28d4476f2a000c459df492d5664320b12",
                        merkleRoot: hex"5cb4b52150fe7dec217b74db424e442ef8b24105c244ebaeb59f638db9c48ef3",
                        timestamp: 1546276809,
                        nBits: hex"a5183217",
                        nonce: hex"b412a530",
                        difficulty: 5618595848853,
                        blockHex: hex"00000020120b3264562d49df59c400a0f276448db2a9aa4bf6f4080000000000000000005cb4b52150fe7dec217b74db424e442ef8b24105c244ebaeb59f638db9c48ef3c94f2a5ca5183217b412a530",
                        height: 556416
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000028a69d9498c46b2b073752133e3e9e585965e7dab55065",
                        version: 541065216,
                        prevBlock: hex"0000000000000000000fe62df0a448387749c30d5d2a5f1023066c4f3a97c922",
                        merkleRoot: hex"e88eabc4c6398c80cea87f6d1d662c6640de4719f7949ae85afe75746dd04abb",
                        timestamp: 1547431851,
                        nBits: hex"a5183217",
                        nonce: hex"f6d45f41",
                        difficulty: 5618595848853,
                        blockHex: hex"0000402022c9973a4f6c0623105f2a5d0dc349773848a4f02de60f000000000000000000e88eabc4c6398c80cea87f6d1d662c6640de4719f7949ae85afe75746dd04abbabef3b5ca5183217f6d45f41",
                        height: 558431
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000021ac236d0b29b4467f99c2c8783032451ba7b735045e3c",
                        version: 805289984,
                        prevBlock: hex"00000000000000000028a69d9498c46b2b073752133e3e9e585965e7dab55065",
                        merkleRoot: hex"5988783435f506d2ccfbadb484e56d6f1d5dfdd480650acae1e3b43d3464ea73",
                        timestamp: 1547432394,
                        nBits: hex"33d62f17",
                        nonce: hex"1d508fdb",
                        difficulty: 5883988430955,
                        blockHex: hex"00c0ff2f6550b5dae76559589e3e3e135237072b6bc498949da6280000000000000000005988783435f506d2ccfbadb484e56d6f1d5dfdd480650acae1e3b43d3464ea73caf13b5c33d62f171d508fdb",
                        height: 558432
                    })
                ],
                output: 5883988430955
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"00000000000000000021ac236d0b29b4467f99c2c8783032451ba7b735045e3c",
                        version: 805289984,
                        prevBlock: hex"00000000000000000028a69d9498c46b2b073752133e3e9e585965e7dab55065",
                        merkleRoot: hex"5988783435f506d2ccfbadb484e56d6f1d5dfdd480650acae1e3b43d3464ea73",
                        timestamp: 1547432394,
                        nBits: hex"33d62f17",
                        nonce: hex"1d508fdb",
                        difficulty: 5883988430955,
                        blockHex: hex"00c0ff2f6550b5dae76559589e3e3e135237072b6bc498949da6280000000000000000005988783435f506d2ccfbadb484e56d6f1d5dfdd480650acae1e3b43d3464ea73caf13b5c33d62f171d508fdb",
                        height: 558432
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000014dbca1d9ea7256a3993253c033a50d8b3064a2cbd056b",
                        version: 536870912,
                        prevBlock: hex"00000000000000000023cf32e875ff55fc6e73dea5bb4fb92235e3a54ce5e8d8",
                        merkleRoot: hex"07b395f80858ee022c9c3c2f0f5cee4bd807039f0729b0559ae4326c3ba77d6b",
                        timestamp: 1548656416,
                        nBits: hex"33d62f17",
                        nonce: hex"46ee356d",
                        difficulty: 5883988430955,
                        blockHex: hex"00000020d8e8e54ca5e33522b94fbba5de736efc55ff75e832cf2300000000000000000007b395f80858ee022c9c3c2f0f5cee4bd807039f0729b0559ae4326c3ba77d6b209f4e5c33d62f1746ee356d",
                        height: 560447
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000020adeb95048ff41daac22d2dd97414fd5c47cdc391923a",
                        version: 536870912,
                        prevBlock: hex"00000000000000000014dbca1d9ea7256a3993253c033a50d8b3064a2cbd056b",
                        merkleRoot: hex"1b08df3d42cd9a38d8b66adf9dc5eb464f503633bd861085ffff723634531596",
                        timestamp: 1548657313,
                        nBits: hex"35683017",
                        nonce: hex"bf67b72a",
                        difficulty: 5814661935891,
                        blockHex: hex"000000206b05bd2c4a06b3d8503a033c2593396a25a79e1dcadb140000000000000000001b08df3d42cd9a38d8b66adf9dc5eb464f503633bd861085ffff723634531596a1a24e5c35683017bf67b72a",
                        height: 560448
                    })
                ],
                output: 5814661935891
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"00000000000000000020adeb95048ff41daac22d2dd97414fd5c47cdc391923a",
                        version: 536870912,
                        prevBlock: hex"00000000000000000014dbca1d9ea7256a3993253c033a50d8b3064a2cbd056b",
                        merkleRoot: hex"1b08df3d42cd9a38d8b66adf9dc5eb464f503633bd861085ffff723634531596",
                        timestamp: 1548657313,
                        nBits: hex"35683017",
                        nonce: hex"bf67b72a",
                        difficulty: 5814661935891,
                        blockHex: hex"000000206b05bd2c4a06b3d8503a033c2593396a25a79e1dcadb140000000000000000001b08df3d42cd9a38d8b66adf9dc5eb464f503633bd861085ffff723634531596a1a24e5c35683017bf67b72a",
                        height: 560448
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000019046cf62aa17f6e526636c71c09161c8e730b64d755ae",
                        version: 536870912,
                        prevBlock: hex"0000000000000000000d58e0330e678481f4a1d73a9a262cee3e729e914a6da4",
                        merkleRoot: hex"d0df74c5c0ca4ee2c0f0a93e173d5ea68788413febe3d572f573bf2ef2a90667",
                        timestamp: 1549817652,
                        nBits: hex"35683017",
                        nonce: hex"deaa6854",
                        difficulty: 5814661935891,
                        blockHex: hex"00000020a46d4a919e723eee2c269a3ad7a1f48184670e33e0580d000000000000000000d0df74c5c0ca4ee2c0f0a93e173d5ea68788413febe3d572f573bf2ef2a906673457605c35683017deaa6854",
                        height: 562463
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000000db7442b5662bbd980d7c2db1aef2ca925917ae392df11",
                        version: 536870912,
                        prevBlock: hex"00000000000000000019046cf62aa17f6e526636c71c09161c8e730b64d755ae",
                        merkleRoot: hex"f7825fe0714275fe54521f66e898cf743ed43dd93f185cb628df995823e4ee2d",
                        timestamp: 1549817981,
                        nBits: hex"886f2e17",
                        nonce: hex"6d085a4c",
                        difficulty: 6061518831027,
                        blockHex: hex"00000020ae55d7640b738e1c16091cc73666526e7fa12af66c0419000000000000000000f7825fe0714275fe54521f66e898cf743ed43dd93f185cb628df995823e4ee2d7d58605c886f2e176d085a4c",
                        height: 562464
                    })
                ],
                output: 6061518831027
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"0000000000000000000db7442b5662bbd980d7c2db1aef2ca925917ae392df11",
                        version: 536870912,
                        prevBlock: hex"00000000000000000019046cf62aa17f6e526636c71c09161c8e730b64d755ae",
                        merkleRoot: hex"f7825fe0714275fe54521f66e898cf743ed43dd93f185cb628df995823e4ee2d",
                        timestamp: 1549817981,
                        nBits: hex"886f2e17",
                        nonce: hex"6d085a4c",
                        difficulty: 6061518831027,
                        blockHex: hex"00000020ae55d7640b738e1c16091cc73666526e7fa12af66c0419000000000000000000f7825fe0714275fe54521f66e898cf743ed43dd93f185cb628df995823e4ee2d7d58605c886f2e176d085a4c",
                        height: 562464
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000017e5c36734296b27065045f181e028c0d91cebb336d50c",
                        version: 536870912,
                        prevBlock: hex"0000000000000000000365d89a02f14ef85eb497a51b010622d0e48ef70efeb4",
                        merkleRoot: hex"34fdbe970f5d00d2e37de72755077c7039976baa5417ddfd358013d8ea9cb8d3",
                        timestamp: 1551025524,
                        nBits: hex"886f2e17",
                        nonce: hex"95d4ee3a",
                        difficulty: 6061518831027,
                        blockHex: hex"00000020b4fe0ef78ee4d02206011ba597b45ef84ef1029ad8650300000000000000000034fdbe970f5d00d2e37de72755077c7039976baa5417ddfd358013d8ea9cb8d374c5725c886f2e1795d4ee3a",
                        height: 564479
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000002567dc317da20ddb0d7ef922fe1f9c2375671654f9006c",
                        version: 536870912,
                        prevBlock: hex"00000000000000000017e5c36734296b27065045f181e028c0d91cebb336d50c",
                        merkleRoot: hex"7bc1b27489db01c85d38a4bc6d2280611e9804f506d83ad00d2a33ebd663992f",
                        timestamp: 1551026038,
                        nBits: hex"505b2e17",
                        nonce: hex"4fb90f55",
                        difficulty: 6071846049920,
                        blockHex: hex"000000200cd536b3eb1cd9c028e081f1455006276b293467c3e5170000000000000000007bc1b27489db01c85d38a4bc6d2280611e9804f506d83ad00d2a33ebd663992f76c7725c505b2e174fb90f55",
                        height: 564480
                    })
                ],
                output: 6071846049920
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"0000000000000000002567dc317da20ddb0d7ef922fe1f9c2375671654f9006c",
                        version: 536870912,
                        prevBlock: hex"00000000000000000017e5c36734296b27065045f181e028c0d91cebb336d50c",
                        merkleRoot: hex"7bc1b27489db01c85d38a4bc6d2280611e9804f506d83ad00d2a33ebd663992f",
                        timestamp: 1551026038,
                        nBits: hex"505b2e17",
                        nonce: hex"4fb90f55",
                        difficulty: 6071846049920,
                        blockHex: hex"000000200cd536b3eb1cd9c028e081f1455006276b293467c3e5170000000000000000007bc1b27489db01c85d38a4bc6d2280611e9804f506d83ad00d2a33ebd663992f76c7725c505b2e174fb90f55",
                        height: 564480
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000002296c06935b34f3ed946d98781ff471a99101796e8611b",
                        version: 536870912,
                        prevBlock: hex"0000000000000000000d19c44e45aa18947b696ce3ebfd03b06a24e5c4d86421",
                        merkleRoot: hex"59134ad5aaad38a0e75946c7d4cb09b3ad45b459070195dd564cde193cf0ef29",
                        timestamp: 1552236227,
                        nBits: hex"505b2e17",
                        nonce: hex"f61af734",
                        difficulty: 6071846049920,
                        blockHex: hex"000000202164d8c4e5246ab003fdebe36c697b9418aa454ec4190d00000000000000000059134ad5aaad38a0e75946c7d4cb09b3ad45b459070195dd564cde193cf0ef29c33e855c505b2e17f61af734",
                        height: 566495
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000015fea169c62eb0a1161aba36932ca32bc3785cbb3480bf",
                        version: 536870912,
                        prevBlock: hex"0000000000000000002296c06935b34f3ed946d98781ff471a99101796e8611b",
                        merkleRoot: hex"d0098658f53531e6e67fc9448986b5a8f994da42d746079eabe10f55e561e243",
                        timestamp: 1552236304,
                        nBits: hex"17612e17",
                        nonce: hex"35c4afdb",
                        difficulty: 6068891541676,
                        blockHex: hex"000000201b61e8961710991a47ff8187d946d93e4fb33569c09622000000000000000000d0098658f53531e6e67fc9448986b5a8f994da42d746079eabe10f55e561e243103f855c17612e1735c4afdb",
                        height: 566496
                    })
                ],
                output: 6071846049920
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"0000000000000000002567dc317da20ddb0d7ef922fe1f9c2375671654f9006c",
                        version: 536870912,
                        prevBlock: hex"00000000000000000017e5c36734296b27065045f181e028c0d91cebb336d50c",
                        merkleRoot: hex"7bc1b27489db01c85d38a4bc6d2280611e9804f506d83ad00d2a33ebd663992f",
                        timestamp: 1551026038,
                        nBits: hex"505b2e17",
                        nonce: hex"4fb90f55",
                        difficulty: 6071846049920,
                        blockHex: hex"000000200cd536b3eb1cd9c028e081f1455006276b293467c3e5170000000000000000007bc1b27489db01c85d38a4bc6d2280611e9804f506d83ad00d2a33ebd663992f76c7725c505b2e174fb90f55",
                        height: 564480
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000002296c06935b34f3ed946d98781ff471a99101796e8611b",
                        version: 536870912,
                        prevBlock: hex"0000000000000000000d19c44e45aa18947b696ce3ebfd03b06a24e5c4d86421",
                        merkleRoot: hex"59134ad5aaad38a0e75946c7d4cb09b3ad45b459070195dd564cde193cf0ef29",
                        timestamp: 1552236227,
                        nBits: hex"505b2e17",
                        nonce: hex"f61af734",
                        difficulty: 6071846049920,
                        blockHex: hex"000000202164d8c4e5246ab003fdebe36c697b9418aa454ec4190d00000000000000000059134ad5aaad38a0e75946c7d4cb09b3ad45b459070195dd564cde193cf0ef29c33e855c505b2e17f61af734",
                        height: 566495
                    }),
                    BlockHeader({
                        blockHash: hex"00000000000000000015fea169c62eb0a1161aba36932ca32bc3785cbb3480bf",
                        version: 536870912,
                        prevBlock: hex"0000000000000000002296c06935b34f3ed946d98781ff471a99101796e8611b",
                        merkleRoot: hex"d0098658f53531e6e67fc9448986b5a8f994da42d746079eabe10f55e561e243",
                        timestamp: 1552236304,
                        nBits: hex"17612e17",
                        nonce: hex"35c4afdb",
                        difficulty: 6068891541676,
                        blockHex: hex"000000201b61e8961710991a47ff8187d946d93e4fb33569c09622000000000000000000d0098658f53531e6e67fc9448986b5a8f994da42d746079eabe10f55e561e243103f855c17612e1735c4afdb",
                        height: 566496
                    })
                ],
                output: 6068891541676
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"00000000000000000015fea169c62eb0a1161aba36932ca32bc3785cbb3480bf",
                        version: 536870912,
                        prevBlock: hex"0000000000000000002296c06935b34f3ed946d98781ff471a99101796e8611b",
                        merkleRoot: hex"d0098658f53531e6e67fc9448986b5a8f994da42d746079eabe10f55e561e243",
                        timestamp: 1552236304,
                        nBits: hex"17612e17",
                        nonce: hex"35c4afdb",
                        difficulty: 6068891541676,
                        blockHex: hex"000000201b61e8961710991a47ff8187d946d93e4fb33569c09622000000000000000000d0098658f53531e6e67fc9448986b5a8f994da42d746079eabe10f55e561e243103f855c17612e1735c4afdb",
                        height: 566496
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000001ccf7aa37a7f07e4d709eef9c6c4abd0b808686b14c314",
                        version: 536870912,
                        prevBlock: hex"00000000000000000006ff7fe98d6da7cc7af77afe27a1d83ae17d4a4af3e254",
                        merkleRoot: hex"f09f9736ab073f80f014a03e68c2409cd16a3d5f43f512638e6b67131d7f7c9b",
                        timestamp: 1553387053,
                        nBits: hex"17612e17",
                        nonce: hex"749cdf0c",
                        difficulty: 6068891541676,
                        blockHex: hex"0000002054e2f34a4a7de13ad8a127fe7af77acca76d8de97fff06000000000000000000f09f9736ab073f80f014a03e68c2409cd16a3d5f43f512638e6b67131d7f7c9b2dce965c17612e17749cdf0c",
                        height: 568511
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000001debd424683ee6c16b05a441309f96925dad309af03e80",
                        version: 536870912,
                        prevBlock: hex"0000000000000000001ccf7aa37a7f07e4d709eef9c6c4abd0b808686b14c314",
                        merkleRoot: hex"68149a62b93c2c9f91fbaa2973ca1b79ba11fc5ee8c6cce9f01861e8ad02cd82",
                        timestamp: 1553387093,
                        nBits: hex"6c1f2c17",
                        nonce: hex"77fabf78",
                        difficulty: 6379265451411,
                        blockHex: hex"0000002014c3146b6808b8d0abc4c6f9ee09d7e4077f7aa37acf1c00000000000000000068149a62b93c2c9f91fbaa2973ca1b79ba11fc5ee8c6cce9f01861e8ad02cd8255ce965c6c1f2c1777fabf78",
                        height: 568512
                    })
                ],
                output: 6379265451411
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"0000000000000000001debd424683ee6c16b05a441309f96925dad309af03e80",
                        version: 536870912,
                        prevBlock: hex"0000000000000000001ccf7aa37a7f07e4d709eef9c6c4abd0b808686b14c314",
                        merkleRoot: hex"68149a62b93c2c9f91fbaa2973ca1b79ba11fc5ee8c6cce9f01861e8ad02cd82",
                        timestamp: 1553387093,
                        nBits: hex"6c1f2c17",
                        nonce: hex"77fabf78",
                        difficulty: 6379265451411,
                        blockHex: hex"0000002014c3146b6808b8d0abc4c6f9ee09d7e4077f7aa37acf1c00000000000000000068149a62b93c2c9f91fbaa2973ca1b79ba11fc5ee8c6cce9f01861e8ad02cd8255ce965c6c1f2c1777fabf78",
                        height: 568512
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000000de3e7a7711130dbac9fb0a14e5ad6ab72d080182f3321",
                        version: 805257216,
                        prevBlock: hex"000000000000000000078e0449cd368f8b463b3a3585bd8b7d197a23cf547622",
                        merkleRoot: hex"34e7151e2fdaf85bf6751d1281c027b630c481318c3762fa10c318b7f19286e8",
                        timestamp: 1554594090,
                        nBits: hex"6c1f2c17",
                        nonce: hex"3f83f821",
                        difficulty: 6379265451411,
                        blockHex: hex"0040ff2f227654cf237a197d8bbd85353a3b468b8f36cd49048e0700000000000000000034e7151e2fdaf85bf6751d1281c027b630c481318c3762fa10c318b7f19286e82a39a95c6c1f2c173f83f821",
                        height: 570527
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000000000000d4833adbfb465d4cfb57c2918b830db228cf1b217d99f",
                        version: 541065216,
                        prevBlock: hex"0000000000000000000de3e7a7711130dbac9fb0a14e5ad6ab72d080182f3321",
                        merkleRoot: hex"71b3a61247a4cf6b892055f278247f33d76fa90b48c76fda69f583268cb965f8",
                        timestamp: 1554594223,
                        nBits: hex"1d072c17",
                        nonce: hex"0022062d",
                        difficulty: 6393023717201,
                        blockHex: hex"0000402021332f1880d072abd65a4ea1b09facdb301171a7e7e30d00000000000000000071b3a61247a4cf6b892055f278247f33d76fa90b48c76fda69f583268cb965f8af39a95c1d072c170022062d",
                        height: 570528
                    })
                ],
                output: 6393023717201
            }),
            RetargetAlgorithmTest({
                input: [
                    BlockHeader({
                        blockHash: hex"0000000002216521d1a33de5bf19b3f8966395fbc81be449e2b2f1bdab2bd88f",
                        version: 0,
                        prevBlock: hex"0000000000d14af55c4eae0121184919baba2deb8bf89c3af6b8e4c4f35c8e4e",
                        merkleRoot: hex"6bac1a25fa61b6e183880764cdb67bf1e56e10149408d87b0d2b11e844232a9f",
                        timestamp: 1279008237,
                        nBits: hex"f4a3051c",
                        nonce: hex"4dcd2b02",
                        difficulty: 45,
                        blockHex: hex"010000004e8e5cf3c4e4b8f63a9cf88beb2dbaba1949182101ae4e5cf54ad100000000009f2a2344e8112b0d7bd8089414106ee5f17bb6cd64078883e1b661fa251aac6bed1d3c4cf4a3051c4dcd2b02",
                        height: 66528
                    }),
                    BlockHeader({
                        blockHash: hex"000000000050aa3223d06ff9bea45292aa09c0a6ed5e87959ff88bb9d61fc459",
                        version: 0,
                        prevBlock: hex"00000000053a2071014efc03941f023c805237ceee21a54c6c9425cb881d321e",
                        merkleRoot: hex"50af9f152114dd04016d45df95546f3dce8aebd9263a5a8a841404b5f8577031",
                        timestamp: 1279011113,
                        nBits: hex"f4a3051c",
                        nonce: hex"73199005",
                        difficulty: 45,
                        blockHex: hex"010000001e321d88cb25946c4ca521eece3752803c021f9403fc4e0171203a0500000000317057f8b50414848a5a3a26d9eb8ace3d6f5495df456d0104dd1421159faf5029293c4cf4a3051c73199005",
                        height: 66543
                    }),
                    BlockHeader({
                        blockHash: hex"0000000000519051eb5f3c5943cdbc176a0eff4e1fbc3e08287bdb76299b8e5c",
                        version: 0,
                        prevBlock: hex"0000000003dfbfa2b33707e691ab2ab7cda7503be2c2cce43d1b21cd1cc757fb",
                        merkleRoot: hex"376043cd8410ca0bcda2408bc6715822ef0ce5b7525d0e885e9268dfd98aa888",
                        timestamp: 1279297779,
                        nBits: hex"fd68011c",
                        nonce: hex"aeb1f801",
                        difficulty: 181,
                        blockHex: hex"01000000fb57c71ccd211b3de4ccc2e23b50a7cdb72aab91e60737b3a2bfdf030000000088a88ad9df68925e880e5d52b7e50cef225871c68b40a2cd0bca1084cd436037f388404cfd68011caeb1f801",
                        height: 68544
                    })
                ],
                output: 181
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            uint firstTimestamp = testCases[i].input[0].timestamp;
            uint secondTimestamp = testCases[i].input[1].timestamp;
            uint previousTarget = instance.extractTarget(testCases[i].input[1].blockHex);
            uint expectedNewTarget = instance.extractTarget(testCases[i].input[2].blockHex);
            uint res = instance.retargetAlgorithm(previousTarget, firstTimestamp, secondTimestamp);
            assertEq(res & expectedNewTarget, expectedNewTarget);

            uint secondTimestamp1 = firstTimestamp + 5 * 2016 * 10 * 60; // longer than 4x
            uint res1 = instance.retargetAlgorithm(previousTarget, firstTimestamp, secondTimestamp1);
            assertEq((res1 / 4) & previousTarget, previousTarget);

            uint secondTimestamp2 = firstTimestamp + 2016 * 10 * 14; // shorter than 1/4x
            uint res2 = instance.retargetAlgorithm(previousTarget, firstTimestamp, secondTimestamp2);
            assertEq((res2 * 4) & previousTarget, previousTarget);      
        }

        // extracts difficulty from a header
        for (uint i = 0; i < testCases.length; i++) {
            uint res1 = instance.extractDifficulty(testCases[i].input[0].blockHex);
            assertEq(res1, testCases[i].input[0].difficulty);

            uint res2 = instance.extractDifficulty(testCases[i].input[1].blockHex);
            assertEq(res2, testCases[i].input[1].difficulty);

            uint res3 = instance.extractDifficulty(testCases[i].input[2].blockHex);
            assertEq(res3, testCases[i].input[2].difficulty);
        }
    }
}
