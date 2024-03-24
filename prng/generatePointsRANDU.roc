app "generatePointsRANDU"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br" }
    imports [pf.Stdout, TestGenerators, RandomTools, PRNG, RANDU]
    provides [main] to pf

main =
    generator = RANDU.create 1
    (_, pts) = generatePoints generator RANDU.generate 1000
    pts
    |> format3dPoints
    |> Stdout.line

Point a : { x : a, y : a, z : a }

generatePoint : state, PRNG.Generator state U32 -> (state, Point U32)
generatePoint = \state0, generator ->
    (state1, x) = RandomTools.generateU32 state0 generator
    (state2, y) = RandomTools.generateU32 state1 generator
    (state3, z) = RandomTools.generateU32 state2 generator
    (state3, { x, y, z })

expect
    generatePoint 1 TestGenerators.generateInc
    |> PRNG.result
    |> Bool.isEq { x: 1, y: 2, z: 3 }

generatePoints = \state0, generator, len ->
    RandomTools.generateList state0 (\s -> generatePoint s generator) len

expect
    (_, pts) = generatePoints 1 TestGenerators.generateInc 2
    pts == [{ x: 1, y: 2, z: 3 }, { x: 4, y: 5, z: 6 }]

format3dPoint = \{ x, y, z } ->
    "$(Num.toStr x),$(Num.toStr y),$(Num.toStr z)"

format3dPoints = \points ->
    points
    |> List.map format3dPoint
    |> List.prepend "x,y,z"
    |> Str.joinWith "\n"
