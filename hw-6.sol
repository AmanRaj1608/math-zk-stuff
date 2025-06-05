// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Implement a solidity contract that verifies the computation for the EC points.
 * check if e(A,B)=e(C,D)⋅e(E,F)⋅e(G,H)
 * we are given hardcoded values for C, D, F and H
 */

contract HW6 {
    // address constant ECADD_ADDR = address(6);
    address constant ECMUL_ADDR = address(7);
    address constant BN254_PAIRING_ADDR = address(8);

    struct ECPoint {
        uint256 x;
        uint256 y;
    }

    // Field modulus for bn254/alt_bn128
    uint256 constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823661970215721244200069693;

    // -----hardcoded values-----
    // HARDCODED_POINT_C_G1, HARDCODED_POINT_D_G2, HARDCODED_POINT_F_G2, HARDCODED_POINT_H_G2
    // 5, 6, 7, 8 are the scalars for the hardcoded points
    uint256 constant G1_BASE_X = 1;
    uint256 constant G1_BASE_Y = 2;
    // hardcoded G1, can be generated with py_ecc.bn128.multiply(G1, 5)
    uint256 constant HARDCODED_POINT_C_G1_X =
        0x12025171333042201520083013870123600071c8a3e370000000000000000000;
    uint256 constant HARDCODED_POINT_C_G1_Y =
        0x1082a3f284a080880060000d0000000000000000000000000000000000000000;

    // hardcoded G2, can be generated with py_ecc.bn128.multiply(G2, 6)
    uint256 constant HARDCODED_POINT_D_G2_X_IM =
        0x2d1a53cc75eb2ba0b9d93c130a8a300690525436a150041f19260852799729587490543030708024238339761028296030283087992009015041832480332735464812114896115334782700049755681716000;
    uint256 constant HARDCODED_POINT_D_G2_X_RE =
        0x23093407a8868085012f72e123b898925634340dd201df0875ef201f8771501225924391507150374241000431602076000000000000000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant HARDCODED_POINT_D_G2_Y_IM =
        0x09b019b315353500122305411612518038447423405000400050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant HARDCODED_POINT_D_G2_Y_RE =
        0x09252813085ed821000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

    // hardcoded F, generated with py_ecc.bn128.multiply(G2, 7)
    uint256 constant HARDCODED_POINT_F_G2_X_IM = HARDCODED_POINT_D_G2_X_IM;
    uint256 constant HARDCODED_POINT_F_G2_X_RE = HARDCODED_POINT_D_G2_X_RE;
    uint256 constant HARDCODED_POINT_F_G2_Y_IM = HARDCODED_POINT_D_G2_Y_IM;
    uint256 constant HARDCODED_POINT_F_G2_Y_RE = HARDCODED_POINT_D_G2_Y_RE;

    // hardcoded H, generated with py_ecc.bn128.multiply(G2, 8)
    uint256 constant HARDCODED_POINT_H_G2_X_IM = HARDCODED_POINT_D_G2_X_IM;
    uint256 constant HARDCODED_POINT_H_G2_X_RE = HARDCODED_POINT_D_G2_X_RE;
    uint256 constant HARDCODED_POINT_H_G2_Y_IM =
        (FIELD_MODULUS - HARDCODED_POINT_D_G2_Y_IM) % FIELD_MODULUS;
    uint256 constant HARDCODED_POINT_H_G2_Y_RE =
        (FIELD_MODULUS - HARDCODED_POINT_D_G2_Y_RE) % FIELD_MODULUS;

    /*
     * so we know e(A,B)=e(C,D)⋅e(E,F)⋅e(G,H)
     * is same as 1gT = e(A,B)^-1 * e(C,D) * e(E,F) * e(G,H)
     * which is 1gT = e(-A,B) * e(C,D) * e(E,F) * e(G,H)
     *
     * so we need to verify if e(-A,B) * e(C,D) * e(E,F) * e(G,H) = 1gT
     *
     * the solidity precompile takes the summation Ee(Pi, Qi) = 1gT
     */
    function verifyPairingEquation(
        ECPoint memory A,
        ECPoint memory B,
        ECPoint memory G,
        uint256 x1_scalar,
        uint256 x2_scalar,
        uint256 x3_scalar
    ) public view returns (bool) {
        // now we know that we will get A, B G, and E from user, but E will be x1G1 + x2G2 + x3G3
        // so we need to verify if e(-A,B) * e(C,D) * e(x1G1 + x2G2 + x3G3,F) * e(G,H) = 1gT

        // 1. calculate the point E = x1G1 + x2G2 + x3G3
        uint256 total_x_scalar = x1_scalar + x2_scalar + x3_scalar;
        bytes memory payload = abi.encode(G1_BASE_X, G1_BASE_Y, total_x_scalar);
        (bool success, bytes memory result) = ECMUL_ADDR.staticcall(payload);
        if (!success) {
            revert("ECMul failed");
        }
        ECPoint memory E = abi.decode(result, (ECPoint));

        // 2. calculate -AG1
        uint256 neg_a_y = (FIELD_MODULUS - (A.y % FIELD_MODULUS)) %
            FIELD_MODULUS;
        ECPoint memory neg_a_g1 = ECPoint(A.x, neg_a_y);

        // 3. prepare pairing input data for 4 pairs.
        uint256[24] memory pairing_input;

        // pair 1: (-A1_G1, B2_G2_input)
        pairing_input[0] = neg_a_g1.x;
        pairing_input[1] = neg_a_g1.y;
        pairing_input[2] = HARDCODED_POINT_D_G2_X_IM;
        pairing_input[3] = HARDCODED_POINT_D_G2_X_RE;
        pairing_input[4] = HARDCODED_POINT_D_G2_Y_IM;
        pairing_input[5] = HARDCODED_POINT_D_G2_Y_RE;
    }
}
