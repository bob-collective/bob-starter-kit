pragma solidity ^0.8.4;

import {BTCUtils} from "./BTCUtils.sol";
import {BytesLib} from "./BytesLib.sol";

library SegWitUtils {
    using BTCUtils for bytes;
    using BytesLib for bytes;

    bytes6 public constant WITNESS_MAGIC_BYTES = hex"6a24aa21a9ed";
    uint256 public constant COINBASE_WITNESS_PK_SCRIPT_LENGTH = 38;

    function isWitnessCommitment(bytes memory pkScript) internal pure returns (bool) {
        return pkScript.length >= COINBASE_WITNESS_PK_SCRIPT_LENGTH && bytes6(pkScript.slice32(0)) == WITNESS_MAGIC_BYTES;
    }

    // https://github.com/btcsuite/btcd/blob/80f5a0ffdf363cfff27d550f9e38aa262667a7f1/blockchain/merkle.go#L192
    function extractWitnessCommitment(bytes memory _vout) internal pure returns (bytes32) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = _vout.parseVarInt();
        require(_varIntDataLen != BTCUtils.ERR_BAD_ARG, "Read overrun during VarInt parsing");

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _nOuts; _i ++) {
            _len = _vout.determineOutputLengthAt(_offset);
            require(_len != BTCUtils.ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
            bytes memory _output = _vout.slice(_offset, _len);
            if (_output[8] == hex"26") {
                // skip 8-byte value
                bytes memory _pkScript = _output.slice(9, COINBASE_WITNESS_PK_SCRIPT_LENGTH);
                if (isWitnessCommitment(_pkScript)) {
                    return bytes32(_pkScript.slice(
                        WITNESS_MAGIC_BYTES.length,
                        COINBASE_WITNESS_PK_SCRIPT_LENGTH - WITNESS_MAGIC_BYTES.length
                    ));
                }
            }
            _offset += _len;
        }

        return hex"";
    }
}