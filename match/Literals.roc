interface Literals
    exposes [
        match,
    ]
    imports []

match : Str, Str -> Bool
match = \pattern, text ->
    # convert pattern and text from Str to List U8, which will be more natural to work with
    patternList = Str.toUtf8 pattern
    textList = Str.toUtf8 text

    # we'll always need to consider at least 0 as a starting point since pattern may be empty
    startingPoints = List.range { start: At 0, end: At (Num.max 1 (List.len textList)) }

    # find the first starting point in `text` that `pattern` matches.
    startingPoints
    |> List.findFirst \index -> matchHere patternList (List.dropFirst textList index)
    |> Result.isOk

matchHere : List U8, List U8 -> Bool
matchHere = \pattern, text ->
    when (pattern, text) is
        ([], _) -> Bool.true
        ([p, ..], [t, ..]) if p == t ->
            matchHere (List.dropFirst pattern 1) (List.dropFirst text 1)

        _ -> Bool.false

# literal matches
expect match "a" "a" == Bool.true
expect match "b" "a" == Bool.false
expect match "a" "ab" == Bool.true
expect match "b" "abcdefgh" == Bool.true
expect match "ab" "ba" == Bool.false
expect match "" "" == Bool.true
