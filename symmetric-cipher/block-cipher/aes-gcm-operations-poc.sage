#!/usr/bin/env sage

# https://nvlpubs.nist.gov/nistpubs/legacy/sp/nistspecialpublication800-38d.pdf

from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from Crypto.Util.number import long_to_bytes, bytes_to_long
from Crypto.Util.strxor import strxor

# perform AES-GCM encrypt and digest.
def aes_gcm_encrypt(nonce, key, pt):
    cipher = AES.new(key, AES.MODE_GCM, nonce = nonce)
    ct, tag = cipher.encrypt_and_digest(pt)
    return ct, tag

# perform AES-GCM decrypt and verify.
def aes_gcm_decrypt(nonce, key, ct, tag):
    cipher = AES.new(key, AES.MODE_GCM, nonce = nonce)
    try:
        pt = cipher.decrypt_and_verify(ct, tag)
        return pt
    except:
        return None

# perform AES-ECB encrypt.
def aes_ecb_encrypt(key, pt):
    cipher = AES.new(key, AES.MODE_ECB)
    ct = cipher.encrypt(pt)
    return ct

# define basic algebraic structures.
X = GF(2).polynomial_ring().gen()
F = GF(2^128, name = 'a', modulus = X^128 + X^7 + X^2 + X^1 + 1)
R.<x> = PolynomialRing(F)

# increment by 1 on `bytes`.
def bytes_inc(x, c):
    return long_to_bytes(bytes_to_long(x) + c)

# convert `int` to `bits`.
def int_to_bits(x, n):
    return ZZ(x).bits() + [0] * (n - ZZ(x).nbits())

# convert `bits` to `int`.
def bits_to_int(x):
    return int("".join(map(str, x)), 2)

# convert `int` to `poly`.
def int_to_poly(x):
    return F.fetch_int(bits_to_int(int_to_bits(x, 128)))

# convert `poly` to `int`.
def poly_to_int(x):
    return bits_to_int(int_to_bits(x.integer_representation(), 128))

# convert `bytes` to `poly`.
def bytes_to_poly(x):
    return int_to_poly(bytes_to_long(x))

# convert `poly` to `bytes`.
def poly_to_bytes(x):
    return long_to_bytes(poly_to_int(x))

# implement the GHASH function.
def ghash(iv, H):
    fill = (16 - (len(iv) % 16)) % 16 + 8
    ghash_in = iv + b"\x00" * fill + long_to_bytes(8 * len(iv), 8)
    assert len(ghash_in) % 16 == 0
    ghash = int_to_poly(0)
    for i in range(0, len(ghash_in), 16):
        ghash_block = ghash_in[i: i+16]
        ghash += bytes_to_poly(ghash_block)
        ghash *= H
    return poly_to_bytes(ghash)

# implement the AES-GCM encrypt and digest function.
def aes_gcm_encrypt_operations(nonce, key, pt):
    H = bytes_to_poly(aes_ecb_encrypt(key, b'\x00' * 16))
    j0 = ghash(nonce, H)
    ji = j0
    pt_blocks = [pt[i * 16: (i + 1) * 16] for i in range(len(pt) // 16)]
    ct_blocks = []
    for pt_block in pt_blocks:
        ji = bytes_inc(ji, 1)
        ct_block = strxor(pt_block, aes_ecb_encrypt(key, ji))
        ct_blocks += [ct_block]
    ct = b''.join(ct_blocks)
    T = int_to_poly(0)
    for i, ct_block in enumerate(ct_blocks):
        T += bytes_to_poly(ct_block) * H^(len(ct_blocks) + 1 - i)
    T += bytes_to_poly(b'\x00' * 8 + long_to_bytes(len(pt) * 8, 8)) * H
    T += bytes_to_poly(aes_ecb_encrypt(key, j0))
    tag = poly_to_bytes(T)
    return ct, tag

# implement the AES-GCM decrypt and verify function.
def aes_gcm_decrypt_operations(nonce, key, ct, tag):
    H = bytes_to_poly(aes_ecb_encrypt(key, b'\x00' * 16))
    j0 = ghash(nonce, H)
    ji = j0
    ct_blocks = [ct[i * 16: (i + 1) * 16] for i in range(len(ct) // 16)]
    pt_blocks = []
    for ct_block in ct_blocks:
        ji = bytes_inc(ji, 1)
        pt_block = strxor(ct_block, aes_ecb_encrypt(key, ji))
        pt_blocks += [pt_block]
    pt = b''.join(pt_blocks)
    T = int_to_poly(0)
    for i, ct_block in enumerate(ct_blocks):
        T += bytes_to_poly(ct_block) * H^(len(ct_blocks) + 1 - i)
    T += bytes_to_poly(b'\x00' * 8 + long_to_bytes(len(ct) * 8, 8)) * H
    T += bytes_to_poly(aes_ecb_encrypt(key, j0))
    tag_calc = poly_to_bytes(T)
    if tag_calc == tag:
        return pt

if __name__ == "__main__":
    # initialize variables.
    key = get_random_bytes(16)
    nonce = get_random_bytes(16)
    pt = b'A' * 48

    # test.
    ct, tag = aes_gcm_encrypt(nonce, key, pt)
    ct_calc, tag_calc = aes_gcm_encrypt_operations(nonce, key, pt)

    # check.
    print(ct == ct_calc)
    print(tag == tag_calc)

    # test.
    pt_calc = aes_gcm_decrypt_operations(nonce, key, ct, tag)

    # check.
    print(pt == pt_calc)