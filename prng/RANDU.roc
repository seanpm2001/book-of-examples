interface RANDU
    exposes
    [
        create,
        generate,
        State,
    ]
    imports [PRNG]

State := U32

denom = Num.powInt 2 31
coeff = 65539

generate : PRNG.Generator State U32
generate = \@State r0 ->
    r1 = (Num.mulWrap r0 coeff) % denom
    (@State r1, r0)

create : U32 -> State
create = \seed -> @State seed

expect
    r1 = create 1
    (r2, x) = generate r1
    (r3, y) = generate r2
    (_, z) = generate r3
    [x, y, z] == [1, 65539, 393225]
