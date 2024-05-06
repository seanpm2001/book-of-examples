interface Lcs
    exposes [diffFormat]
    imports []

Line := { lineNumber : U64, content : Str } implements [Eq { isEq: areLinesEqual }]

# TODO: Docstring.
areLinesEqual : Line, Line -> Bool
areLinesEqual = \@Line { content: x }, @Line { content: y } -> x == y

DiffOp : [Insertion, Deletion, Match]
DiffLine : { op : DiffOp, source : Line, target : Line }
Diff : List DiffLine

Table : Dict (U64, U64) U64

beginningMark = @Line { lineNumber: 0, content: "ε" }

DiffParameters : { colorize ? Bool, contextSize ? U64 }

# TODO: Docstring.
diffFormat : DiffParameters, List Str, List Str -> List Str
diffFormat = \params, x, y ->
    formatDiff params (diff x y)

# TODO: Docstring.
formatDiff : DiffParameters, Diff -> List Str
formatDiff = \params, input ->
    formatDiffHelp params input

# TODO: Docstring.
formatDiffHelp : DiffParameters, Diff -> List Str
formatDiffHelp = \{ colorize ? Bool.false, contextSize ? 3 }, diffResult ->
    filterDiff diffResult contextSize
    |> List.map \elem ->
        (_, source) = unpackLine elem.source
        (_, target) = unpackLine elem.target

        when elem.op is
            Match ->
                "  $(source)"

            Insertion ->
                diffLine = "+ $(target)"
                if colorize then
                    colorizeText GreenFg diffLine
                else
                    diffLine

            Deletion ->
                diffLine = "- $(source)"
                if colorize then
                    colorizeText RedFg diffLine
                else
                    diffLine

# TODO: Docstring.
unpackLine : Line -> (U64, Str)
unpackLine = \@Line { lineNumber, content } -> (lineNumber, content)

green = "\u(001b)[6;33;32m"
red = "\u(001b)[6;33;31m"
resetFormatting = "\u(001b)[0m"

# TODO: Docstring.
Color : [GreenFg, RedFg]
colorizeText : Color, Str -> Str
colorizeText = \color, input ->
    when color is
        GreenFg -> "$(green)$(input)$(resetFormatting)"
        RedFg -> "$(red)$(input)$(resetFormatting)"

Range : (U64, U64)

# TODO: Docstring.
filterDiff : Diff, U64 -> Diff
filterDiff = \diffResult, contextSize ->
    ranges = filterDiffHelp diffResult contextSize
    List.walk ranges [] \updated, (first, last) ->
        List.concat updated (slice diffResult first last)

# TODO: Docstring.
# Cases:
# - Seq start:
#   - Curr is Match
#   - 0th idx
#   - >0th idx, and the prev wasn't Match
# - Seq continuation
#   - Curr is Match and prev was Match
# - Seq end:
#   - Curr is not Match and prev was Match
#   - Curr is Match and idx indicates we're at the last diff line/element
filterDiffHelp : Diff, U64 -> List Range
filterDiffHelp = \diffResult, contextSize ->
    when List.len diffResult is
        0 -> []
        n ->
            allMatching = List.all diffResult \elem -> elem.op == Match
            if allMatching then
                []
            else
                lastDiffEntryIdx = n - 1
                (subseqRanges, _) = List.walkWithIndex diffResult ([], 0) \(ranges, latestSeqStart), elem, idx ->
                    prev : Result DiffOp [NoDiffOpBeforeSeqStart]
                    prev =
                        when idx is
                            0 -> Err NoDiffOpBeforeSeqStart
                            _ ->
                                when List.get diffResult (idx - 1) is
                                    Err OutOfBounds -> crash "Error: Unexpected out-of-bounds access in diff list"
                                    Ok prevDiffLine -> Ok prevDiffLine.op

                    when idx is
                        0 ->
                            when prev is
                                Err NoDiffOpBeforeSeqStart ->
                                    (
                                        ranges,
                                        idx,
                                    )

                                _ ->
                                    crash "TODO: Prev cannot be a match/insertion/deletion if curr idx is 0"

                        _ ->
                            when prev is
                                Ok Match ->
                                    when elem.op is
                                        Match ->
                                            if idx == lastDiffEntryIdx then
                                                (
                                                    List.concat ranges (maybeTrimRange (latestSeqStart, idx) idx contextSize),
                                                    latestSeqStart,
                                                )
                                            else
                                                (
                                                    ranges,
                                                    latestSeqStart,
                                                )

                                        _ ->
                                            prevRange = (latestSeqStart, idx - 1)
                                            matchingRange = maybeTrimRange prevRange idx contextSize
                                            rangesUpdated = List.concat ranges matchingRange

                                            if idx == lastDiffEntryIdx then
                                                (
                                                    List.append rangesUpdated (idx, idx),
                                                    idx,
                                                )
                                            else
                                                (
                                                    rangesUpdated,
                                                    idx,
                                                )

                                Ok Insertion | Ok Deletion ->
                                    when elem.op is
                                        Match ->
                                            prevRange = (latestSeqStart, idx - 1)
                                            rangesUpdated = List.append ranges prevRange
                                            if idx == lastDiffEntryIdx then
                                                (
                                                    List.concat rangesUpdated (maybeTrimRange (idx, idx) idx contextSize),
                                                    idx,
                                                )
                                            else
                                                (
                                                    rangesUpdated,
                                                    idx,
                                                )

                                        _ ->
                                            if idx == lastDiffEntryIdx then
                                                (
                                                    List.append ranges (latestSeqStart, idx),
                                                    idx,
                                                )
                                            else
                                                (
                                                    ranges,
                                                    latestSeqStart,
                                                )

                                Err NoDiffOpBeforeSeqStart ->
                                    crash "TODO: Prev must be a match/insertion/deletion if curr idx is greater than 0"

                subseqRanges

# TODO: Docstring.
slice : List elem, U64, U64 -> List elem
slice = \list, fromInclusive, untilInclusive ->
    List.sublist list { start: fromInclusive, len: 1 + untilInclusive - fromInclusive }

# TODO: Docstring.
maybeTrimRange : Range, U64, U64 -> List Range
maybeTrimRange = \(first, last), lastIdx, maxLength ->
    if first == 0 then
        if last == lastIdx then
            crash "TODO: Unexpected state, this should already have been returned as the sole range beforehand"
        else if last >= maxLength then
            [(1 + last - maxLength, last)]
        else
            [(first, last)]
    else if last == lastIdx then
        if last - maxLength + 1 <= first then
            [(first, last)]
        else
            [(first, first + maxLength - 1)]
    else if last - first + 1 <= 2 * maxLength then
        [(first, last)]
    else
        [(first, first + maxLength - 1), (1 + last - maxLength, last)]

# TODO: Docstring.
# Please, note that we're passing the original length, as that is what we need for our iterations, in terms of starting indices.
diff : List Str, List Str -> Diff
diff = \x, y ->
    xPrim = List.prepend (toLines x) beginningMark
    yPrim = List.prepend (toLines y) beginningMark
    diffHelp (buildTable xPrim yPrim) xPrim yPrim (List.len x) (List.len y)

# TODO: Docstring.
diffHelp : Table, List Line, List Line, U64, U64 -> Diff
diffHelp = \lcs, x, y, i, j ->
    (xi, up) =
        if i > 0 then
            (
                (List.get x i |> Result.withDefault beginningMark),
                (Dict.get lcs (i - 1, j) |> Result.withDefault 0),
            )
        else
            (beginningMark, 0)

    (yj, left) =
        if j > 0 then
            (
                (List.get y j |> Result.withDefault beginningMark),
                (Dict.get lcs (i, j - 1) |> Result.withDefault 0),
            )
        else
            (beginningMark, 0)

    if i > 0 && j > 0 && xi == yj then
        List.append (diffHelp lcs x y (i - 1) (j - 1)) { op: Match, source: xi, target: yj }
    else if j > 0 && (i == 0 || left >= up) then
        List.append (diffHelp lcs x y i (j - 1)) { op: Insertion, source: xi, target: yj }
    else if i > 0 && (j == 0 || left < up) then
        List.append (diffHelp lcs x y (i - 1) j) { op: Deletion, source: xi, target: yj }
    else
        []

# TODO: Docstring.
toLines : List Str -> List Line
toLines = \list ->
    List.mapWithIndex list \elem, idx -> @Line {
            lineNumber: idx + 1,
            content: elem,
        }

# TODO: Docstring.
buildTable : List a, List a -> Table where a implements Eq
buildTable = \x, y ->
    List.walkWithIndex
        x
        (Dict.empty {})
        (\tableX, xi, i ->
            List.walkWithIndex
                y
                tableX
                (\tableY, yj, j ->
                    curr =
                        if i == 0 || j == 0 then
                            0
                        else if xi == yj then
                            prevMatch = Dict.get tableY (i - 1, j - 1) |> Result.withDefault 0
                            prevMatch + 1
                        else
                            prevInsert = Dict.get tableY (i, j - 1) |> Result.withDefault 0
                            prevDelete = Dict.get tableY (i - 1, j) |> Result.withDefault 0
                            Num.max prevInsert prevDelete

                    Dict.insert tableY (i, j) curr
                )
        )

# TODO: Articulate properly in a comment that the tests aren't meant to be `roc format`able, for the purpose of intuitive readability (in terms of text alignment) of how the LCS table gets built.
## "All matches, expecting to return a blank diff"
expect
    before = [
        { op: Match, source: @Line { lineNumber: 1, content: "A" }, target: @Line { lineNumber: 1, content: "A" } },
        { op: Match, source: @Line { lineNumber: 2, content: "G" }, target: @Line { lineNumber: 2, content: "G" } },
        { op: Match, source: @Line { lineNumber: 3, content: "C" }, target: @Line { lineNumber: 3, content: "C" } },
    ]
    # TODO: Add an explanation that this can be commented out after optional fields bug gets fixed in Roc.
    # Provide a reference to a GitHub issue or a ZulipChat discussion.
    # after = filterDiff before {}
    after = filterDiff before 3
    expected = []
    after == expected

## "All matching lines filtered out"
expect
    # NOTE: We need to re-define the beginning mark here, because Roc doesn't like nested records, as per its latest version,
    # as of the time of writing.
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    before = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A" }, target: expectedBeginningMark },
        { op: Deletion,  source: @Line { lineNumber: 2, content: "G" }, target: expectedBeginningMark },
        { op: Match,     source: @Line { lineNumber: 3, content: "C" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Deletion,  source: @Line { lineNumber: 4, content: "A" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 2, content: "G" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 3, content: "A" } },
        { op: Match,     source: @Line { lineNumber: 6, content: "G" }, target: @Line { lineNumber: 4, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 7, content: "A" }, target: @Line { lineNumber: 5, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "A" }, target: @Line { lineNumber: 6, content: "C" } },
    ]
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A" }, target: expectedBeginningMark },
        { op: Deletion,  source: @Line { lineNumber: 2, content: "G" }, target: expectedBeginningMark },
        { op: Deletion,  source: @Line { lineNumber: 4, content: "A" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 3, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "A" }, target: @Line { lineNumber: 6, content: "C" } },
    ]
    after = filterDiff before 0
    after == expected

## "No matching lines filtered out"
expect
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    before = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A" }, target: expectedBeginningMark },
        { op: Deletion,  source: @Line { lineNumber: 2, content: "G" }, target: expectedBeginningMark },
        { op: Match,     source: @Line { lineNumber: 3, content: "C" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Deletion,  source: @Line { lineNumber: 4, content: "A" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 2, content: "G" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 3, content: "A" } },
        { op: Match,     source: @Line { lineNumber: 6, content: "G" }, target: @Line { lineNumber: 4, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 7, content: "A" }, target: @Line { lineNumber: 5, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "A" }, target: @Line { lineNumber: 6, content: "C" } },
    ]
    after = filterDiff before 1
    after == before

## "Some matching lines filtered out"
expect
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    before = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A" }, target: expectedBeginningMark },
        { op: Insertion, source: @Line { lineNumber: 2, content: "G" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 2, content: "G" }, target: @Line { lineNumber: 2, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 3, content: "G" }, target: @Line { lineNumber: 3, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 4, content: "G" }, target: @Line { lineNumber: 4, content: "G" } },
        { op: Deletion,  source: @Line { lineNumber: 5, content: "C" }, target: @Line { lineNumber: 4, content: "G" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 5, content: "A" } },
    ]
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A" }, target: expectedBeginningMark },
        { op: Insertion, source: @Line { lineNumber: 2, content: "G" }, target: @Line { lineNumber: 1, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 2, content: "G" }, target: @Line { lineNumber: 2, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 4, content: "G" }, target: @Line { lineNumber: 4, content: "G" } },
        { op: Deletion,  source: @Line { lineNumber: 5, content: "C" }, target: @Line { lineNumber: 4, content: "G" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G" }, target: @Line { lineNumber: 5, content: "A" } },
    ]
    after = filterDiff before 1
    after == expected

expect
    x = [
        beginningMark,
        @Line { lineNumber: 1, content: "G" },
        @Line { lineNumber: 2, content: "A" },
        @Line { lineNumber: 3, content: "C" },
    ]
    y = [
        beginningMark,
        @Line { lineNumber: 1, content: "A" },
        @Line { lineNumber: 2, content: "G" },
        @Line { lineNumber: 3, content: "C" },
        @Line { lineNumber: 4, content: "A" },
        @Line { lineNumber: 5, content: "T" },
    ]
    c = Dict.insert
    expected : Table
    expected =
        Dict.empty {}
        |> c (0, 0) 0 |> c (0, 1) 0 |> c (0, 2) 0 |> c (0, 3) 0 |> c (0, 4) 0 |> c (0, 5) 0
        |> c (1, 0) 0 |> c (1, 1) 0 |> c (1, 2) 1 |> c (1, 3) 1 |> c (1, 4) 1 |> c (1, 5) 1
        |> c (2, 0) 0 |> c (2, 1) 1 |> c (2, 2) 1 |> c (2, 3) 1 |> c (2, 4) 2 |> c (2, 5) 2
        |> c (3, 0) 0 |> c (3, 1) 1 |> c (3, 2) 1 |> c (3, 3) 2 |> c (3, 4) 2 |> c (3, 5) 2

    actual = buildTable x y
    actual == expected

expect
    # NOTE: We don't need to re-define the beginning mark here, because we're not using it as a record field value.
    x = [
        beginningMark,
        @Line { lineNumber: 1, content: "A" },
        @Line { lineNumber: 2, content: "G" },
        @Line { lineNumber: 3, content: "C" },
        @Line { lineNumber: 4, content: "A" },
        @Line { lineNumber: 5, content: "G" },
        @Line { lineNumber: 6, content: "G" },
        @Line { lineNumber: 7, content: "A" },
    ]
    y = [
        beginningMark,
        @Line { lineNumber: 1, content: "C" },
        @Line { lineNumber: 2, content: "G" },
        @Line { lineNumber: 3, content: "A" },
        @Line { lineNumber: 4, content: "G" },
        @Line { lineNumber: 5, content: "A" },
        @Line { lineNumber: 6, content: "C" },
    ]
    c = Dict.insert
    expected : Table
    expected =
        Dict.empty {}
        |> c (0, 0) 0 |> c (0, 1) 0 |> c (0, 2) 0 |> c (0, 3) 0 |> c (0, 4) 0 |> c (0, 5) 0 |> c (0, 6) 0
        |> c (1, 0) 0 |> c (1, 1) 0 |> c (1, 2) 0 |> c (1, 3) 1 |> c (1, 4) 1 |> c (1, 5) 1 |> c (1, 6) 1
        |> c (2, 0) 0 |> c (2, 1) 0 |> c (2, 2) 1 |> c (2, 3) 1 |> c (2, 4) 2 |> c (2, 5) 2 |> c (2, 6) 2
        |> c (3, 0) 0 |> c (3, 1) 1 |> c (3, 2) 1 |> c (3, 3) 1 |> c (3, 4) 2 |> c (3, 5) 2 |> c (3, 6) 3
        |> c (4, 0) 0 |> c (4, 1) 1 |> c (4, 2) 1 |> c (4, 3) 2 |> c (4, 4) 2 |> c (4, 5) 3 |> c (4, 6) 3
        |> c (5, 0) 0 |> c (5, 1) 1 |> c (5, 2) 2 |> c (5, 3) 2 |> c (5, 4) 3 |> c (5, 5) 3 |> c (5, 6) 3
        |> c (6, 0) 0 |> c (6, 1) 1 |> c (6, 2) 2 |> c (6, 3) 2 |> c (6, 4) 3 |> c (6, 5) 3 |> c (6, 6) 3
        |> c (7, 0) 0 |> c (7, 1) 1 |> c (7, 2) 2 |> c (7, 3) 3 |> c (7, 4) 3 |> c (7, 5) 4 |> c (7, 6) 4

    actual = buildTable x y
    actual == expected

expect
    x = [
        beginningMark,
        @Line { lineNumber: 1, content: "A" },
        @Line { lineNumber: 2, content: "B" },
        @Line { lineNumber: 3, content: "C" },
        @Line { lineNumber: 4, content: "D" },
        @Line { lineNumber: 5, content: "E" },
        @Line { lineNumber: 6, content: "F" },
        @Line { lineNumber: 7, content: "G" },
        @Line { lineNumber: 8, content: "H" },
    ]
    y = [
        beginningMark,
        @Line { lineNumber: 1, content: "I" },
        @Line { lineNumber: 2, content: "B" },
        @Line { lineNumber: 3, content: "C" },
        @Line { lineNumber: 4, content: "D" },
        @Line { lineNumber: 5, content: "E" },
        @Line { lineNumber: 6, content: "F" },
        @Line { lineNumber: 7, content: "J" },
        @Line { lineNumber: 8, content: "H" },
    ]
    c = Dict.insert
    expected : Table
    expected =
        Dict.empty {}
        |> c (0, 0) 0 |> c (0, 1) 0 |> c (0, 2) 0 |> c (0, 3) 0 |> c (0, 4) 0 |> c (0, 5) 0 |> c (0, 6) 0 |> c (0, 7) 0 |> c (0, 8) 0
        |> c (1, 0) 0 |> c (1, 1) 0 |> c (1, 2) 0 |> c (1, 3) 0 |> c (1, 4) 0 |> c (1, 5) 0 |> c (1, 6) 0 |> c (1, 7) 0 |> c (1, 8) 0
        |> c (2, 0) 0 |> c (2, 1) 0 |> c (2, 2) 1 |> c (2, 3) 1 |> c (2, 4) 1 |> c (2, 5) 1 |> c (2, 6) 1 |> c (2, 7) 1 |> c (2, 8) 1
        |> c (3, 0) 0 |> c (3, 1) 0 |> c (3, 2) 1 |> c (3, 3) 2 |> c (3, 4) 2 |> c (3, 5) 2 |> c (3, 6) 2 |> c (3, 7) 2 |> c (3, 8) 2
        |> c (4, 0) 0 |> c (4, 1) 0 |> c (4, 2) 1 |> c (4, 3) 2 |> c (4, 4) 3 |> c (4, 5) 3 |> c (4, 6) 3 |> c (4, 7) 3 |> c (4, 8) 3
        |> c (5, 0) 0 |> c (5, 1) 0 |> c (5, 2) 1 |> c (5, 3) 2 |> c (5, 4) 3 |> c (5, 5) 4 |> c (5, 6) 4 |> c (5, 7) 4 |> c (5, 8) 4
        |> c (6, 0) 0 |> c (6, 1) 0 |> c (6, 2) 1 |> c (6, 3) 2 |> c (6, 4) 3 |> c (6, 5) 4 |> c (6, 6) 5 |> c (6, 7) 5 |> c (6, 8) 5
        |> c (7, 0) 0 |> c (7, 1) 0 |> c (7, 2) 1 |> c (7, 3) 2 |> c (7, 4) 3 |> c (7, 5) 4 |> c (7, 6) 5 |> c (7, 7) 5 |> c (7, 8) 5
        |> c (8, 0) 0 |> c (8, 1) 0 |> c (8, 2) 1 |> c (8, 3) 2 |> c (8, 4) 3 |> c (8, 5) 4 |> c (8, 6) 5 |> c (8, 7) 5 |> c (8, 8) 6

    actual = buildTable x y
    actual == expected

expect
    c = Dict.insert
    lcs : Table
    lcs =
        Dict.empty {}
        |> c (0, 0) 0 |> c (0, 1) 0 |> c (0, 2) 0 |> c (0, 3) 0 |> c (0, 4) 0 |> c (0, 5) 0
        |> c (1, 0) 0 |> c (1, 1) 0 |> c (1, 2) 1 |> c (1, 3) 1 |> c (1, 4) 1 |> c (1, 5) 1
        |> c (2, 0) 0 |> c (2, 1) 1 |> c (2, 2) 1 |> c (2, 3) 1 |> c (2, 4) 2 |> c (2, 5) 2
        |> c (3, 0) 0 |> c (3, 1) 1 |> c (3, 2) 1 |> c (3, 3) 2 |> c (3, 4) 2 |> c (3, 5) 2

    x = [
        beginningMark,
        @Line { lineNumber: 1, content: "G" },
        @Line { lineNumber: 2, content: "A" },
        @Line { lineNumber: 3, content: "C" },
    ]
    y = [
        beginningMark,
        @Line { lineNumber: 1, content: "A" },
        @Line { lineNumber: 2, content: "G" },
        @Line { lineNumber: 3, content: "C" },
        @Line { lineNumber: 4, content: "A" },
        @Line { lineNumber: 5, content: "T" },
    ]
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "G"}, target: expectedBeginningMark },
        { op: Match,     source: @Line { lineNumber: 2, content: "A"}, target: @Line { lineNumber: 1, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 2, content: "A"}, target: @Line { lineNumber: 2, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 3, content: "C" } },
        { op: Insertion, source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 4, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 5, content: "T" } },
    ]
    lenMinus1 = \list -> List.dropFirst list 1 |> List.len
    actual = diffHelp lcs x y (lenMinus1 x) (lenMinus1 y)
    actual == expected

expect
    c = Dict.insert
    lcs : Table
    lcs =
        Dict.empty {}
        |> c (0, 0) 0 |> c (0, 1) 0 |> c (0, 2) 0 |> c (0, 3) 0 |> c (0, 4) 0 |> c (0, 5) 0 |> c (0, 6) 0
        |> c (1, 0) 0 |> c (1, 1) 0 |> c (1, 2) 0 |> c (1, 3) 1 |> c (1, 4) 1 |> c (1, 5) 1 |> c (1, 6) 1
        |> c (2, 0) 0 |> c (2, 1) 0 |> c (2, 2) 1 |> c (2, 3) 1 |> c (2, 4) 2 |> c (2, 5) 2 |> c (2, 6) 2
        |> c (3, 0) 0 |> c (3, 1) 1 |> c (3, 2) 1 |> c (3, 3) 1 |> c (3, 4) 2 |> c (3, 5) 2 |> c (3, 6) 3
        |> c (4, 0) 0 |> c (4, 1) 1 |> c (4, 2) 1 |> c (4, 3) 2 |> c (4, 4) 2 |> c (4, 5) 3 |> c (4, 6) 3
        |> c (5, 0) 0 |> c (5, 1) 1 |> c (5, 2) 2 |> c (5, 3) 2 |> c (5, 4) 3 |> c (5, 5) 3 |> c (5, 6) 3
        |> c (6, 0) 0 |> c (6, 1) 1 |> c (6, 2) 2 |> c (6, 3) 2 |> c (6, 4) 3 |> c (6, 5) 3 |> c (6, 6) 3
        |> c (7, 0) 0 |> c (7, 1) 1 |> c (7, 2) 2 |> c (7, 3) 3 |> c (7, 4) 3 |> c (7, 5) 4 |> c (7, 6) 4

    x = [
        beginningMark,
        @Line { lineNumber: 1, content: "A" },
        @Line { lineNumber: 2, content: "G" },
        @Line { lineNumber: 3, content: "C" },
        @Line { lineNumber: 4, content: "A" },
        @Line { lineNumber: 5, content: "G" },
        @Line { lineNumber: 6, content: "G" },
        @Line { lineNumber: 7, content: "A" },
    ]
    y = [
        beginningMark,
        @Line { lineNumber: 1, content: "C" },
        @Line { lineNumber: 2, content: "G" },
        @Line { lineNumber: 3, content: "A" },
        @Line { lineNumber: 4, content: "G" },
        @Line { lineNumber: 5, content: "A" },
        @Line { lineNumber: 6, content: "C" },
    ]
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A"}, target: expectedBeginningMark },
        { op: Deletion,  source: @Line { lineNumber: 2, content: "G"}, target: expectedBeginningMark },
        { op: Match,     source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 1, content: "C" } },
        { op: Deletion,  source: @Line { lineNumber: 4, content: "A"}, target: @Line { lineNumber: 1, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 5, content: "G"}, target: @Line { lineNumber: 2, content: "G" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G"}, target: @Line { lineNumber: 3, content: "A" } },
        { op: Match,     source: @Line { lineNumber: 6, content: "G"}, target: @Line { lineNumber: 4, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 7, content: "A"}, target: @Line { lineNumber: 5, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "A"}, target: @Line { lineNumber: 6, content: "C" } },
    ]
    lenMinus1 = \list -> List.dropFirst list 1 |> List.len
    actual = diffHelp lcs x y (lenMinus1 x) (lenMinus1 y)
    actual == expected

expect
    x = ["G", "A", "C"]
    y = ["A", "G", "C", "A", "T"]
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "G"}, target: expectedBeginningMark },
        { op: Match,     source: @Line { lineNumber: 2, content: "A"}, target: @Line { lineNumber: 1, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 2, content: "A"}, target: @Line { lineNumber: 2, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 3, content: "C" } },
        { op: Insertion, source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 4, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 5, content: "T" } },
    ]
    actual = diff x y
    actual == expected

expect
    x = ["A", "G", "C", "A", "G", "G", "A"]
    y = ["C", "G", "A", "G", "A", "C"]
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A"}, target: expectedBeginningMark },
        { op: Deletion,  source: @Line { lineNumber: 2, content: "G"}, target: expectedBeginningMark },
        { op: Match,     source: @Line { lineNumber: 3, content: "C"}, target: @Line { lineNumber: 1, content: "C" } },
        { op: Deletion,  source: @Line { lineNumber: 4, content: "A"}, target: @Line { lineNumber: 1, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 5, content: "G"}, target: @Line { lineNumber: 2, content: "G" } },
        { op: Insertion, source: @Line { lineNumber: 5, content: "G"}, target: @Line { lineNumber: 3, content: "A" } },
        { op: Match,     source: @Line { lineNumber: 6, content: "G"}, target: @Line { lineNumber: 4, content: "G" } },
        { op: Match,     source: @Line { lineNumber: 7, content: "A"}, target: @Line { lineNumber: 5, content: "A" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "A"}, target: @Line { lineNumber: 6, content: "C" } },
    ]
    actual = diff x y
    actual == expected

expect
    x = [
        "app \"hello\"",
        "    packages { pf: \"https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br\" }",
        "    imports [pf.Stdout]",
        "    provides [main] to pf",
        "",
        "main =",
        "    Stdout.line \"Hello!\"",
        "",
    ]
    y = [
        "app \"hello-world\"",
        "    packages { pf: \"https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br\" }",
        "    imports [pf.Stdout]",
        "    provides [main] to pf",
        "",
        "main =",
        "    Stdout.line \"HelloWorld!\"",
        "",
    ]
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "app \"hello\"" },              target: expectedBeginningMark },
        { op: Insertion, source: @Line { lineNumber: 1, content: "app \"hello\"" },              target: @Line { lineNumber: 1, content: "app \"hello-world\"" } },
        { op: Match,     source: @Line { lineNumber: 2, content: "    packages { pf: \"https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br\" }" }, target: @Line { lineNumber: 2, content: "    packages { pf: \"https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br\" }" } },
        { op: Match,     source: @Line { lineNumber: 3, content: "    imports [pf.Stdout]" },    target: @Line { lineNumber: 3, content: "    imports [pf.Stdout]" } },
        { op: Match,     source: @Line { lineNumber: 4, content: "    provides [main] to pf" },  target: @Line { lineNumber: 4, content: "    provides [main] to pf" } },
        { op: Match,     source: @Line { lineNumber: 5, content: "" },                           target: @Line { lineNumber: 5, content: "" } },
        { op: Match,     source: @Line { lineNumber: 6, content: "main =" },                     target: @Line { lineNumber: 6, content: "main =" } },
        { op: Deletion,  source: @Line { lineNumber: 7, content: "    Stdout.line \"Hello!\"" }, target: @Line { lineNumber: 6, content: "main =" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "    Stdout.line \"Hello!\"" }, target: @Line { lineNumber: 7, content: "    Stdout.line \"HelloWorld!\"" } },
        { op: Match,     source: @Line { lineNumber: 8, content: "" },                           target: @Line { lineNumber: 8, content: "" } },
    ]
    actual = diff x y
    actual == expected

expect
    x = ["A", "B", "C", "D", "E", "F", "G", "H"]
    y = ["I", "B", "C", "D", "E", "F", "J", "H"]
    expectedBeginningMark = @Line { lineNumber: 0, content: "ε" }
    expected = [
        { op: Deletion,  source: @Line { lineNumber: 1, content: "A" }, target: expectedBeginningMark },
        { op: Insertion, source: @Line { lineNumber: 1, content: "A" }, target: @Line { lineNumber: 1, content: "I" } },
        { op: Match,     source: @Line { lineNumber: 2, content: "B" }, target: @Line { lineNumber: 2, content: "B" } },
        { op: Match,     source: @Line { lineNumber: 3, content: "C" }, target: @Line { lineNumber: 3, content: "C" } },
        { op: Match,     source: @Line { lineNumber: 4, content: "D" }, target: @Line { lineNumber: 4, content: "D" } },
        { op: Match,     source: @Line { lineNumber: 5, content: "E" }, target: @Line { lineNumber: 5, content: "E" } },
        { op: Match,     source: @Line { lineNumber: 6, content: "F" }, target: @Line { lineNumber: 6, content: "F" } },
        { op: Deletion,  source: @Line { lineNumber: 7, content: "G" }, target: @Line { lineNumber: 6, content: "F" } },
        { op: Insertion, source: @Line { lineNumber: 7, content: "G" }, target: @Line { lineNumber: 7, content: "J" } },
        { op: Match,     source: @Line { lineNumber: 8, content: "H" }, target: @Line { lineNumber: 8, content: "H" } },
    ]
    actual = diff x y
    actual == expected

# TODO: Add diffFormat tests.
