interface Repetitions
    exposes [
        match,
    ]
    imports []

match : Str, Str -> Bool
match = \pattern, text ->
    # convert pattern and text from Str to List U8
    patternList = Str.toUtf8 pattern
    textList = Str.toUtf8 text

    # if the pattern begins with a ^, we'll only check for matches at the beginning of `text`
    if List.first patternList == Ok '^' then
        matchHere (List.dropFirst patternList 1) textList
    else
        # we'll always need to consider at least 0 as a starting point since text may be empty
        startingPoints = List.range { start: At 0, end: At (Num.max 1 (List.len textList)) }

        # find the first starting point in `text` that `pattern` matches.
        startingPoints
        |> List.findFirst \index -> matchHere patternList (List.dropFirst textList index)
        |> Result.isOk

matchHere = \pattern, text ->
    when (pattern, text) is
        ([], _) -> Bool.true
        (['$'], []) -> Bool.true
        # match any character followed by a *
        ([p, '*', ..], _) -> matchStar p (List.dropFirst pattern 2) text
        ([p, ..], [t, ..]) if p == t || p == '.' ->
            matchHere (List.dropFirst pattern 1) (List.dropFirst text 1)

        _ -> Bool.false

matchStar : U8, List U8, List U8 -> Bool
matchStar = \repeatedChar, remainingPattern, text ->
    # does the remainder of the text match the remainder of the pattern?
    if matchHere remainingPattern text then
        Bool.true
    else
        when List.first text is
            # if it's a valid repetition of repeatedChar, our answer is to consider the remaining elements of text
            Ok c if c == repeatedChar || repeatedChar == '.' ->
                matchStar repeatedChar remainingPattern (List.dropFirst text 1)
            _ -> Bool.false

s = \l ->
    when Str.fromUtf8 l is
        Ok str -> str
        _ -> crash "bad s"

# literal
expect match "a" "a" == Bool.true
expect match "b" "a" == Bool.false
expect match "a" "ab" == Bool.true
expect match "b" "abcdefgh" == Bool.true
expect match "ab" "ba" == Bool.false

# wildcard
expect match "a.c" "abc" == Bool.true

# start of string
expect match "^a" "ab" == Bool.true
expect match "^b" "ab" == Bool.false

# end of string
expect match "a$" "ab" == Bool.false
expect match "a$" "ba" == Bool.true

# repetitions
expect match "a*" "" == Bool.true
expect match "a*" "aac" == Bool.true
expect match "a*" "baac" == Bool.true
expect match "ab*c" "ac" == Bool.true
expect match "ab*c" "abc" == Bool.true
expect match "ab*b*c" "abc" == Bool.true
expect match "ab*c" "abbbc" == Bool.true
expect match "ab*c" "abxc" == Bool.false
expect match "^X.*xyz" "Xaxyz" == Bool.true
