// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {Test, console2} from "forge-std/Test.sol";
import {CheckBitcoinSigsScript} from "../script/CheckBitcoinSigs.s.sol";

contract CheckBitcoinSigsTest is Test {
    CheckBitcoinSigsScript public instance;

    bytes32 constant EMPTY = hex'0000000000000000000000000000000000000000000000000000000000000000';

    function setUp() public {
        instance = new CheckBitcoinSigsScript();
    }

    bytes pubkey = hex'4f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa385b6b1b8ead809ca67454d9683fcf2ba03456d6fe2c4abe2b07f0fbdbb2f1c1';
    bytes32 digest = hex'02d449a31fbb267c8f352e9968a79e3e5fc95c1bbeaa502fd6454ebde5a4bedc';
    uint8 v = 27;
    bytes32 r = hex'd7e83e8687ba8b555f553f22965c74e81fd08b619a7337c5c16e4b02873b537e';
    bytes32 s = hex'633bf745cdf7ae303ca8a6f41d71b2c3a21fcbd1aed9e7ffffa295c08918c1b3';

    // #accountFromPubkey

    function test_GeneratesAnAccountFromAPubkey() public {
        address res = instance.accountFromPubkey(hex'33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333');
        assertEq(res, 0x183671Cd69C7f9a760F9f1c59393Df69e893e557);
    }

    function test_ErrorsIfTheInputLengthIsWrong() public {
        vm.expectRevert("Pubkey must be 64-byte raw, uncompressed key.");
        instance.accountFromPubkey(hex'33');
    }

    // #p2wpkhFromPubkey

    bytes uncompressed = hex'3c72addb4fdf09af94f0c94d7fe92a386a7e70cf8a1d85916386bb2535c7b1b13b306b0fe085665d8fc1b28ae1676cd3ad6e08eaeda225fe38d0da4de55703e0';
    bytes compressed = hex'023c72addb4fdf09af94f0c94d7fe92a386a7e70cf8a1d85916386bb2535c7b1b1';
    bytes prefixedUncompressed = hex'043c72addb4fdf09af94f0c94d7fe92a386a7e70cf8a1d85916386bb2535c7b1b13b306b0fe085665d8fc1b28ae1676cd3ad6e08eaeda225fe38d0da4de55703e0';
    bytes outputScript = hex'00143bc28d6d92d9073fb5e3adf481795eaf446bceed';

    function test_HandlesUnprefixedUncompressedKeys() public {
        bytes memory res = instance.p2wpkhFromPubkey(uncompressed);
        assertEq(res, outputScript);
    }

    function test_HandlesPrefixedUncompressedKeys() public {
        bytes memory res = instance.p2wpkhFromPubkey(prefixedUncompressed);
        assertEq(res, outputScript);
    }

    function test_HandleCompressedKeys() public {
        bytes memory res = instance.p2wpkhFromPubkey(compressed);
        assertEq(res, outputScript);
    }

    function test_ErrorsOnNonStandardKeyFormats() public {
        vm.expectRevert("Witness PKH requires compressed keys");
        instance.p2wpkhFromPubkey(hex'');
    }

    // #checkSig

    // signing the sha 256 of '11' * 32
    // signing with privkey '11' * 32
    // using RFC 6979 nonce (libsecp256k1)
    function test_ValidatesSignatures() public {
        bool res = instance.checkSig(pubkey, digest, v, r, s);
        assertEq(res, true);
    }

    function test_FailsOnBadSignatures() public {
        bool res = instance.checkSig(pubkey, digest, 28, r, s);
        assertEq(res, false);
    }

    function test_SigErrorsOnWeirdPubkeyLengths() public {
        vm.expectRevert("Requires uncompressed unprefixed pubkey");
        instance.checkSig(hex'00', EMPTY, 1, EMPTY, EMPTY);
    }

    // #checkBitcoinSig

    bytes witnessScript = hex'0014fc7250a211deddc70ee5a2738de5f07817351cef';

    function test_ReturnsFalseIfThePubkeyDoesNotMatchTheWitnessScript() public {
        bool res = instance.checkBitcoinSig(hex'00', pubkey, EMPTY, 1, EMPTY, EMPTY);
        assertEq(res, false);
    }

    function test_ReturnsTrueIfTheSignatureIsValidAndMatchesTheScript() public {
        bool res = instance.checkBitcoinSig(witnessScript, pubkey, digest, v, r, s);
        assertEq(res, true);
    }

    function test_ReturnsFalseIfTheSignatureIsInvalid() public {
        bool res = instance.checkBitcoinSig(witnessScript, pubkey, digest, v + 1, r, s);
        assertEq(res, false);
    }

    function test_BitcoinSigErrorsOnWeirdPubkeyLengths() public {
        vm.expectRevert("Requires uncompressed unprefixed pubkey");
        bool res = instance.checkBitcoinSig(hex'00', hex'00', EMPTY, 1, EMPTY, EMPTY);
    }

    // #isSha256Preimage

    function test_IdentifiesSha256Preimages() public {
        assertEq(instance.isSha256Preimage(hex'01', hex'4bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a'), true);
        assertEq(instance.isSha256Preimage(hex'02', hex'dbc1b4c900ffe48d575b5da5c638040125f65db0fe3e24494b76ea986457d986'), true);
        assertEq(instance.isSha256Preimage(hex'03', hex'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'), true);
        assertEq(instance.isSha256Preimage(hex'04', hex'084fed08b978af4d7d196a7446a86b58009e636b611db16211b65a9aadff29c5'), false);
    }

    // #isKeccak256Preimage

    function test_IdentifiesKeccak256Preimages() public {
        assertEq(instance.isKeccak256Preimage(hex'01', hex'5fe7f977e71dba2ea1a68e21057beebb9be2ac30c6410aa38d4f3fbe41dcffd2'), true);
        assertEq(instance.isKeccak256Preimage(hex'02', hex'f2ee15ea639b73fa3db9b34a245bdfa015c260c598b211bf05a1ecc4b3e3b4f2'), true);
        assertEq(instance.isKeccak256Preimage(hex'03', hex'69c322e3248a5dfc29d73c5b0553b0185a35cd5bb6386747517ef7e53b15e287'), true);
        assertEq(instance.isKeccak256Preimage(hex'04', hex'69c322e3248a5dfc29d73c5b0553b0185a35cd5bb6386747517ef7e53b15e287'), false);
    }

    // #oneInputOneOutputSighash

    function test_CalculatesTheSighashOfABizarreTransactionThatForSomeReasonEeNeed() public {
        // the TX produced will be:
        // 01000000000101333333333333333333333333333333333333333333333333333333333333333333333333000000000001111111110000000016001433333333333333333333333333333333333333330000000000
        // the sighash preimage will be:
        // 010000003fc8fd9fada5a3573744477d5e35b0d4d0645e42285e3dec25aac02078db0f838cb9012517c817fead650287d61bdd9c68803b6bf9c64133dcab3e65b5a50cb93333333333333333333333333333333333333333333333333333333333333333333333331976a9145eb9b5e445db673f0ed8935d18cd205b214e518788ac111111111111111100000000e4ca7a168bd64e3123edd7f39e1ab7d670b32311cac2dda8e083822139c7936c0000000001000000
        bytes memory outpoint = hex'333333333333333333333333333333333333333333333333333333333333333333333333';
        bytes20 inputPKH = hex'5eb9b5e445db673f0ed8935d18cd205b214e5187'; // pubkey is '02' + '33'.repeat(32)
        bytes8 inputValue = hex'1111111111111111';
        bytes8 outputValue = hex'1111111100000000';
        bytes20 outputPKH = hex'3333333333333333333333333333333333333333';
        bytes32 sighash = hex'b68a6378ddb770a82ae4779a915f0a447da7d753630f8dd3b00be8638677dd90';

        bytes32 res = instance.oneInputOneOutputSighash(
            outpoint,
            inputPKH,
            inputValue,
            outputValue,
            outputPKH    
        );
        assertEq(res, sighash);
    }
}