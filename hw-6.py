from py_ecc.bn128 import G1, G2, multiply, neg, pairing, FQ12

FQ12_one = FQ12.one()

s_C, s_D, s_F, s_H = 5, 6, 7, 8
s_A, s_B, s_E, s_G = 4, 13, 2, 1

print("=== VALIDATION CHECK ===")
A = multiply(G1, s_A)
B = multiply(G2, s_B)
G_point = multiply(G1, s_G)
E = multiply(G1, s_E)

print(f"A is valid: x={A[0].n}, y={A[1].n}")
print(f"B is valid: x_re={B[0].coeffs[0].n}, x_im={B[0].coeffs[1].n}")
print(f"             y_re={B[1].coeffs[0].n}, y_im={B[1].coeffs[1].n}")
print(f"G is valid: x={G_point[0].n}, y={G_point[1].n}")
print(f"E is valid: x={E[0].n}, y={E[1].n}")

print("\n=== HARDCODED POINTS FOR SOLIDITY ===")
print(f"C = {s_C}*G1:")
C = multiply(G1, s_C)
print(f"uint256 constant HARDCODED_POINT_C_G1_X = {C[0].n};")
print(f"uint256 constant HARDCODED_POINT_C_G1_Y = {C[1].n};")

print(f"\nD = {s_D}*G2:")
D = multiply(G2, s_D)
print(f"uint256 constant HARDCODED_POINT_D_G2_X_RE = {D[0].coeffs[0].n};")
print(f"uint256 constant HARDCODED_POINT_D_G2_X_IM = {D[0].coeffs[1].n};")
print(f"uint256 constant HARDCODED_POINT_D_G2_Y_RE = {D[1].coeffs[0].n};")
print(f"uint256 constant HARDCODED_POINT_D_G2_Y_IM = {D[1].coeffs[1].n};")

print(f"\nF = {s_F}*G2:")
F = multiply(G2, s_F)
print(f"uint256 constant HARDCODED_POINT_F_G2_X_RE = {F[0].coeffs[0].n};")
print(f"uint256 constant HARDCODED_POINT_F_G2_X_IM = {F[0].coeffs[1].n};")
print(f"uint256 constant HARDCODED_POINT_F_G2_Y_RE = {F[1].coeffs[0].n};")
print(f"uint256 constant HARDCODED_POINT_F_G2_Y_IM = {F[1].coeffs[1].n};")

print(f"\nH = {s_H}*G2:")
H = multiply(G2, s_H)
print(f"uint256 constant HARDCODED_POINT_H_G2_X_RE = {H[0].coeffs[0].n};")
print(f"uint256 constant HARDCODED_POINT_H_G2_X_IM = {H[0].coeffs[1].n};")
print(f"uint256 constant HARDCODED_POINT_H_G2_Y_RE = {H[1].coeffs[0].n};")
print(f"uint256 constant HARDCODED_POINT_H_G2_Y_IM = {H[1].coeffs[1].n};")

print("\n=== TEST INPUT VALUES ===")
print(f"A = {s_A}*G1: ({A[0].n}, {A[1].n})")

print(f"B = {s_B}*G2: x_re={B[0].coeffs[0].n}, x_im={B[0].coeffs[1].n}, y_re={B[1].coeffs[0].n}, y_im={B[1].coeffs[1].n}")

print(f"G = {s_G}*G1: ({G_point[0].n}, {G_point[1].n})")

print(f"x1_scalar = 1, x2_scalar = 1, x3_scalar = 0 (sum = {s_E})")

print("\n=== VERIFICATION ===")
neg_A = neg(A)
result = pairing(B, neg_A) * pairing(D, C) * pairing(F, E) * pairing(H, G_point)
print(f"Constraint check: -({s_A}*{s_B}) + ({s_C}*{s_D}) + ({s_E}*{s_F}) + ({s_G}*{s_H}) = {-s_A*s_B + s_C*s_D + s_E*s_F + s_G*s_H}")
print(f"Pairing equation result: {result == FQ12_one}")

# Test with smaller values to debug
print(f"\n=== DEBUGGING WITH GENERATOR POINTS ===")
print(f"G1 generator: ({G1[0].n}, {G1[1].n})")
print(f"G2 generator: x_re={G2[0].coeffs[0].n}, x_im={G2[0].coeffs[1].n}, y_re={G2[1].coeffs[0].n}, y_im={G2[1].coeffs[1].n}")

# Verify that e(G1, G2) != 1 (should be true for a valid pairing)
test_pairing = pairing(G2, G1)
print(f"e(G1, G2) != 1: {test_pairing != FQ12_one}")