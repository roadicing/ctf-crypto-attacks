#!/usr/bin/env sage

from tqdm import tqdm

NBITS = 512
SMALL_BOUND = 24
BIG_BOUND = 160

# all the factors of `p - 1` are less than `2^small_bound`.
def gen_p_minus_1_full_smooth_prime(nbits, small_bound):
    p = 2
    while p.nbits() < nbits - 2 * small_bound:
        p *= random_prime(2^small_bound, lbound = 2^(small_bound - 1))
    rbits = (nbits - p.nbits()) // 2
    while True:
        r, s = [random_prime(2^rbits, lbound = 2^(rbits - 1)) for _ in '01']
        _p = p * r * s
        if _p.nbits() < nbits: rbits += 1
        if _p.nbits() > nbits: rbits -= 1
        if is_prime(_p + 1) and (_p + 1).nbits() == nbits:
            p = _p + 1
            return p

# all the factors of `p - 1` are less than `2^small_bound` except the last one, which is less than `2^big_bound`.
def gen_p_minus_1_partial_smooth_prime(nbits, small_bound, big_bound):
    p = 2
    while p.nbits() < nbits - 2 * small_bound - big_bound:
        p *= random_prime(2^small_bound, lbound = 2^(small_bound - 1))
    rbits = (nbits - p.nbits()) // 2
    while True:
        r, s = [random_prime(2^rbits, lbound = 2^(rbits - 1)) for _ in '01']
        z = random_prime(2^big_bound, lbound = 2^(big_bound - 1))
        _p = p * r * s * z
        if _p.nbits() < nbits: rbits += 1
        if _p.nbits() > nbits: rbits -= 1
        if is_prime(_p + 1) and (_p + 1).nbits() == nbits:
            p = _p + 1
            return p

# used when `p - 1` is partial smooth, where `factors` are relatively small factors of `p - 1`.
# calculate `x` such that `g^x = y (mod p)`.
def dlp_pohlig_hellman_attack(p, g, y, factors):
    residues = []
    moduli = []
    for i in tqdm(factors):
        t = (p - 1) // i
        g_i = pow(g, t, p)
        y_i = pow(y, t, p)
        x_i = discrete_log(Mod(y_i, p), Mod(g_i, p))
        if x_i == 0:
            continue
        residues += [x_i]
        moduli += [i]
    x = crt(residues, moduli)
    return x, moduli

if __name__ == "__main__":
    # case-1
    # enerate parameters.
    p = gen_p_minus_1_full_smooth_prime(NBITS, SMALL_BOUND)
    g = randint(1, p)
    x = randint(1, p)
    y = pow(g, x, p)

    # solve DLP in `GF(p)`, where `p - 1` is smooth enough.
    ans = discrete_log(Mod(y, p), Mod(g, p))

    # test.
    print(x == ans)


    # case-2
    # generate parameters.
    p = gen_p_minus_1_partial_smooth_prime(NBITS, SMALL_BOUND, BIG_BOUND)
    g = randint(1, p)
    x = randint(1, p)
    y = pow(g, x, p)

    # solve DLP in `GF(p)`, where `p - 1` isn't smooth enough.
    factors = [i for i, _ in list((p - 1).factor())][:-1]
    ans, moduli = dlp_pohlig_hellman_attack(p, g, y, factors)

    # test.
    print(x % lcm(moduli) == ans % lcm(moduli))


    # case-3
    # generate parameters.
    p = gen_p_minus_1_full_smooth_prime(NBITS, SMALL_BOUND)
    q = gen_p_minus_1_full_smooth_prime(NBITS, SMALL_BOUND)
    n = p * q
    g = randint(1, p)
    x = randint(1, p)
    y = pow(g, x, n)

    # solve DLP in `Zmod(n)`, where `p - 1` and `q - 1` are smooth enough.
    ans = crt([discrete_log(Mod(y, i), Mod(g, i)) for i in [p, q]], [Mod(g, i).multiplicative_order() for i in [p, q]])

    # test.
    print(x == ans)
