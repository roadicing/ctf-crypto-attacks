#!/usr/bin/env sage

# https://crypto.stackexchange.com/questions/54578/how-to-forge-a-shamir-secret-share

# The Shamir's Secret Sharing part.
p = 2^127 - 1
P.<x> = PolynomialRing(GF(p))

secret = 123456
min_num = 3
num = 6

def make_shares(secret, min_num, num, P):
    assert min_num <= num
    poly = P.random_element(min_num)
    poly = poly - poly.constant_coefficient() + secret
    shares = [(i, poly(i)) for i in range(1, num + 1)]
    return shares

def recover_secret(shares, P):
    f = P.lagrange_polynomial(shares)
    return f(0)

shares = make_shares(secret, min_num, num, P)
print(recover_secret(shares, P) == secret)

# The forge attack part, assume we hold shares[0].
target_secret = 654321

def forge_shamir_secret_share(our_share, other_shares_x_coords, origin_secret, target_secret, prime):
    tmp = 1
    for x in other_shares_x_coords:
        tmp *= ((x - our_share[0]) * inverse_mod(x, prime)) % prime
    return (our_share[1] + (target_secret - origin_secret) * tmp) % prime

new_our_share = forge_shamir_secret_share(shares[0], [x for (x, _) in shares[1:]], secret, target_secret, p)
print(recover_secret([(shares[0][0], new_our_share)] + shares[1:], P) == target_secret)

'''
True
True
'''
