app "randu"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br" }
    imports [pf.Stdout, pf.Task, RNG]
    provides [main] to pf

main =
    { rngState: 1 }
    |> generatePoints 4
    |> Inspect.toStr
    |> Stdout.line

format3dPoint = \{ x, y, z } ->
    "$(Num.toStr x),$(Num.toStr y),$(Num.toStr z)"

format3dPoints = \points ->
    points
    |> List.map format3dPoint
    |> Str.joinWith "\n"

denom = Num.powInt 2 31
coeff = 65539
randuNext : U32 -> (U32, U32)
randuNext = \r0 ->
    r1 = (Num.mulWrap r0 coeff) % denom
    (r1, r0)

# generateNumber : {rngState : U32, ...} -> RngResult {rngState: U32, ...} U32
generateNumber = \state ->
    (nextRngState, number) = randuNext state.rngState
    ({ state & rngState: nextRngState }, number)

generateNumbers = \state, len ->
    generate state generateNumber len

generatePoint = \state ->
    (s1, x) = generateNumber state
    (s2, y) = generateNumber s1
    (s3, z) = generateNumber s2
    (s3, { x, y, z })

generatePoints = \state, len ->
    generate state generatePoint len

generate = \state, f, len ->
    gn = \s, acc ->
        if (List.len acc) >= len then
            (s, acc)
        else
            (nextState, n) = f s
            gn nextState (List.append acc n)
    gn state []
