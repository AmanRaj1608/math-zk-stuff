// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  Problem 1: Rational numbers
  Claim: "I know two rational numbers that add up to num/den"
  Proof: ([A], [B], num, den)
 */

contract HW5_1 {
    struct ECPoint {
        uint256 x;
        uint256 y;
    }
    // for BN254 (alt_bn128) G1 curve
    uint256 constant CURVE_ORDER =
        21888242871839275222246405745257275088614511777268538073601725287587578984328;
    // BN254 Generator Point G1 = (1, 2)
    uint256 constant G_X = 1;
    uint256 constant G_Y = 2;

    // Precompile addresses
    address constant MODEXP_ADDR = address(5);
    address constant ECADD_ADDR = address(6);
    address constant ECMUL_ADDR = address(7);

    // takes two points A, B and a rational number num/den and returns true if the sum of A and B is equal to num/den
    function rationalAdd(
        ECPoint calldata A,
        ECPoint calldata B,
        uint256 num,
        uint256 den
    ) public view returns (bool verified) {
        // We need to check if pointA + pointB == (num/den) * G

        // first calculate A+B
        bytes memory precompileData = abi.encode(A.x, A.y, B.x, B.y);
        (bool ok, bytes memory data) = ECADD_ADDR.staticcall(precompileData);
        require(ok, "ECAdd failed");
        (uint256 Cx, uint256 Cy) = abi.decode(data, (uint256, uint256));

        // now calculate the scalar k = num/den = num * den^-1
        uint256 denInv = modExp(den, CURVE_ORDER - 2, CURVE_ORDER); // (from fermat's little theorem)
        uint256 k = mulmod(num, denInv, CURVE_ORDER); // making sure we don't overflow and in curve order

        // now calculate k * G
        bytes memory precompileData2 = abi.encode(G_X, G_Y, k);
        (bool ok2, bytes memory data2) = ECMUL_ADDR.staticcall(precompileData2);
        require(ok2, "ECMul failed");
        (uint256 Dx, uint256 Dy) = abi.decode(data2, (uint256, uint256));

        // now check if C == D
        return Cx == Dx && Cy == Dy;
    }

    function modExp(
        uint256 base,
        uint256 exp,
        uint256 mod
    ) public view returns (uint256) {
        // (length_of_base, length_of_exp, length_of_mod, base, exp, mod)
        bytes memory precompileData = abi.encode(32, 32, 32, base, exp, mod);
        (bool ok, bytes memory data) = MODEXP_ADDR.staticcall(precompileData);
        require(ok, "expMod failed");
        return abi.decode(data, (uint256));
    }
}
