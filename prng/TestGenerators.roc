## Generators for testing RNG implementations
interface TestGenerators
    exposes [
        generateInc,
        generateConstant,
        generateCycle,
    ]
    imports [PRNG]

generateInc : PRNG.Generator U32 U32
generateInc = \s -> ((s + 1), s)

expect
    s0 = 0
    (s1, x) = generateInc s0 
    (s2, y) = generateInc s1 
    (_s, z) = generateInc s2 
    (x, y, z) == (0, 1, 2)

generateConstant : PRNG.Generator U32 U32
generateConstant = \s -> (s, s)
expect
    s0 = 0
    (s1, x) = generateConstant s0
    (_s, y) = generateConstant s1
    (x, y) == (0, 0)

## NB: The type annotation I had for this was causing a compiler error
generateCycle = \{ items, idx } ->
    when List.get items idx is
        Ok n -> ({ items, idx: idx + 1 }, n)
        Err OutOfBounds -> generateCycle { items, idx: 0 }

expect
    s = { items: [1, 2, 3], idx: 0 }
    List.range { start: At 0, end: Before 10 }
    |> List.walk { state: s, items: [] } \{ state, items }, _ ->
        (newState, x) = generateCycle state
        { state: newState, items: List.append items x }
    |> .items
    |> Bool.isEq [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
