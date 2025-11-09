// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev A BLS G1 Point in affine form.
 */
struct AffinePointG1 {
    bytes x;
    bytes y;
}

/**
 * @dev A BLS G1 Point in serialized affine form, meant as input for precompile operations.
 */
struct OpPointG1 {
    bytes xy;
}

/**
 * @author xevisalle
 * @title BlsSignatures
 * @dev Implementation of BLS signatures, instantiated with the parameters of
 * the BLS12-381 curve.
 *
 * Ref: https://www.iacr.org/archive/asiacrypt2001/22480516.pdf
 */
library BlsSignatures {
    // Amount of bytes set to zero used for converting affine points to operation form
    bytes constant ZERO = new bytes(16);

    /**
     * @dev Converts a point from affine to operation form
     */
    function toOp(AffinePointG1 memory P) internal pure returns (OpPointG1 memory) {
        return OpPointG1({xy: bytes.concat(ZERO, P.x, ZERO, P.y)});
    }

    /**
     * @dev Adds two G1 points.
     */
    function addG1(OpPointG1 memory P, OpPointG1 memory Q) internal view returns (OpPointG1 memory) {
        (bool success, bytes memory sum) = address(0x0b).staticcall(bytes.concat(P.xy, Q.xy));
        require(success, "BLS12-381 G1 addition failed.");

        return OpPointG1({xy: sum});
    }
}
