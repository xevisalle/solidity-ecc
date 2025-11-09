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

    // The generator of G1
    bytes constant G1_GEN =
        hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";

    /**
     * @dev Converts a point from affine to operation form
     */
    function toOp(AffinePointG1 memory P) internal pure returns (OpPointG1 memory) {
        return OpPointG1({xy: bytes.concat(ZERO, P.x, ZERO, P.y)});
    }

    /**
     * @dev Hashes a given message and outputs a Keccak256 digest, with 2 bits truncated.
     */
    function truncatedHash(bytes memory message) internal pure returns (bytes memory) {
        return abi.encode(uint256(keccak256(message)) & (uint256(1) << (254)) - 1);
    }

    /**
     * @dev Hashes a given message to the curve's G1, using the truncatedHash() method.
     */
    function hashToCurve(bytes memory message) internal view returns (OpPointG1 memory) {
        bytes memory hash = truncatedHash(message);
        return mulG1Gen(hash);
    }

    /**
     * @dev Adds two G1 points.
     */
    function addG1(OpPointG1 memory P, OpPointG1 memory Q) internal view returns (OpPointG1 memory) {
        (bool success, bytes memory sum) = address(0x0b).staticcall(bytes.concat(P.xy, Q.xy));
        require(success, "BLS12-381 G1 addition failed.");

        return OpPointG1({xy: sum});
    }

    /**
     * @dev Multiplies a scalar by a G1 point.
     */
    function mulG1(bytes memory x, OpPointG1 memory P) internal view returns (OpPointG1 memory) {
        (bool success, bytes memory mul) = address(0x0c).staticcall(bytes.concat(P.xy, x));
        require(success, "BLS12-381 G1 scalar multiplication failed.");

        return OpPointG1({xy: mul});
    }

    /**
     * @dev Multiplies a scalar by the G1 generator.
     */
    function mulG1Gen(bytes memory x) internal view returns (OpPointG1 memory) {
        (bool success, bytes memory mul) = address(0x0c).staticcall(bytes.concat(G1_GEN, x));
        require(success, "BLS12-381 G1 scalar multiplication failed.");

        return OpPointG1({xy: mul});
    }
}
