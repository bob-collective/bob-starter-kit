// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {ValidateSPVScript} from "../script/ValidateSPV.s.sol";

contract ValidateSPVTest is Test {
    ValidateSPVScript public instance;

    function setUp() public {
        instance = new ValidateSPVScript();
    }

    function test_TheConstantGettersForThatSweetSweetCoverage() public {
        bytes memory getErrBadLengthOutput = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        uint256 res1 = instance.getErrBadLength();
        assertEq(res1, uint(bytes32(getErrBadLengthOutput)));

        bytes memory getErrInvalidChainOutput = hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe";
        uint256 res2 = instance.getErrInvalidChain();
        assertEq(res2, uint(bytes32(getErrInvalidChainOutput)));

        bytes memory getErrLowWorkOutput = hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd";
        uint256 res3 = instance.getErrLowWork();
        assertEq(res3, uint(bytes32(getErrLowWorkOutput)));
    }

    struct ProveTest {
        bytes32 inputTxIdLE;
        bytes32 inputMerkleRootLE;
        bytes inputProof;
        uint inputIndex;
        bool output;
    }

    function test_ReturnsTrueIfProofIsValid() public {
        ProveTest[3] memory testCases = [
            ProveTest({
                inputTxIdLE: hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6",
                inputMerkleRootLE: hex"0296ef123ea96da5cf695f22bf7d94be87d49db1ad7ac371ac43c4da4161c8c2",
                inputProof: hex"e35a0d6de94b656694589964a252957e4673a9fb1d2f8b4a92e3f0a7bb654fddb94e5a1e6d7f7f499fd1be5dd30a73bf5584bf137da5fdd77cc21aeb95b9e35788894be019284bd4fbed6dd6118ac2cb6d26bc4be4e423f55a3a48f2874d8d02a65d9c87d07de21d4dfe7b0a9f4a23cc9a58373e9e6931fefdb5afade5df54c91104048df1ee999240617984e18b6f931e2373673d0195b8c6987d7ff7650d5ce53bcec46e13ab4f2da1146a7fc621ee672f62bc22742486392d75e55e67b09960c3386a0b49e75f1723d6ab28ac9a2028a0c72866e2111d79d4817b88e17c821937847768d92837bae3832bb8e5a4ab4434b97e00a6c10182f211f592409068d6f5652400d9a3d1cc150a7fb692e874cc42d76bdafc842f2fe0f835a7c24d2d60c109b187d64571efbaa8047be85821f8e67e0e85f2f5894bc63d00c2ed9d64",
                inputIndex: 281,
                output: true
            }),
            ProveTest({
                inputTxIdLE: hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6",
                inputMerkleRootLE: hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6",
                inputProof: hex"",
                inputIndex: 0,
                output: true
            }),
            ProveTest({
                inputTxIdLE: hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6",
                inputMerkleRootLE: hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6",
                inputProof: hex"e35a0d6de94b656694589964a252957e4673a9fb1d2f8b4a92e3f0a7bb654fddb94e5a1e6d7f7f499fd1be5dd30a73bf5584bf137da5fdd77cc21aeb95b9e35788894be019284bd4fbed6dd6118ac2cb6d26bc4be4e423f55a3a48f2874d8d02a65d9c87d07de21d4dfe7b0a9f4a23cc9a58373e9e6931fefdb5afade5df54c91104048df1ee999240617984e18b6f931e2373673d0195b8c6987d7ff7650d5ce53bcec46e13ab4f2da1146a7fc621ee672f62bc22742486392d75e55e67b09960c3386a0b49e75f1723d6ab28ac9a2028a0c72866e2111d79d4817b88e17c821937847768d92837bae3832bb8e5a4ab4434b97e00a6c10182f211f592409068d6f5652400d9a3d1cc150a7fb692e874cc42d76bdafc842f2fe0f835a7c24d2d60c109b187d64571efbaa8047be85821f8e67e0e85f2f5894bc63d00c2ed9d64",
                inputIndex: 0,
                output: false
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.prove(
                testCases[i].inputTxIdLE,
                testCases[i].inputMerkleRootLE,
                testCases[i].inputProof,
                testCases[i].inputIndex
            );
            assertEq(res, testCases[i].output);
        }
    }

    function test_ReturnsTheTransactionHash() public {
        bytes4 version = hex"01000000";
        bytes memory vin = hex"011746bd867400f3494b8f44c24b83e1aa58c4f0ff25b4a61cffeffd4bc0f9ba300000000000ffffffff";
        bytes memory vout = hex"024897070000000000220020a4333e5612ab1a1043b25755c89b16d55184a42f81799e623e6bc39db8539c180000000000000000166a14edb1b5c2f39af0fec151732585b1049b07895211";
        bytes4 locktime = hex"00000000";

        bytes32 output = hex"48e5a1a0e616d8fd92b4ef228c424e0c816799a256c6a90892195ccfc53300d6";

        bytes32 res = instance.calculateTxId(version, vin, vout, locktime);
        assertEq(res, output);
    }

    function test_ReturnsTrueIfHeaderChainIsValid() public {
        bytes memory input = hex"0000002073bd2184edd9c4fc76642ea6754ee40136970efc10c4190000000000000000000296ef123ea96da5cf695f22bf7d94be87d49db1ad7ac371ac43c4da4161c8c216349c5ba11928170d38782b00000020fe70e48339d6b17fbbf1340d245338f57336e97767cc240000000000000000005af53b865c27c6e9b5e5db4c3ea8e024f8329178a79ddb39f7727ea2fe6e6825d1349c5ba1192817e2d9515900000020baaea6746f4c16ccb7cd961655b636d39b5fe1519b8f15000000000000000000c63a8848a448a43c9e4402bd893f701cd11856e14cbbe026699e8fdc445b35a8d93c9c5ba1192817b945dc6c00000020f402c0b551b944665332466753f1eebb846a64ef24c71700000000000000000033fc68e070964e908d961cd11033896fa6c9b8b76f64a2db7ea928afa7e304257d3f9c5ba11928176164145d0000ff3f63d40efa46403afd71a254b54f2b495b7b0164991c2d22000000000000000000f046dc1b71560b7d0786cfbdb25ae320bd9644c98d5c7c77bf9df05cbe96212758419c5ba1192817a2bb2caa00000020e2d4f0edd5edd80bdcb880535443747c6b22b48fb6200d0000000000000000001d3799aa3eb8d18916f46bf2cf807cb89a9b1b4c56c3f2693711bf1064d9a32435429c5ba1192817752e49ae0000002022dba41dff28b337ee3463bf1ab1acf0e57443e0f7ab1d000000000000000000c3aadcc8def003ecbd1ba514592a18baddddcd3a287ccf74f584b04c5c10044e97479c5ba1192817c341f595";
        uint output = 49134394618239;

        uint res = instance.validateHeaderChain(input);
        assertEq(res, output);
    }

    struct ValidateHeaderChainErrorTest {
        bytes input;
        bytes32 errorValue;
    }

    function test_ReturnsErrorIfHeaderChainIsInvalid() public {
        ValidateHeaderChainErrorTest[3] memory testCases = [
            ValidateHeaderChainErrorTest({
                input: hex"00002073bd2184edd9c4fc76642ea6754ee40136970efc10c4190000000000000000000296ef123ea96da5cf695f22bf7d94be87d49db1ad7ac371ac43c4da4161c8c216349c5ba11928170d38782b00000020fe70e48339d6b17fbbf1340d245338f57336e97767cc240000000000000000005af53b865c27c6e9b5e5db4c3ea8e024f8329178a79ddb39f7727ea2fe6e6825d1349c5ba1192817e2d9515900000020baaea6746f4c16ccb7cd961655b636d39b5fe1519b8f15000000000000000000c63a8848a448a43c9e4402bd893f701cd11856e14cbbe026699e8fdc445b35a8d93c9c5ba1192817b945dc6c00000020f402c0b551b944665332466753f1eebb846a64ef24c71700000000000000000033fc68e070964e908d961cd11033896fa6c9b8b76f64a2db7ea928afa7e304257d3f9c5ba11928176164145d0000ff3f63d40efa46403afd71a254b54f2b495b7b0164991c2d22000000000000000000f046dc1b71560b7d0786cfbdb25ae320bd9644c98d5c7c77bf9df05cbe96212758419c5ba1192817a2bb2caa00000020e2d4f0edd5edd80bdcb880535443747c6b22b48fb6200d0000000000000000001d3799aa3eb8d18916f46bf2cf807cb89a9b1b4c56c3f2693711bf1064d9a32435429c5ba1192817752e49ae0000002022dba41dff28b337ee3463bf1ab1acf0e57443e0f7ab1d000000000000000000c3aadcc8def003ecbd1ba514592a18baddddcd3a287ccf74f584b04c5c10044e97479c5ba1192817c341f595",
                errorValue: hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
            }),
            ValidateHeaderChainErrorTest({
                input: hex"0000002073bd2184edd9c4fc76642ea6754ee40136970efc10c4190000000000000000000296ef123ea96da5cf695f22bf7d94be87d49db1ad7ac371ac43c4da4161c8c216349c5ba11928170d38782b0000002073bd2184edd9c4fc76642ea6754ee40136970efc10c4190000000000000000005af53b865c27c6e9b5e5db4c3ea8e024f8329178a79ddb39f7727ea2fe6e6825d1349c5ba1192817e2d951590000002073bd2184edd9c4fc76642ea6754ee40136970efc10c419000000000000000000c63a8848a448a43c9e4402bd893f701cd11856e14cbbe026699e8fdc445b35a8d93c9c5ba1192817b945dc6c00000020f402c0b551b944665332466753f1eebb846a64ef24c71700000000000000000033fc68e070964e908d961cd11033896fa6c9b8b76f64a2db7ea928afa7e304257d3f9c5ba11928176164145d0000ff3f63d40efa46403afd71a254b54f2b495b7b0164991c2d22000000000000000000f046dc1b71560b7d0786cfbdb25ae320bd9644c98d5c7c77bf9df05cbe96212758419c5ba1192817a2bb2caa00000020e2d4f0edd5edd80bdcb880535443747c6b22b48fb6200d0000000000000000001d3799aa3eb8d18916f46bf2cf807cb89a9b1b4c56c3f2693711bf1064d9a32435429c5ba1192817752e49ae0000002022dba41dff28b337ee3463bf1ab1acf0e57443e0f7ab1d000000000000000000c3aadcc8def003ecbd1ba514592a18baddddcd3a287ccf74f584b04c5c10044e97479c5ba1192817c341f595",
                errorValue: hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe"
            }),
            ValidateHeaderChainErrorTest({
                input: hex"bbbbbbbb7777777777777777777777777777777777777777777777777777777777777777e0e333d0fd648162d344c1a760a319f2184ab2dce1335353f36da2eea155f97fccccccccffff001fe85f0000bbbbbbbbcbee0f1f713bdfca4aa550474f7f252581268935ef8948f18d48ec0a2b4800008888888888888888888888888888888888888888888888888888888888888888ccccccccffff001f01440000bbbbbbbbfe6c72f9b42e11c339a9cbe1185b2e16b74acce90c8316f4a5c8a6c0a10f00008888888888888888888888888888888888888888888888888888888888888888dcccccccffff001f30340000",
                errorValue: hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd"
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            uint256 res = instance.validateHeaderChain(testCases[i].input);
            assertEq(res, uint256(testCases[i].errorValue));


            // Execute within Tx to measure gas amount
            instance.validateHeaderChainTx(testCases[i].input);
        }
    }

    struct ValidateHeaderWorkTest {
        bytes32 inputDigest;
        bytes32 inputTarget;
        bool output;
    }

    function test_ReturnsFalseOnAnEmptyDigest() public {
        ValidateHeaderWorkTest[3] memory testCases = [
            ValidateHeaderWorkTest({
                inputDigest: hex"0000000000000000000000000000000000000000000000000000000000000000",
                inputTarget: hex"0000000000000000000000000000000000000000000000000000000000000001",
                output: false
            }),
            ValidateHeaderWorkTest({
                inputDigest: hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
                inputTarget: hex"0000000000000000000000000000000000000000000000000000000000000001",
                output: false
            }),
            ValidateHeaderWorkTest({
                inputDigest: hex"fe70e48339d6b17fbbf1340d245338f57336e97767cc24000000000000000000",
                inputTarget: hex"0000000000000000002819a10000000000000000000000000000000000000000",
                output: true
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.validateHeaderWork(
                testCases[i].inputDigest,
                uint256(testCases[i].inputTarget)
            );
            assertEq(res, testCases[i].output);
        }
    }

    struct ValidateHeaderPrevHashTest {
        bytes inputHeader;
        bytes32 inputPrevHash;
        bool output;
    }

    function test_ReturnsTrueIfHeaderPrevHashIsValid() public {
        ValidateHeaderPrevHashTest[2] memory testCases = [
            ValidateHeaderPrevHashTest({
                inputHeader: hex"00000020fe70e48339d6b17fbbf1340d245338f57336e97767cc240000000000000000005af53b865c27c6e9b5e5db4c3ea8e024f8329178a79ddb39f7727ea2fe6e6825d1349c5ba1192817e2d95159",
                inputPrevHash: hex"fe70e48339d6b17fbbf1340d245338f57336e97767cc24000000000000000000",
                output: true
            }),
            ValidateHeaderPrevHashTest({
                inputHeader: hex"00000020fe70e48339d6b17fbbf1340d245338f57336e97767cc240000000000000000005af53b865c27c6e9b5e5db4c3ea8e024f8329178a79ddb39f7727ea2fe6e6825d1349c5ba1192817e2d95159",
                inputPrevHash: hex"baaea6746f4c16ccb7cd961655b636d39b5fe1519b8f15000000000000000000",
                output: false
            })
        ];

        for (uint i = 0; i < testCases.length; i++) {
            bool res = instance.validateHeaderPrevHash(
                testCases[i].inputHeader,
                testCases[i].inputPrevHash
            );
            assertEq(res, testCases[i].output);
        }
    }
}