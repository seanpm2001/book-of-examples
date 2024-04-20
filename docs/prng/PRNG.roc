interface PRNG
    exposes
    [
        result,
        Generator,
    ]
    imports []

Generator state value : state -> (state, value)

result = \(_, r) -> r
