#!/usr/bin/env python3

# https://en.wikipedia.org/wiki/Padding_oracle_attack

import os
from tqdm import tqdm
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

# Initialize the AES part.
BLOCK_SIZE = 16
key = os.urandom(BLOCK_SIZE)
iv = os.urandom(BLOCK_SIZE)
cipher = AES.new(key, AES.MODE_CBC, iv)

# Return true if unpad succeeds, false otherwise.
def oracle(ct, io):
    if io:
        '''
        Write your own `oracle` function here during CTF.
        '''
    else:
        iv, ct = ct[:BLOCK_SIZE], ct[BLOCK_SIZE:]
        cipher = AES.new(key, AES.MODE_CBC, iv)
        pt = cipher.decrypt(ct)
        try:
            _ = unpad(pt, BLOCK_SIZE, "pkcs7")
            return True
        except:
            return False

# Use two ct blocks to recover one pt block.
def single_block_cbc_padding_oracle_attack(ct_block_0, ct_block_1, io):
    '''
    If a timeout is encountered during execution, 
    just replace the values of `pt_bytes` and `new_ct_bytes` with the values before the interruption, 
    no need to re-execute the whole process.
    '''
    pt_bytes = b''
    new_ct_bytes = b''
    for padding_len in range(len(pt_bytes) + 1, BLOCK_SIZE + 1):
        for candidate_byte in tqdm(range(256)):
            new_ct_block_0 = os.urandom(BLOCK_SIZE - padding_len) + bytes([candidate_byte]) + new_ct_bytes
            new_ct_blocks = [new_ct_block_0] + [ct_block_1]
            new_ct = b''.join(new_ct_blocks)
            if oracle(new_ct, io):
                pt_bytes += bytes([padding_len ^ ct_block_0[-padding_len] ^ candidate_byte])
                new_ct_bytes = bytes([i ^ padding_len ^ (padding_len + 1) for i in new_ct_block_0[BLOCK_SIZE - padding_len:]])
                print(pt_bytes)
                print(new_ct_bytes)
                break
    pt_block = pt_bytes[::-1]
    return pt_block

# Recover the whole pt.
def cbc_padding_oracle_attack(ct, io):
    '''
    If you already know some pt blocks, 
    just fill each block into `pt_blocks` in order.
    '''
    pt_blocks = []
    ct_blocks = [ct[i: i + BLOCK_SIZE] for i in range(0, len(ct), BLOCK_SIZE)]
    for i in range(len(pt_blocks), len(ct_blocks) - 1):
        print("[+] BLOCK " + str(i))
        pt_blocks += [single_block_cbc_padding_oracle_attack(ct_blocks[i], ct_blocks[i + 1], io)]
    pt = b''.join(pt_blocks)
    return pt

if __name__ == "__main__":
    # Our goal is to recover `pt` using `ct` and `oracle` function.
    pt = b"abcdefghijklmnopqrstuvwxyz"
    ct = cipher.encrypt(pad(pt, BLOCK_SIZE, "pkcs7"))
    ct = iv + ct

    '''
    For local test, set `io = None`.
    For remote test, set `io = remote(IP, PORT)`.
    '''
    io = None
    pt_recovered = cbc_padding_oracle_attack(ct, io)

    # Test.
    print(unpad(pt_recovered, BLOCK_SIZE, "pkcs7") == pt)
