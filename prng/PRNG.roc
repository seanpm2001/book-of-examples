interface PRNG
    exposes
    [
        generate,
        result,
        Generator,
    ]
    imports []

Generator state value : state -> (state, value)

generate : state, Generator state value -> (state, value)
generate = \s, g -> g s

result = \(_, r) -> r
