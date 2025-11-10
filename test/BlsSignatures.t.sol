// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {BlsSignatures, AffinePointG1, OpPointG1, AffinePointG2, OpPointG2} from "../src/BlsSignatures.sol";

contract BlsSignaturesTest is Test {
    using BlsSignatures for AffinePointG1;
    using BlsSignatures for AffinePointG2;

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

    AffinePointG2 pk = AffinePointG2({
        x1: hex"0ffe13c2e8ccdb19d846ed0674282d4c6d13642f4ecaefab42eecb70c17c7c95c84bb18095508ee2cf1c9b307d5d3687",
        x2: hex"05571d872653e05eb3aa495c389ca9a114f58fa3eafdf102c764b64edae10a0983f187fc1ca8140f75c16e4ecef0bda9",
        y1: hex"176b15b96630b2f9829d62d05e510b4d7a54eddc22c031e0b4d43380ee764a4dfea6ef326ed29b5c11b1556e58daabed",
        y2: hex"008ffd3017493b2189bf3493e6ed6d3a6f43c9f68a78ec65c9cea10cd6cc3d416fe802e3000129d6769dc16b21a70bed"
    });

    AffinePointG1 sig = AffinePointG1({
        x: hex"0760474b2b63d08796f528dcba365d9cc58c6dc5e4604ecca71a892a9cf323f6bf1b72da86af83e4b595cbf9e2e1b9f1",
        y: hex"05c80439057731aeb0d5283f29e5afd253b68a845d322ea28d1de01a4b26389eb5930ded7853c0ecd8cd6f229420b5cd"
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

    function test_NegG1() public view {
        AffinePointG1 memory negG1gen = AffinePointG1({
            x: hex"17f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb",
            y: hex"114d1d6855d545a8aa7d76c8cf2e21f267816aef1db507c96655b9d5caac42364e6f38ba0ecb751bad54dcd6b939c2ca"
        });

        assert(keccak256(negG1gen.toOp().xy) == keccak256(BlsSignatures.negG1(P).toOp().xy));
    }

    function test_VerifySignature() public view {
        bytes memory message = abi.encodePacked(uint64(12345678));
        assert(BlsSignatures.verifySignature(pk.toOpG2(), message, sig));
    }

    function test_VerifySignatureWrongMessage() public view {
        bytes memory message = abi.encodePacked(uint64(87654321));
        assert(!BlsSignatures.verifySignature(pk.toOpG2(), message, sig));
    }

    function test_VerifySignatureWrongKey() public view {
        bytes memory message = abi.encodePacked(uint64(12345678));

        AffinePointG2 memory pk_wrong = AffinePointG2({
            x1: hex"003b8b1486a6231e5e15975490a10c5e09ad2d6aeea34a5e08c1711bad273e47d13516520433fc6e63f2d9d706ac2674",
            x2: hex"0214a897cb24131e843fb3f4d96d11ad070b3ee86609739d8f9f9df03798a2a069ecc18380db69b7c80f79813a70413c",
            y1: hex"160ae55b9f947db1480f04252b598dc637f5b282e99f5de68c043f9da752cb4587ddf480b00dd52c0d868c8be6c126f3",
            y2: hex"082fc6e4eddd35cbb3288b65e916606ffd14e64868fb45b7adf4812b16aecb21a9d74616f9059b6a9a3a0dda7c962a6d"
        });

        assert(!BlsSignatures.verifySignature(pk_wrong.toOpG2(), message, sig));
    }
}
