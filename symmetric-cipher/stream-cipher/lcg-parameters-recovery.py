#!/usr/bin/env python3

import random
from math import gcd
from gmpy2 import invert
from functools import reduce
from Crypto.Util.number import isPrime, getPrime

NBITS = 64

# Linear Congruential Generator
class LCG:
    def __init__(self, seed, p, m, c):
        self.state = seed
    def next(self):
        self.state = (self.state * m + c) % p
        return self.state

# use 6 outputs to recover `p`.
def recover_p(s):
    diffs = [s2 - s1 for s1, s2 in zip(s, s[1:])]
    zeroes = [t3 * t1 - t2 * t2 for t1, t2, t3 in zip(diffs, diffs[1:], diffs[2:])]
    p = abs(reduce(gcd, zeroes))
    return p

# use 3 outputs and `p` to recover `m`.
def recover_m(s, p):
    m = (s[2] - s[1]) * invert(s[1] - s[0], p) % p
    return m

# use 2 outputs, `p` and `m` to recover `c`.
def recover_c(s, p, m):
    c = (s[1] - s[0] * m) % p
    return c

# use the first output, `p`, `m` and `c` to recover `seed`.
def recover_seed(s, p, m, c):
    seed = ((s - c) * invert(m, p)) % p
    return seed

if __name__ == '__main__':
    # test
    p = getPrime(NBITS)
    seed, m, c = [random.randint(1, p) for _ in range(3)]
    PRNG = LCG(seed, p, m, c)
    s = [PRNG.next() for _ in range(6)]

    p_recovered = recover_p(s)

    # avoid the case where the recovered parameter is `k * p`.
    for i in range(1, 20):
        if isPrime(p_recovered // i) and (p_recovered // i).bit_length() == NBITS:
            p_recovered = p_recovered // i
            break

    m_recovered = recover_m(s[: 3], p_recovered)
    c_recovered = recover_c(s[: 2], p_recovered, m_recovered)
    seed_recovered = recover_seed(s[0], p_recovered, m_recovered, c_recovered)

    # check
    print(p_recovered == p)
    print(m_recovered == m)
    print(c_recovered == c)
    print(seed_recovered == seed)