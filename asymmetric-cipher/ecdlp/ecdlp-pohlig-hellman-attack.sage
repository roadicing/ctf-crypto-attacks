#!/usr/bin/env sage

# used when `E_p.order()` and `E_q.order()` are smooth enough.
# calculate `s` such that `P * s = Q` in `Zmod(p * q)`.
def zmodn_pohlig_hellman_attack(P, Q, p, q):
    residues = []
    moduli = []
    for i in [p, q]:
        E = EllipticCurve(GF(i), [a, b])
        PP = E(P[0] % i, P[1] % i)
        QQ = E(Q[0] % i, Q[1] % i)
        residues += [discrete_log(QQ, PP, operation = '+')]
        moduli += [PP.order()]
    s = crt(residues, moduli)
    return s

if __name__ == "__main__":
    # case-1
    # generate curve.
    p, a, b = 1248181544411553578085037206926245929211, 978425315227900659025715935774133186126, 1086876623236142458586092925970595827396
    E = EllipticCurve(GF(p), [a, b])
    
    # generate points.
    P = E.random_point()
    s = randint(1, P.order())
    Q = P * s

    # solve ECDLP in `GF(p)`, where `E.order()` is smooth enough.
    ans = discrete_log(Q, P, operation = '+')

    # test.
    print(s == ans)


    # case-2
    # generate curve.
    p, q = 11522256336953175349, 14624100800238964261
    n = p * q
    a, b = 31337, 5150705532662904291319187242308405023384690214780131486784837319746506803341
    E = EllipticCurve(Zmod(n), [a, b])

    # generate points.
    while True: 
        try: 
            x = randint(1, n) 
            y = crt([Integer((GF(p)(x^3 + a*x + b)).nth_root(2)), Integer((GF(q)(x^3 + a*x + b)).nth_root(2))], [p, q]) 
            P = E(x, y) 
            break 
        except: 
            continue
    s = randint(1, p)
    Q = P * s

    # solve ECDLP in `Zmod(n)`, where `E_p.order()` and `E_q.order()` are smooth enough.
    ans = zmodn_pohlig_hellman_attack(P, Q, p, q)

    # test.
    print(s == ans)