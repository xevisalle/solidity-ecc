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
 * @dev A BLS G2 Point in affine form.
 */
struct AffinePointG2 {
    bytes x1;
    bytes x2;
    bytes y1;
    bytes y2;
}

/**
 * @dev A BLS G1 Point in serialized affine form, meant as input for precompile operations.
 */
struct OpPointG1 {
    bytes xy;
}

/**
 * @dev A BLS G2 Point in serialized affine form, meant as input for precompile operations.
 */
struct OpPointG2 {
    bytes xxyy;
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

    // Field mod
    bytes constant FIELD_MOD =
        hex"1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab";

    // The generator of G1
    bytes constant G1_GEN =
        hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";

    // The generator of G2
    bytes constant G2_GEN =
        hex"00000000000000000000000000000000024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80000000000000000000000000000000013e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e000000000000000000000000000000000ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801000000000000000000000000000000000606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be";

    /**
     * @dev Converts a point from affine to operation form
     */
    function toOp(AffinePointG1 memory P) internal pure returns (OpPointG1 memory) {
        return OpPointG1({xy: bytes.concat(ZERO, P.x, ZERO, P.y)});
    }

    /**
     * @dev Converts a point from affine to G2 operation form
     */
    function toOpG2(AffinePointG2 memory P) internal pure returns (OpPointG2 memory) {
        return OpPointG2({xxyy: bytes.concat(ZERO, P.x1, ZERO, P.x2, ZERO, P.y1, ZERO, P.y2)});
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

    /**
     * @dev Negates a G1 point.
     */
    function negG1(AffinePointG1 memory P) public pure returns (AffinePointG1 memory) {
        bytes memory res = new bytes(P.y.length);
        uint256 borrow = 0;

        for (uint256 i = P.y.length; i > 0; i--) {
            uint256 ai = uint8(FIELD_MOD[i - 1]);
            uint256 bi = uint8(P.y[i - 1]);

            uint256 f;
            if (ai >= bi + borrow) {
                f = ai - bi - borrow;
                borrow = 0;
            } else {
                f = 256 + ai - bi - borrow;
                borrow = 1;
            }

            res[i - 1] = bytes1(uint8(f));
        }

        return AffinePointG1({x: P.x, y: res});
    }

    /**
     * @dev Verifies a signature given the message and the public key.
     */
    function verifySignature(OpPointG2 memory pk, bytes memory message, AffinePointG1 memory sig)
        internal
        view
        returns (bool)
    {
        OpPointG1 memory hash = BlsSignatures.hashToCurve(message);
        OpPointG1 memory sigNeg = toOp(negG1(sig));

        (bool success, bytes memory pairing) =
            address(0x0f).staticcall(bytes.concat(sigNeg.xy, G2_GEN, hash.xy, pk.xxyy));
        require(success, "BLS12-381 pairing failed.");

        return pairing[31] == bytes1(0x01);
    }
}
