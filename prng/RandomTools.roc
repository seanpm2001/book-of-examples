interface RandomTools
    exposes [
        generateList,
        generateU32,
        generateU64,
        generateU32UpTo,
        generateU64UpTo,
        shuffle,
    ]
    imports [PRNG, TestGenerators]

BaseGenerator state : PRNG.Generator state U32

generateU32 : state, BaseGenerator state -> (state, U32)
generateU32 = \state, generator -> PRNG.generate state generator
expect
    (s1, x) = generateU32 1 TestGenerators.generateInc
    (_s2, y) = generateU32 s1 TestGenerators.generateInc
    (x, y) == (1, 2)

generateList : state, PRNG.Generator state value, U64 -> (state, List value)
generateList = \state, generator, len ->
    generateListStep = \s, acc ->
        if (List.len acc) >= len then
            (s, acc)
        else
            (nextState, n) = PRNG.generate s generator
            generateListStep nextState (List.append acc n)
    generateListStep state []

expect
    generateList 1 TestGenerators.generateInc 10
    |> PRNG.result
    |> Bool.isEq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
expect
    (_, xs) = generateList { items: [1, 2, 3], idx: 0 } TestGenerators.generateCycle 10
    xs == [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]

makeU64 : U32, U32 -> U64
makeU64 = \x32, y32 ->
    x64 = Num.toU64 x32
    y64 = y32 |> Num.toU64 |> Num.shiftLeftBy 32
    Num.add x64 y64

expect (makeU64 0 0) == 0
expect (makeU64 1 0) == 1
expect (makeU64 Num.maxU32 0) == Num.toU64 Num.maxU32
expect (makeU64 0 Num.maxU32) == Num.maxU32 |> Num.toU64 |> Num.shiftLeftBy 32
expect (makeU64 Num.maxU32 Num.maxU32) == Num.maxU64
expect
    x = 0b11010111_10010100_10010110_01000010
    y = 0b11110110_01011001_10101111_01000101
    (makeU64 x y) == 0b11110110_01011001_10101111_01000101_11010111_10010100_10010110_01000010

generateU64 : state, BaseGenerator state -> (state, U64)
generateU64 = \state, generator ->
    (s1, a) = PRNG.generate state generator
    (s2, b) = PRNG.generate s1 generator
    (s2, makeU64 a b)

expect
    (_, x) = generateU64 1 TestGenerators.generateInc
    x == 0b00000000_00000000_00000000_00000010_00000000_00000000_00000000_00000001

rejectForModuloBias = \generated, limit, maxvalue ->
    v = generated % limit
    generated - v > maxvalue - limit

expect rejectForModuloBias 3 5 32 == Bool.false
expect rejectForModuloBias 31 5 32 == Bool.true

generateU32UpTo : state, BaseGenerator state, U32 -> (state, U32)
generateU32UpTo = \state, g32, limit ->
    tryU32 : state -> (state, U32)
    tryU32 = \s ->
        (t, r) = g32 s
        if rejectForModuloBias r limit Num.maxU32 then
            # We've hit modulo bias; try again
            tryU32 t
        else
            (t, r % limit)
    when limit is
        0 -> (state, 0)
        _ -> tryU32 state

expect
    generateU32UpTo 1 TestGenerators.generateInc 5
    |> PRNG.result
    |> Bool.isEq 1
expect
    generateList 1 (\s -> generateU32UpTo s TestGenerators.generateInc 3) 10
    |> PRNG.result
    |> Bool.isEq [1, 2, 0, 1, 2, 0, 1, 2, 0, 1]

generateU64UpTo : state, BaseGenerator state, U64 -> (state, U64)
generateU64UpTo = \state, g32, limit ->
    tryU64 : state -> (state, U64)
    tryU64 = \s ->
        (t, r) = generateU64 s g32
        if rejectForModuloBias r limit Num.maxU64 then
            # We've hit modulo bias; try again
            tryU64 t
        else
            (t, r % limit)
    when limit is
        0 -> (state, 0)
        _ -> tryU64 state

expect
    limit = 5
    (_, x) = generateU64UpTo 1 TestGenerators.generateInc limit
    x == 0b00000000_00000000_00000000_00000010_00000000_00000000_00000000_00000001 % limit
expect
    limit = 3
    (_, xs) = generateList 1 (\s -> generateU64UpTo s TestGenerators.generateInc limit) 10
    List.all xs (\x -> x < limit)

shuffle : state, BaseGenerator state, List a -> (state, List a)
shuffle = \s, g32, xs ->
    when List.len xs is
        0 -> (s, [])
        1 -> (s, xs)
        _ -> actuallyShuffle s g32 xs

actuallyShuffle = \state, g32, xs ->
    n = List.len xs
    List.range { start: At 0, end: At (n - 2) }
    |> List.walk
        (state, xs)
        \(s, ys), idx ->
            (newState, j) = generateU64UpTo s g32 (n - idx)
            (newState, List.swap ys idx j)

expect
    shuffle 1 TestGenerators.generateInc [1, 2, 3, 4]
    |> PRNG.result
    |> Bool.isEq [2, 3, 1, 4]
