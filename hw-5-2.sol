// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  Problem 2: Matrix Multiplication
  Claim: "I know a matrix M and a vector s such that M * s = o * G"
  Proof: (M, s, o)
 */
contract HW5_2 {
    struct ECPoint {
        uint256 x;
        uint256 y;
    }

    // BN254 Curve Order (order of the scalar field Z_r)
    uint256 constant CURVE_ORDER = 21888242871839275222246405745257275088614511777268538073601725287587578984328;
    
    // BN254 Generator Point G1 = (1, 2)
    // Using immutable for gas efficiency as it's set at deployment.
    ECPoint immutable G_POINT;

    // Precompile addresses for BN254 curve operations
    address constant ECADD_ADDR = address(6);
    address constant ECMUL_ADDR = address(7);

    constructor() {
        G_POINT = ECPoint(1, 2);
    }

    // internal function for EC scalar multiplication: scalar * P.
    function _ecMul(ECPoint memory p, uint256 scalar) internal view returns (ECPoint memory resultP) {
        uint256 s = scalar % CURVE_ORDER; // Precompile handles this, but good for clarity

        // Handle cases for point at infinity or zero scalar
        if ((p.x == 0 && p.y == 0) || s == 0) {
            return ECPoint(0, 0); // P*0 = O or O*s = O (O is point at infinity (0,0))
        }

        bytes memory precompileData = abi.encode(p.x, p.y, s);
        (bool success, bytes memory resultData) = ECMUL_ADDR.staticcall(precompileData);
        require(success, "ECMUL precompile failed");
        (resultP.x, resultP.y) = abi.decode(resultData, (uint256, uint256));
    }

    // internal function for EC addition: P1 + P2.
    function _ecAdd(ECPoint memory p1, ECPoint memory p2) internal view returns (ECPoint memory resultP) {
        // Handle identity point P1 = O (point at infinity)
        if (p1.x == 0 && p1.y == 0) {
            return p2; // O + P2 = P2
        }
        // Handle identity point P2 = O
        if (p2.x == 0 && p2.y == 0) {
            return p1; // P1 + O = P1
        }

        bytes memory precompileData = abi.encode(p1.x, p1.y, p2.x, p2.y);
        (bool success, bytes memory resultData) = ECADD_ADDR.staticcall(precompileData);
        require(success, "ECADD precompile failed");
        (resultP.x, resultP.y) = abi.decode(resultData, (uint256, uint256));
    }

    // verifies the matrix-vector multiplication claim: M * s_vector == o_vector * G.
    function matmul(
        uint256[] calldata matrix_M,
        uint256 n,
        ECPoint[] calldata s_vector,
        uint256[] calldata o_vector
    ) public view returns (bool verified) {
        // --- Input Validations ---
        require(n > 0, "Dimension n must be greater than 0");
        require(matrix_M.length == n * n, "matrix_M: Incorrect length for n*n");
        require(s_vector.length == n, "s_vector: Incorrect length for n");
        require(o_vector.length == n, "o_vector: Incorrect length for n");

        // --- Perform n equality checks ---
        // For each row i (0 to n-1):
        // Calculate LHS: (M * s_vector)_i = sum_{j=0}^{n-1} (matrix_M[i][j] * s_vector[j])
        // Calculate RHS: (o_vector * G)_i = o_vector[i] * G_POINT
        // Compare LHS_i with RHS_i
        for (uint256 i = 0; i < n; i++) {
            // --- Calculate LHS_i ---
            ECPoint memory lhs_Pi = ECPoint(0, 0); // Initialize sum to point at infinity O

            for (uint256 j = 0; j < n; j++) {
                uint256 scalar_M_ij = matrix_M[i * n + j]; // M[i][j]
                ECPoint memory point_s_j = s_vector[j];    // s[j]
                
                // Term = M_ij * s_j
                ECPoint memory term_ij = _ecMul(point_s_j, scalar_M_ij);
                
                // Add to running sum: lhs_Pi = lhs_Pi + term_ij
                lhs_Pi = _ecAdd(lhs_Pi, term_ij);
            }

            // --- Calculate RHS_i ---
            uint256 scalar_o_i = o_vector[i]; // o[i]
            ECPoint memory rhs_OiG = _ecMul(G_POINT, scalar_o_i);

            // --- Compare LHS_i and RHS_i ---
            if (lhs_Pi.x != rhs_OiG.x || lhs_Pi.y != rhs_OiG.y) {
                return false; // Verification failed for this row
            }
        }

        // All row checks passed
        return true;
    }
}