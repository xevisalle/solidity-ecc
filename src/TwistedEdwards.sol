// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev A twisted Edwards Point in affine form.
 */
struct AffinePoint {
    uint256 x;
    uint256 y;
}

/**
 * @dev A twisted Edwards Point in extended form.
 */
struct ExtendedPoint {
    uint256 x;
    uint256 y;
    uint256 t;
    uint256 z;
}

/**
 * @author xevisalle
 * @title TwistedEdwards
 * @dev Implementation of twisted Edwards elliptic curves, instantiated with the parameters of
 * the Jubjub curve.
 *
 * Ref: https://eprint.iacr.org/2008/522.pdf
 *
 * IMPORTANT: this library is work in progress, at the moment there is not checks on the input
 * points, i.e. they might not be on the curve.
 */
library TwistedEdwards {
    // prime mod q
    uint256 constant q = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;

    // constants a and d
    uint256 constant a = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000000;
    uint256 constant d = 0x2a9318e74bfa2b48f5fd9207e6bd7fd4292d7f6d37579d2601065fd6d6343eb1;

    // generator
    uint256 constant G_X = 0x3fd2814c43ac65a6f1fbf02d0fd6cce62e3ebb21fd6c54ed4df7b7ffec7beaca;
    uint256 constant G_Y = 0x0000000000000000000000000000000000000000000000000000000000000012;

    // identity point
    uint256 constant I_X = 0;
    uint256 constant I_Y = 1;

    /**
     * @dev Converts an AffinePoint to an ExtendedPoint
     */
    function toExtended(AffinePoint memory P) internal pure returns (ExtendedPoint memory) {
        return ExtendedPoint({x: P.x, y: P.y, t: mulmod(P.x, P.y, q), z: 1});
    }

    /**
     * @dev Converts an ExtendedPoint to an AffinePoint
     */
    function toAffine(ExtendedPoint memory P) internal view returns (AffinePoint memory) {
        uint256 zInv = invPrimeMod(P.z, q);
        return AffinePoint({x: mulmod(P.x, zInv, q), y: mulmod(P.y, zInv, q)});
    }

    /**
     * @dev Compares two points in their extended form
     */
    function cmp(ExtendedPoint memory P, ExtendedPoint memory Q) internal pure returns (bool) {
        uint256 c1 = mulmod(P.x, Q.z, q);
        uint256 c2 = mulmod(Q.x, P.z, q);
        uint256 c3 = mulmod(P.y, Q.z, q);
        uint256 c4 = mulmod(Q.y, P.z, q);

        return (c1 == c2 && c3 == c4);
    }

    /**
     * @dev Addition of two extended points. Given two points P and Q where P.z != 0 and Q.z != 0,
     * we perform the unified addition by setting Q.z = 1. That way, we perform the addition
     * with 8 multiplications + 2 multiplications by curve constants.
     */
    function add(ExtendedPoint memory P, ExtendedPoint memory Q) internal pure returns (ExtendedPoint memory R) {
        uint256 A = mulmod(P.x, Q.x, q);
        uint256 B = mulmod(P.y, Q.y, q);
        uint256 C = mulmod(d, mulmod(P.t, Q.t, q), q);
        // D = P.z

        uint256 E_ = mulmod(addmod(P.x, P.y, q), addmod(Q.x, Q.y, q), q);
        uint256 E = addmod(E_, addmod(q - A, q - B, q), q);
        uint256 F = addmod(P.z, q - C, q);
        uint256 G = addmod(P.z, C, q);
        uint256 H = addmod(B, q - mulmod(a, A, q), q);

        R.x = mulmod(E, F, q);
        R.y = mulmod(G, H, q);
        R.t = mulmod(E, H, q);
        R.z = mulmod(F, G, q);
    }

    /**
     * @dev Addition of two different extended points. Given two points P and Q where P.z != 0 and
     * Q.z != 0, we perform the dedicated addition by setting Q.z = 1. That way, we perform the
     * addition with 8 multiplications + 1 multiplication by a curve constant. It's important
     * to note that this function must be used only when we are certain that both points to be
     * added are distinct.
     */
    function addDiff(ExtendedPoint memory P, ExtendedPoint memory Q) internal pure returns (ExtendedPoint memory R) {
        uint256 A = mulmod(P.x, Q.x, q);
        uint256 B = mulmod(P.y, Q.y, q);
        uint256 C = mulmod(P.z, Q.t, q);
        // D = P.t

        uint256 E = addmod(P.t, C, q);
        uint256 F_ = mulmod(addmod(P.x, q - P.y, q), addmod(Q.x, Q.y, q), q);
        uint256 F = addmod(F_, addmod(B, q - A, q), q);
        uint256 G = addmod(B, mulmod(a, A, q), q);
        uint256 H = addmod(P.t, q - C, q);

        R.x = mulmod(E, F, q);
        R.y = mulmod(G, H, q);
        R.t = mulmod(E, H, q);
        R.z = mulmod(F, G, q);
    }

    /**
     * @dev Doubles an ExtendedPoint. Given a point P where P.z != 0, we perform the dedicated
     * doubling with 4 multiplications, 4 squarings, and 1 multiplication by a curve constant.
     */
    function double(ExtendedPoint memory P) internal pure returns (ExtendedPoint memory R) {
        uint256 A = mulmod(P.x, P.x, q);
        uint256 B = mulmod(P.y, P.y, q);
        uint256 C = mulmod(2, mulmod(P.z, P.z, q), q);
        uint256 D = mulmod(a, A, q);

        uint256 E_ = addmod(P.x, P.y, q);
        uint256 E = addmod(addmod(mulmod(E_, E_, q), q - A, q), q - B, q);
        uint256 G = addmod(D, B, q);
        uint256 F = addmod(G, q - C, q);
        uint256 H = addmod(D, q - B, q);

        R.x = mulmod(E, F, q);
        R.y = mulmod(G, H, q);
        R.t = mulmod(E, H, q);
        R.z = mulmod(F, G, q);
    }

    /**
     * @dev Subtracts a point P from another point Q
     */
    function sub(ExtendedPoint memory P, ExtendedPoint memory Q) internal pure returns (ExtendedPoint memory) {
        return add(P, ExtendedPoint({x: q - Q.x, y: Q.y, t: q - Q.t, z: Q.z}));
    }

    /**
     * @dev Compute the modular inverse of a value x, given a prime mod p
     */
    function invPrimeMod(uint256 x, uint256 p) internal view returns (uint256 inv) {
        assembly {
            let ptr := mload(0x40)

            mstore(ptr, 0x20)
            mstore(add(ptr, 0x20), 0x20)
            mstore(add(ptr, 0x40), 0x20)
            mstore(add(ptr, 0x60), x)
            mstore(add(ptr, 0x80), sub(p, 2))
            mstore(add(ptr, 0xa0), p)

            // Call to precompile 0x05
            if iszero(staticcall(not(0), 0x05, ptr, 0xc0, ptr, 0x20)) {
                revert(0, 0)
            }
            inv := mload(ptr)
        }
    }
}
