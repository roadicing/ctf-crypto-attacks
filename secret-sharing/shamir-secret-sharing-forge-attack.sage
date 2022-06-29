#!/usr/bin/env sage

# https://crypto.stackexchange.com/questions/54578/how-to-forge-a-shamir-secret-share

# Initialize the Shamir's Secret Sharing part.
p = 2^127 - 1
P.<x> = PolynomialRing(GF(p))
min_num = 3
num = 6

# Make `min_num` shares for `secret`.
def make_shares(secret, min_num, num, P):
    assert min_num <= num
    poly = P.random_element(min_num)
    poly = poly - poly.constant_coefficient() + secret
    shares = [(i, poly(i)) for i in range(1, num + 1)]
    return shares

# Recover `secret` from at least `min_num` shares.
def recover_secret(shares, P):
    f = P.lagrange_polynomial(shares)
    return f(0)

# Forge a new share for target secret, assume we hold `shares[0]`.
def forge_shamir_secret_share(our_share, other_shares_x_coords, origin_secret, target_secret, prime):
    tmp = 1
    for x in other_shares_x_coords:
        tmp *= ((x - our_share[0]) * inverse_mod(x, prime)) % prime
    return (our_share[0], (our_share[1] + (target_secret - origin_secret) * tmp) % prime)

if __name__ == "__main__":
    # Make `min_num` shares for `origin_secret`.
    origin_secret = 123456
    shares = make_shares(origin_secret, min_num, num, P)

    # We changed the recovered secret from `origin_secret` to `target_secret` by forging a new share.
    target_secret = 654321
    new_our_share = forge_shamir_secret_share(shares[0], [x for (x, _) in shares[1:]], origin_secret, target_secret, p)
    new_shares = [new_our_share] + shares[1:]

    # Test.
    print(recover_secret(new_shares, P) == target_secret)
