from py_ecc.bn128 import G1, G2, add, multiply, neg
from py_ecc.bn128 import curve_order as bn128_curve_order # n
from py_ecc.bn128 import field_modulus as bn128_field_modulus # p

print(f"BN128 G1 Generator Point: {G1}")

# 1. scalar multiplication: P = s * G1
scalar_s = 5
P = multiply(G1, scalar_s)
print(f"P = {scalar_s} * G1 = {P}")

# 2. scalar multiplication: Q = t * G1
scalar_t = 3
Q = multiply(G1, scalar_t)
print(f"Q = {scalar_t} * G1 = {Q}")

# 3. Point Addition: R = P + Q
R_added = add(P, Q)
print(f"R = P + Q = {R_added}")

# verify: R should be (s+t) * G1
R_expected = multiply(G1, scalar_s + scalar_t)
print(f"Expected R = ({scalar_s} + {scalar_t}) * G1 = {R_expected}")
if R_added == R_expected:
    print("Point addition verified: P + Q == (s+t)*G1")
else:
    print("Point addition verification failed.")

# 4. Point Negation
neg_P = neg(P)
print(f"Negation of P: -P = {neg_P}")

# verify P + (-P) = O (Point at Infinity, represented as None in py_ecc for G1/G2)
sum_P_negP = add(P, neg_P)
print(f"P + (-P) = {sum_P_negP}") # Should be None (Point at Infinity)
if sum_P_negP is None:
    print("P + (-P) correctly results in the point at infinity.")
else:
    print("P + (-P) did not result in point at infinity.")

# curve order and field modulus
print(f"BN128 Curve Order (n): {bn128_curve_order}")
print(f"BN128 Field Modulus (p): {bn128_field_modulus}")

# note: BN128 is often used for pairings. G2 is another generator point for a different group.
print(f"BN128 G2 Generator Point: {G2}")

