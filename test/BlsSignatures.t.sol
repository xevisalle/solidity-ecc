// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BlsSignatures, AffinePointG1, OpPointG1} from "../src/BlsSignatures.sol";

contract BlsSignaturesTest is Test {
    using BlsSignatures for AffinePointG1;

    function test_Addition() public view {
        AffinePointG1 memory P = AffinePointG1({
            x: hex"17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
            y: hex"08b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1"
        });

        AffinePointG1 memory twoP = AffinePointG1({
            x: hex"0572cbea904d67468808c8eb50a9450c9721db309128012543902d0ac358a62ae28f75bb8f1c7c42c39a8c5529bf0f4e",
            y: hex"166a9d8cabc673a322fda673779d8e3822ba3ecb8670e461f73bb9021d5fd76a4c56d9d4cd16bd1bba86881979749d28"
        });

        OpPointG1 memory opP = P.toOp();
        OpPointG1 memory opTwoP = twoP.toOp();

        OpPointG1 memory sum = BlsSignatures.addG1(opP, opP);
        assert(keccak256(opTwoP.xy) == keccak256(sum.xy));
    }
}
