interface PCG
    exposes [
        create,
        generate,
        State,
    ]
    imports [PRNG]

multiplier = 6364136223846793005u64
increment = 1442695040888963407u64

State := U64

create : U64 -> State
create = \seed ->
    s = @State (seed + increment)
    (generate s).0

rotr32 : U32, U8 -> U32
rotr32 = \x, r ->
    a = Num.shiftRightZfBy x r
    b = Num.shiftLeftBy x (32 - r)
    Num.bitwiseOr a b

expect
    x = rotr32 0b11111111_00000000_10101010_01010101 8
    x == 0b01010101_11111111_00000000_10101010

newState : U64 -> U64
newState = \x ->
    x |> Num.mulWrap multiplier |> Num.addWrap increment

generate : PRNG.Generator State U32
generate = \@State s0 ->
    count = Num.shiftRightZfBy s0 59 |> Num.toU8
    x = Num.bitwiseXor s0 (Num.shiftRightZfBy s0 18)
    value = rotr32 (Num.shiftRightZfBy x 27 |> Num.toU32) count
    s1 = newState s0
    (@State s1, value)

expect
    s0 = create 1
    (s1, x) = generate s0
    (s2, y) = generate s1
    (_, z) = generate s2
    [x, y, z] == [1412771199, 1791099446, 124312908]
