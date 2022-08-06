#!/usr/bin/env sage

NBITS = 192

# gen ec
def gen_ec():
    while True:
        p = random_prime(2^NBITS, False, lbound = 2^(NBITS - 1))
        a, b = [randint(1, p) for _ in range(2)]
        try:
            E = EllipticCurve(GF(p), [a, b])
            return a, b, p, E
        except:
            continue

# recover a, b using p and two points.
def recover_ec_a_b(p, points):
    A, B = [list(map(ZZ, i.xy())) for i in points]
    try:
        a = ((B[1]^2 - A[1]^2 - (B[0]^3 - A[0]^3)) * inverse_mod(B[0] - A[0], p)) % p
    except:
        print("[+] inappropriate points used, try again.")
        exit(-1)
    b = (A[1]^2 - A[0]^3 - a * A[0]) % p
    return a, b

# recover p using a, b and two points.
def recover_ec_p(a, b, points):
    A, B = [list(map(ZZ, i.xy())) for i in points]
    kp = A[1]^2 - (A[0]^3 + a * A[0] + b)
    gp = B[1]^2 - (B[0]^3 + a * B[0] + b)
    rp = gcd(kp, gp)
    i = 1
    p = rp // i
    while not (is_prime(p) and p.nbits() == NBITS):
        i += 1
        p = rp // i
    return p

# recover a, b, p using four points.
def recover_ec_a_b_p(points):
    A, B, C, D = [list(map(ZZ, i.xy())) for i in points]
    kp = (((A[1]^2 - B[1]^2) - (A[0]^3 - B[0]^3)) * (C[0] - D[0]) - ((C[1]^2 - D[1]^2) - (C[0]^3 - D[0]^3)) * (A[0] - B[0]))
    gp = (((A[1]^2 - C[1]^2) - (A[0]^3 - C[0]^3)) * (B[0] - D[0]) - ((B[1]^2 - D[1]^2) - (B[0]^3 - D[0]^3)) * (A[0] - C[0]))
    rp = gcd(kp, gp)
    i = 1
    p = rp // i
    while not (is_prime(p) and p.nbits() == NBITS):
        i += 1
        p = rp // i
    a, b = recover_ec_a_b(p, points[:2])
    return a, b, p

if __name__ == '__main__':
    # test
    a, b, p, E = gen_ec()
    points = [E.random_point() for _ in range(4)]

    # check
    print((a, b) == recover_ec_a_b(p, points[:2]))
    print(p == recover_ec_p(a, b, points[:2]))
    print((a, b, p) == recover_ec_a_b_p(points))