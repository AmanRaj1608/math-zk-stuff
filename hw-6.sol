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

    struct ECPointG1 {
        uint256 x;
        uint256 y;
    }

    struct ECPointG2 {
        uint256 x_re;
        uint256 x_im;
        uint256 y_re;
        uint256 y_im;
    }

    // Field modulus for bn254/alt_bn128
    uint256 constant FIELD_MODULUS =
        21888242871839275222246405745257275088696311157297823661970215721244200069693;

    // -----hardcoded values-----
    // HARDCODED_POINT_C_G1 -> 5G1, HARDCODED_POINT_D_G2 -> 6G2, HARDCODED_POINT_F_G2 -> 7G2, HARDCODED_POINT_H_G2 -> 8G2
    uint256 constant G1_BASE_X = 1;
    uint256 constant G1_BASE_Y = 2;
    // hardcoded G1, can be generated with py_ecc.bn128.multiply(G1, 5)
    uint256 constant HARDCODED_POINT_C_G1_X =
        10744596414106452074759370245733544594153395043370666422502510773307029471145;
    uint256 constant HARDCODED_POINT_C_G1_Y =
        848677436511517736191562425154572367705380862894644942948681172815252343932;

    // hardcoded G2, can be generated with py_ecc.bn128.multiply(G2, 6)
    uint256 constant HARDCODED_POINT_D_G2_X_RE =
        10191129150170504690859455063377241352678147020731325090942140630855943625622;
    uint256 constant HARDCODED_POINT_D_G2_X_IM =
        12345624066896925082600651626583520268054356403303305150512393106955803260718;
    uint256 constant HARDCODED_POINT_D_G2_Y_RE =
        16727484375212017249697795760885267597317766655549468217180521378213906474374;
    uint256 constant HARDCODED_POINT_D_G2_Y_IM =
        13790151551682513054696583104432356791070435696840691503641536676885931241944;

    // hardcoded F, generated with py_ecc.bn128.multiply(G2, 7)
    uint256 constant HARDCODED_POINT_F_G2_X_RE =
        15512671280233143720612069991584289591749188907863576513414377951116606878472;
    uint256 constant HARDCODED_POINT_F_G2_X_IM =
        18551411094430470096460536606940536822990217226529861227533666875800903099477;
    uint256 constant HARDCODED_POINT_F_G2_Y_RE =
        13376798835316611669264291046140500151806347092962367781523498857425536295743;
    uint256 constant HARDCODED_POINT_F_G2_Y_IM =
        1711576522631428957817575436337311654689480489843856945284031697403898093784;

    // hardcoded H, generated with py_ecc.bn128.multiply(G2, 8)
    uint256 constant HARDCODED_POINT_H_G2_X_RE =
        11166086885672626473267565287145132336823242144708474818695443831501089511977;
    uint256 constant HARDCODED_POINT_H_G2_X_IM =
        1513450333913810775282357068930057790874607011341873340507105465411024430745;
    uint256 constant HARDCODED_POINT_H_G2_Y_RE =
        10576778712883087908382530888778326306865681986179249638025895353796469496812;
    uint256 constant HARDCODED_POINT_H_G2_Y_IM =
        20245151454212206884108313452940569906396451322269011731680309881579291004202;

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
        ECPointG1 memory A,
        ECPointG2 memory B,
        ECPointG1 memory G,
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
        ECPointG1 memory E = abi.decode(result, (ECPointG1));

        // 2. calculate -AG1
        uint256 neg_a_y = FIELD_MODULUS - A.y;
        ECPointG1 memory neg_a_g1 = ECPointG1(A.x, neg_a_y);

        // 3. prepare pairing input data for 4 pairs.
        uint256[24] memory pairing_input;

        // pair 1: (-A1_G1, B2_G2_input)
        pairing_input[0] = neg_a_g1.x;
        pairing_input[1] = neg_a_g1.y;
        pairing_input[3] = B.x_re;
        pairing_input[2] = B.x_im;
        pairing_input[5] = B.y_re;
        pairing_input[4] = B.y_im;

        // pair 2: (C1_G1, D2_G2_input)
        pairing_input[6] = HARDCODED_POINT_C_G1_X;
        pairing_input[7] = HARDCODED_POINT_C_G1_Y;
        pairing_input[8] = HARDCODED_POINT_D_G2_X_IM;
        pairing_input[9] = HARDCODED_POINT_D_G2_X_RE;
        pairing_input[10] = HARDCODED_POINT_D_G2_Y_IM;
        pairing_input[11] = HARDCODED_POINT_D_G2_Y_RE;

        // pair 3: (E1_G1, F2_G2_input)
        pairing_input[12] = E.x;
        pairing_input[13] = E.y;
        pairing_input[14] = HARDCODED_POINT_F_G2_X_IM;
        pairing_input[15] = HARDCODED_POINT_F_G2_X_RE;
        pairing_input[16] = HARDCODED_POINT_F_G2_Y_IM;
        pairing_input[17] = HARDCODED_POINT_F_G2_Y_RE;

        // pair 4: (G1_G1, H2_G2_input)
        pairing_input[18] = G.x;
        pairing_input[19] = G.y;
        pairing_input[20] = HARDCODED_POINT_H_G2_X_IM;
        pairing_input[21] = HARDCODED_POINT_H_G2_X_RE;
        pairing_input[22] = HARDCODED_POINT_H_G2_Y_IM;
        pairing_input[23] = HARDCODED_POINT_H_G2_Y_RE;

        // 4. call pairing precompile
        (bool pairing_success, bytes memory pairing_result) = BN254_PAIRING_ADDR
            .staticcall(abi.encode(pairing_input));
        if (!pairing_success) {
            revert("Pairing failed");
        }

        bool pairing_result_bool = abi.decode(pairing_result, (bool));
        return pairing_result_bool;
    }
}
