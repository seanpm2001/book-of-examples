# Pattern Matching

- Matching a simplified subset of regex grammar
  - Short background
  - Initial limited implementation
    - Recursion discussion?
    - TDD?
  - Layering on additional capabilities + making code extensible as we do

# Implementing a simplified regular expression matcher

In this chapter we'll write a pattern matcher for a simplified regular expression grammar. At this outset this may seem like a daunting problem, but we'll see it has an elegant recursive solution. Our approach will be to consider substrings in the provided text. If the first element of the text matches the first element the regular expression, we'll repeat the process for the remainder of the text and the remainder of the pattern.

We'll begin with a direct translation of Rob Pike's simplified regular expression matcher originally published in Beautiful Code [cite https://www.oreilly.com/library/view/beautiful-code/9780596510046/ch01.html].  Although Pike's implementation is in C, its approach fits Roc well, and as we develop it we'll further refine it to suit Roc.

We'll work with the following grammar.

| Character | Meaning |
|-----------| ------- |
| c | Match the literal character _c_ |
| . | Match any single character |
| ^ | Match the beginning of the string |
| $ | Match the end of the string |
| * | Match zero or more occurrences of the preceeding character |

As Brian Kernighan notes, "This is quite a useful class; in my own experience of using regular expressions on a day-to-day basis, it easily accounts for 95 percent of all instances."

Let's begin with a set of tests to guide our implementation

```roc
# literal matches
expect match "a" "a" == Bool.true
expect match "b" "a" == Bool.false
expect match "a" "ab" == Bool.true
expect match "b" "abcdefgh" == Bool.true
expect match "ab" "ba" == Bool.false

# wildcard
expect match "a.c" "abc" == Bool.true

# ^ and $
expect match "^a" "ab" == Bool.true
expect match "^b" "ab" == Bool.false
expect match "a$" "ab" == Bool.false
expect match "a$" "ba" == Bool.true

# repetitions
expect match "a*" "" == Bool.true
expect match "a*" "baac" == Bool.true
expect match "ab*c" "ac" == Bool.true
expect match "ab*c" "abc" == Bool.true
expect match "ab*b*c" "abc" == Bool.true
expect match "ab*c" "abbbc" == Bool.true
expect match "ab*c" "abxc" == Bool.false
expect match "^X.*xyz" "Xaxyz" == Bool.true
```

That done, let's write our top-level `match` function. Its role is to search `text` for starting points that match `pattern`.

```roc
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
```

We'll then take our cues from Rob Pike's C-based implementation to write `matchHere`.

```roc
matchHere : List U8, List U8 -> Bool
matchHere = \pattern, text ->
    # if the pattern is empty, we've found a match!
    if List.isEmpty pattern then
        Bool.true
        # also, if the only remaining element in the pattern is $ and text is empty, we've found a match
    else if pattern == ['$'] && List.isEmpty text then
        Bool.true
        # Some character followed by * -- we'll handle this in matchStar
    else if List.get pattern 1 == Ok '*' then
        when List.first pattern is
            Ok ch -> matchStar ch (List.dropFirst pattern 2) text
            _ -> Bool.false
        # match either a literal match or a wildcard
    else if List.first pattern == Ok '.' || List.first pattern == List.first text then
        matchHere (List.dropFirst pattern 1) (List.dropFirst text 1)
        # if none of the following cases are true, text does not match pattern
    else
        Bool.false
```

and `matchStar`

```roc
matchStar : U8, List U8, List U8 -> Bool
matchStar = \ch, pattern, text ->
    # does the remainder of the text match the remainder of the pattern?
    if matchHere pattern text then
        Bool.true
    else
        when List.first text is
            # if it's a valid repetition of ch, our answer is to consider the remaining elements of text
            Ok c if c == ch || ch == '.' -> matchStar ch pattern (List.dropFirst text 1)
            _ -> Bool.false
```

With that, our tests pass -- incredible! Let's push onward and see whether we can improve the readability of `matchHere` with Roc's pattern matching. Consider the following change


```roc
matchHere = \pattern, text ->
    when pattern is
        [] -> Bool.true
        ['$'] if List.isEmpty text -> Bool.true
        [ch, '*', .. as remainingPattern] -> matchStar ch remainingPattern text
        [c, .. as remainingPattern] if c == '.' -> #  (ch == '.' || Ok ch == List.first text)
            matchHere remainingPattern (List.dropFirst text 1)

        _ -> Bool.false
```

We've substantially improved on the initial version. Using `when pattern is` concisely show that we're primarily considering `pattern`'s value, and destructuring saves the clutter of selecting elements like `remainingPattern` while also more clearly communicating their role.
