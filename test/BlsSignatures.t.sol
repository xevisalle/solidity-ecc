// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BlsSignatures, AffinePointG1, OpPointG1} from "../src/BlsSignatures.sol";

contract BlsSignaturesTest is Test {
    using BlsSignatures for AffinePointG1;

    AffinePointG1 P = AffinePointG1({
        x: hex"17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
        y: hex"08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1"
    });

    AffinePointG1 twoP = AffinePointG1({
        x: hex"0572cbea904d67468808c8eb50a9450c9721db309128012543902d0ac358a62ae28f75bb8f1c7c42c39a8c5529bf0f4e",
        y: hex"166a9d8cabc673a322fda673779d8e3822ba3ecb8670e461f73bb9021d5fd76a4c56d9d4cd16bd1bba86881979749d28"
    });

    AffinePointG1 H = AffinePointG1({
        x: hex"06f5dfd939612467487297f2c115b452b468acc6f024c9631f0e23972fe6e9bad4af11d5862e2d1c0242e60cf110dd5e",
        y: hex"09ebb1ef986871f64866f0ed5237d4c5f0da0e53de6aa8438a5254dea424679a1d050e7116402ad16170db5d80a777af"
    });

    function test_Addition() public view {
        OpPointG1 memory opP = P.toOp();
        OpPointG1 memory opTwoP = twoP.toOp();

        OpPointG1 memory sum = BlsSignatures.addG1(opP, opP);
        assert(keccak256(opTwoP.xy) == keccak256(sum.xy));
    }

    function test_ScalarMultiplication() public view {
        OpPointG1 memory opP = P.toOp();
        OpPointG1 memory opTwoP = twoP.toOp();

        bytes memory x = hex"0000000000000000000000000000000000000000000000000000000000000002";

        OpPointG1 memory mul = BlsSignatures.mulG1(x, opP);
        assert(keccak256(opTwoP.xy) == keccak256(mul.xy));

        OpPointG1 memory mulGen = BlsSignatures.mulG1Gen(x);
        assert(keccak256(opTwoP.xy) == keccak256(mulGen.xy));
    }

    function test_HashToCurve() public view {
        bytes memory message = abi.encodePacked(uint256(12345678));
        bytes memory truncated = hex"1e0fc0f9ab0fb4020573d77cf2abf68a53d8d7361ad5c79feb6a9e50244bef2a";

        assert(keccak256(truncated) == keccak256(BlsSignatures.truncatedHash(message)));
        assert(keccak256(H.toOp().xy) == keccak256(BlsSignatures.hashToCurve(message).xy));
    }
}
