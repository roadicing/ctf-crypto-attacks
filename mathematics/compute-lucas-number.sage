#!/usr/bin/sage

# https://math.stackexchange.com/questions/4185190/what-is-the-fastest-method-to-compute-the-nth-number-in-lucas-sequences

# fast method to compute the n-th lucas number.
def lucas_number_fast_method(n, P, Q, N, type):
    mat = matrix(Zmod(N), [[P, -Q], [1, 0]])
    if type == 1:
        vec = vector(Zmod(N), [1, 0])
    elif type == 2:
        vec = vector(Zmod(N), [P, 2])
    num = (mat^(n - 1) * vec)[0]
    return ZZ(num)

if __name__ == "__main__":
    # set the parameters of lucas number. 
    n = randint(1, 1000)
    P = randint(1, 2^512)
    Q = randint(1, 2^512)
    N = 2^1024

    # check.
    print(lucas_number1(n, P, Q) % N == lucas_number_fast_method(n, P, Q, N, 1))
    print(lucas_number2(n, P, Q) % N == lucas_number_fast_method(n, P, Q, N, 2))
