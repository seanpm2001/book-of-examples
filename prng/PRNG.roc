interface PRNG
    exposes
    [
        generate,
        Generator,
        Map,
        apply,
    ]
    imports []

Generator state value : state -> (state, value)

generate : state, Generator state value -> (state, value)
generate = \s, g -> g s

Map state a b : Generator state a -> Generator state b

apply : Generator state a, Map state a b -> Generator state b
apply = \g, m -> m g
