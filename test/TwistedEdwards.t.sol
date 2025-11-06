// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TwistedEdwards, AffinePoint, ExtendedPoint} from "../src/TwistedEdwards.sol";

contract TwistedEdwardsTest is Test {
    using TwistedEdwards for ExtendedPoint;
    using TwistedEdwards for AffinePoint;

    uint256 constant TWO_G_X = 0x3406866c17fc106f8654a8c770137476caf3ad858ea04c0c80eee554cba976b4;
    uint256 constant TWO_G_Y = 0x477abd3191d9c67eacd365a062345c7bf59f8a8c277fdbe75ff2d4023d8c2e5f;

    uint256 constant THREE_G_X = 0x4e7d425467582402f3ab723f0a0c86d18c6bd932e32884256ff29ccfc8721673;
    uint256 constant THREE_G_Y = 0x120a54568c3669646e870dd6f278bae1ffa2cfcbb64ca56d4cdcfa0fb390ea65;

    uint256 constant FOUR_G_X = 0x5c04fb190826f2c43a623f7b4927ea8b9e8eacc6eaec84e70cb2050058618cf3;
    uint256 constant FOUR_G_Y = 0x6193d76c552fa2b73ee41cc1d9710d899aeba1cf6db2c547f4b633c64622faa5;

    ExtendedPoint G = AffinePoint({x: TwistedEdwards.G_X, y: TwistedEdwards.G_Y}).toExtended();
    ExtendedPoint I = AffinePoint({x: TwistedEdwards.I_X, y: TwistedEdwards.I_Y}).toExtended();
    ExtendedPoint twoG = AffinePoint({x: TWO_G_X, y: TWO_G_Y}).toExtended();
    ExtendedPoint threeG = AffinePoint({x: THREE_G_X, y: THREE_G_Y}).toExtended();
    ExtendedPoint fourG = AffinePoint({x: FOUR_G_X, y: FOUR_G_Y}).toExtended();

    function test_Addition() public view {
        // 2G = G + G
        ExtendedPoint memory P = G.add(G);
        AffinePoint memory affP = P.toAffine();
        assert(P.cmp(twoG));
        assert(affP.x == TWO_G_X);
        assert(affP.y == TWO_G_Y);

        // 3G = 2G + G
        P = P.add(G);
        affP = P.toAffine();
        assert(P.cmp(threeG));
        assert(affP.x == THREE_G_X);
        assert(affP.y == THREE_G_Y);

        // G = G + I
        P = G.add(I);
        affP = P.toAffine();
        assert(P.cmp(G));
        assert(affP.x == TwistedEdwards.G_X);
        assert(affP.y == TwistedEdwards.G_Y);

        // I = I + I
        P = I.add(I);
        affP = P.toAffine();
        assert(P.cmp(I));
        assert(affP.x == TwistedEdwards.I_X);
        assert(affP.y == TwistedEdwards.I_Y);
    }

    function test_AdditionDiff() public view {
        // 3G = 2G + G
        ExtendedPoint memory P = twoG.addDiff(G);
        AffinePoint memory affP = P.toAffine();
        assert(P.cmp(threeG));
        assert(affP.x == THREE_G_X);
        assert(affP.y == THREE_G_Y);

        // G = G + I
        P = G.addDiff(I);
        affP = P.toAffine();
        assert(P.cmp(G));
        assert(affP.x == TwistedEdwards.G_X);
        assert(affP.y == TwistedEdwards.G_Y);
    }

    function test_Subtraction() public view {
        // I = G - G
        ExtendedPoint memory P = G.sub(G);
        AffinePoint memory affP = P.toAffine();
        assert(P.cmp(I));
        assert(affP.x == TwistedEdwards.I_X);
        assert(affP.y == TwistedEdwards.I_Y);

        // I = I - I
        P = I.sub(I);
        affP = P.toAffine();
        assert(P.cmp(I));
        assert(affP.x == TwistedEdwards.I_X);
        assert(affP.y == TwistedEdwards.I_Y);

        // G = 2G - G
        P = twoG.sub(G);
        affP = P.toAffine();
        assert(P.cmp(G));
        assert(affP.x == TwistedEdwards.G_X);
        assert(affP.y == TwistedEdwards.G_Y);

        // -G = I - G
        P = I.sub(G);
        affP = P.toAffine();
        assert(affP.x == TwistedEdwards.q - TwistedEdwards.G_X);
        assert(affP.y == TwistedEdwards.G_Y);
    }

    function test_Double() public view {
        // 2G = G + G
        ExtendedPoint memory P = G.double();
        AffinePoint memory affP = P.toAffine();
        assert(P.cmp(twoG));
        assert(affP.x == TWO_G_X);
        assert(affP.y == TWO_G_Y);

        // 4G = 2G + 2G
        P = P.double();
        affP = P.toAffine();
        assert(P.cmp(fourG));
        assert(affP.x == FOUR_G_X);
        assert(affP.y == FOUR_G_Y);
    }

    function test_Conversion() public view {
        // G = (G.toExtended()).toAffine()
        AffinePoint memory P = AffinePoint({x: TwistedEdwards.G_X, y: TwistedEdwards.G_Y}).toExtended().toAffine();
        assert(P.x == TwistedEdwards.G_X);
        assert(P.y == TwistedEdwards.G_Y);
    }
}
