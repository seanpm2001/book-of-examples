---
---

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

Let's begin with a couple tests for a literal match.

```roc
expect match "a" "a" == Bool.true
expect match "b" "a" == Bool.false
expect match "a" "ab" == Bool.true
expect match "b" "abcdefgh" == Bool.true
expect match "ab" "ba" == Bool.false
expect match "" "" == Bool.true
```

That done, let's turn our attention to how we'll structure our solution. We'll approach it recursively. A `pattern` matches `text` if the first element of the pattern matches the first element of the text, and then the rest of the pattern matches the remainder of the text. Additionally, setting aside the `^` operator, a match can begin at any point in the text, so we'll need to check many possible starting points within `text` for a match.

We'll write a `match` function to consider possible starting points, and `matchHere` to check whether a particular substring matches a pattern.


```roc
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
```

Let's give particular attention to `matchHere`. Recall that we're only concerned with literal matches at this stage. We're recursively evaluating pattern for a match on text. We'll conclude it's a match if `pattern` is empty, otherwise we'll check the remainder of `pattern` against the remainder of `text` if the first element of pattern equals the first element of `text, and finally we'll conclude it's not a match if neither of those are true.

Our tests now pass, so let's extend the solution to handle wildcard matches. Again, we'll write a couple tests to get started.

```roc
expect match "." "abc" == Bool.true
expect match "a.c" "abc" == Bool.true
```

Handling this requires a simple modification to `matchHere`

```
matchHere = \pattern, text ->
    when (pattern, text) is
        ([], _) -> Bool.true
        # we'll now consider any value of t to match if p is '.'
        ([p, ..], [t, ..]) if p == t || p == '.' ->
            matchHere (List.dropFirst pattern 1) (List.dropFirst text 1)

        _ -> Bool.false
```

Great! Next up, the `^` operator, which constrains the match to occur at the beginning of the string. Tests

```roc
expect match "^a" "ab" == Bool.true
expect match "^b" "ab" == Bool.false
```

This time we'll modify `match`'s behavior
```roc
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

We're getting near the end, so fittingly we'll consider `$` next, which matches the end of `text`. We'll handle this with a small extension to `matchHere` that accepts the match if all that's left in `pattern` is `$` and text is empty.

Tests
```roc
expect match "a$" "ab" == Bool.false
expect match "a$" "ba" == Bool.true
```

```roc
matchHere = \pattern, text ->
    when (pattern, text) is
        ([], _) -> Bool.true
        # end of string
        (['$'], []) -> Bool.true
        ([p, ..], [t, ..]) if p == t || p == '.' ->
            matchHere (List.dropFirst pattern 1) (List.dropFirst text 1)

        _ -> Bool.false
```

Last up is the `*` operator, which matches zero or more repetitions of the preceeding character.

```roc
expect match "a*" "" == Bool.true
expect match "a*" "aac" == Bool.true
expect match "a*" "baac" == Bool.true
expect match "ab*c" "ac" == Bool.true
expect match "ab*b*c" "abc" == Bool.true
expect match "ab*c" "abbbc" == Bool.true
expect match "ab*c" "abxc" == Bool.false
```

We'll handle this operator by matching any character followed by a `*`, then delegating to a new function we'll write, `matchStar`

```roc
matchHere = \pattern, text ->
    when (pattern, text) is
        ([], _) -> Bool.true
        (['$'], []) -> Bool.true
        # match any character followed by a *
        ([p, '*', ..], _) -> matchStar p (List.dropFirst pattern 2) text
        ([p, ..], [t, ..]) if p == t || p == '.' ->
            matchHere (List.dropFirst pattern 1) (List.dropFirst text 1)

        _ -> Bool.false
```

`matchStart` is another recursive function. It will first consider whether the portion of `pattern` following `*` matches text. If so, it's a match. If not, we'll retry the function with the remainder of `text` if its first character matches the repeated character.

```roc
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
```

And there we have it -- passing tests! The implementation we've written is derived from [Rob Pike's in Beautiful Code](https://www.oreilly.com/library/view/beautiful-code/9780596510046/ch01.html), which is written in C. It's well worth a few minutes to read through that version to understand how the tools and abstractions a language provides affects the code that's written.
