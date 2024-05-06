---
---

- The difference between two sequences can be represented as a conversion of a source sequence to a target sequence, via applying a series of insertion, deletion and matching operations, in an element-wise manner.
- Being able to represent the differences between two files is a fundamental feature of version-control systems, whereby it serves to display a commit, the difference between two commits and assist in branch merging operations.
- Context is important when representing differences, and different formats may choose to achieve this via take advantage of context in different ways.

Terms defined: ability, diff, dynamic programming, longest common subsequence, memoization, merge, opaque type, platform, version-control system

1. [Representation](#section-n1-representation)
2. [Longest Common Subsequence (LCS)](#section-n2-longest-common-subsequence-lcs)
3. [Colorized Output](#section-n3-colorized-output)
4. [Diff Context](#section-n4-diff-context)
5. [Unified Format](#section-n5-unified-format)
6. [Putting It All Together](#section-n6-putting-it-all-together)
7. [Summary](#section-n7-summary)
8. [Exercises](#section-n8-exercises)

In this chapter, we're going to develop a tool capable of identifying and outputting the differences between two files in a suitable format and presentation. The associated fundamental concepts are integral to version-control systems, because they lie at the very core of operations such as `git diff` and `git merge`.

Let's examine the following output, from the UNIX `diff` tool, between two toy Roc programs. We can safely ignore the `-u` argument for the time being.

```diff
$ diff -u Hello.roc HelloWorld.roc
--- Hello.roc <last_modified_timestamp>
+++ HelloWorld.roc <last_modified_timestamp>
@@ -1,8 +1,8 @@
-app "hello"
+app "hello-world"
     packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
     imports [pf.Stdout]
     provides [main] to pf

 main =
-    Stdout.line "Hello!"
+    Stdout.line "Hello, World!"

```

Even if you weren't familiar with the UNIX `diff` or similar tools, it's probably quite obvious what's going on. The command output tells you that the given files differ in terms of two lines only - namely, the first and last lines, namely the lines defining the app name and outputting a string to the standard output.

By the end of this chapter, you will have developed a Roc tool, which outputs identical information, given the same two input files.

## Section N.1: Representation

In the above example, the output was presented intuitively enough, and this enabled us to identify easily what it conveys. For completeness, the listings of the two files are as follows:
```roc
$ cat Hello.roc
app "hello"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
    imports [pf.Stdout]
    provides [main] to pf

main =
    Stdout.line "Hello!"

$ cat HelloWorld.roc
app "hello-world"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
    imports [pf.Stdout]
    provides [main] to pf

main =
    Stdout.line "Hello, World!"

```

The difference between same two files - without any modifications to the files themselves - could be represented alternatively like so:
```diff
$ uglydiff Hello.roc HelloWorld.roc
--- Hello.roc <last_modified_timestamp>
+++ HelloWorld.roc <last_modified_timestamp>
@@ -1,8 +1,8 @@
+app "hello-world"
-app "hello"
     packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
     imports [pf.Stdout]
     provides [main] to pf

 main =
+    Stdout.line "Hello, World!"
-    Stdout.line "Hello!"

```

And even like so:
```diff
$ uglierdiff Hello.roc HelloWorld.roc
--- Hello.roc <last_modified_timestamp>
+++ HelloWorld.roc <last_modified_timestamp>
@@ -1,8 +1,8 @@
-app "hello"
-    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
-    imports [pf.Stdout]
-    provides [main] to pf
-
-main =
-    Stdout.line "Hello!"
-
+app "hello-world"
+    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
+    imports [pf.Stdout]
+    provides [main] to pf
+
+main =
+    Stdout.line "Hello, World!"
+
```

Now, what makes the output from `diff` much more useful and immediately intuitive than its counterparts from the hypothetical `uglydiff` and `uglierdiff` tools? It succinctly presents the actual differences and doesn't distract away from those differences. In the hypothetical, non-intuitive cases, we see that - despite those being still valid representations of differences - the degree of usefulness isn't as high as it could be. In the first case, instead of the more natural flow "from this file, we arrive at that file", we are presented with a "we introduce this, whilst originally we had that", which awkwardly interrupts the reader's flow. In the latter case, no useful intuition regarding the actual differences is conveyed, because any two distinct files could be crudely viewed as differing in their corresponding line sequences atomically. In other words, we could replace all lines from the first file with all lines from the second file and this, effectively, constitutes the difference between them.

## Section N.2: Longest Common Subsequence (LCS)

In this section, we'll get acquainted with a data structure which will enable us to express all possible paths that correspond to constructing a target file from a source file, based on a number of insertion, deletion and matching operations. Then we'll build intuition, regarding how we could heuristically traverse said data structure, in order to be able to choose a single path, which will be the path ultimately presented as the one, succinctly and intuitively representing the difference between the two files.

This automatically means that we wouldn't want to be considering matching blocks of lines from the two files as differences (as it was unfortunately the case with the hypothetical `uglierdiff` tool). This is where an important observation lies - one key ingredient we need is a method for identifying the longest possible stretches of matching sequences between the given files. The other key ingredient is that, if we're to view a diff between two files as a means for transforming one file into another one (even though this may not be be the actual desired outcome at all, you'll see that this is a very useful conceptual representation), then the first one could be viewed as a "source", and the second one - as a "target". Correspondingly, the chain of operations transforming our source into the target will be the ultimate diff output. Therefore, in addition to identifying long stretches of matching lines between the two files, we'll also be interested in thinking in terms of removals of lines from the source file and preservations (or insertions, with respect to the former) of lines that are already present in the target file, but not in the former. Naturally, we won't be performing any modifications to stretches of matching elements between the two sequences. Those are the parts of our output which we would ideally like to keep out of focus as much as possible. They could be useful to provide context, but they shouldn't be at the center of attention.

This particular representation is also referred to as _unified format_, in the context of the GNU `diff` tool, and that was the relevance of the `-u` command-line argument  in the opening paragraph (alternatively accessible via the `--unified` flag). Some alternative representations, which we won't be discussing in this chapter are the _normal format_ (`--normal`) and _context format_ (`-c` or `--context`). They're closely related and are possible to be derived - with relatively minor modifications - using the approaches which we'll get acquainted with in this chapter. Naturally, for further details and even more possible representations, you're welcome to refer to GNU `diff`'s `man` pages.

Let's step back a bit and try to think in what domains we'd expect to see applications of the kind of algorithms are relevant to our use case. Given two or more sequences of comparable-for-equality items, it is of interest to identify the longest possible subsequences of items which are equal between the sequences under consideration.

- For instance, in bioinformatics and molecular biology, DNA sequences can be represented via the symbols A, C, G and T which correspond to the four nucleobases, associated with DNA molecules, namely adenine, cytosine, guanine and thymine. One possible use-case is comparison between DNA sequences for the purpose of capturing some notion of similarity, for instance, with respect to a new DNA sequence. Then, one form of a similarity metric is finding the longest common subsequence between the input sequences.
- In computational linguistics, two strings may be compared for similarity in multiple ways, and the longest common subsequence is one way of solving the approximate string matching problem.
- In terminal-based text editor implementations, screen redisplay may be viewed as the minimum length sequence of characters that need to be changed in order for the screen update to be performed, in accordance to file changes. The longest common subsequence is relevant in that context, because it delineates the parts of the screen that don't need updating.
- Identifying differences between files, which is the main topic of this chapter.

For simplicity and ease of visualization, let's consider pairs of strings of characters, which are equivalent - relative to each other - to the source-code example from the beginning section. Two arbitrary string sequences - where each character is a line in a file - which meet these needs are the following ones:
```bash
$ cat source.txt
A
B
C
D
E
F
G
H
```
```bash
$ cat target.txt
I
B
C
D
E
F
J
H
```

The corresponding most intuitive diff path is as follows:
```diff
$ diff -u source.txt target.txt
--- source.txt <last_modified_timestamp>
+++ target.txt <last_modified_timestamp>
@@ -1,8 +1,8 @@
@@ -1,8 +1,8 @@
-A
+I
 B
 C
 D
 E
 F
-G
+J
 H
```

```
# TODO: Ensure consistent terminology, in terms of the input lists/strings/arrays/sequences. It may be confusing, if referred to as sequences.
```

As discussed, we'll first focus on finding a way to conveniently identify and represent all possible paths from the source sequence to the target sequence. Only then we'll be able to pick the path which conveys the difference in a generally intuitive way, given the aforementioned presentation constraints we're interested to enforce.

We'll resort to a class of algorithms for solving what's referred to as the _Longest Common Subsequence_ (LCS) problem. One of the most common problem-solving approaches is breaking a problem into equivalent but smaller sub-problems. This very intuition is also applicable in our case. In order to identify the longest common subsequence between any two lists of elements, we observe that we would start with an empty common subsequence, and then seek to incrementally find matching elements in each list, in order to identify longer and longer subsequences until we've exhausted at least one of the lists. There exist no general shortcuts which would allow us to generally identify the longest common subsequence without iterating over the contents of both lists first. That's why the problem of identifying a longest common subsequence gets conveniently and intuitively broken down to be defined recursively in terms of the solutions at different iteration steps. The longest common subsequence as of the current step _t_ is defined to be equal to the longest common subsequence as of step _t-1_, in conjunction with the best possible solution at step _t_, among the following options:
- the two current elements in each list are already a match, or
- removing the current element from the source list results in a match, or
- inserting the next element from the target list results in a match.

Let's see how we might implement a Roc function, which will give us an arbitrary longest subsequence, that is common to two lists of elements:
```roc
lcs : List a, List a -> List a where a implements Eq
lcs = \xxs, yys ->
    when (xxs, yys) is
        ([], _) -> []
        (_, []) -> []
        _ ->
            { before: x, others: xs } = List.split xxs 1
            { before: y, others: ys } = List.split yys 1
            if x == y then
                List.concat x (lcs xs ys)
            else
                longest (lcs xxs ys) (lcs xs yys)

longest = \xs, ys ->
    if List.len xs > List.len ys then xs else ys
```

Before we discuss the concrete Roc features that we utilize in this excerpt, let's briefly go over the core idea behind the `lcs` function. It takes two lists and recursively calls itself in order to return an arbitrary longest common subsequence, with respect to the input lists. The recursive calls follow the logic discussed above, namely they contain solutions to sub-problems, which are then concatenated together to form a valid solution to the main problem. Concretely, with respect to any two lists that are being considered as part of the execution flow, we check whether either of them is empty. If yes, we know that we've traversed as much as we could along that particular list and that's our cue to stop our iteration. If they're both non-empty, however, then we inspect the elements at their very beginning. If the elements are equal, then we take a note of the element value and we add it as an element belonging to the longest common subsequence solution. Then, we analogously inspect the remainders of the lists. If the elements aren't equal, we branch off recursively to identify from which list we should skip the non-matching element, in order to ultimately arrive at a longest possible solution. For this purpose, we also employ an auxiliary function `longest`, which ensures that we pick the longest branch, with respect to any solution to a sub-problem.

In the `lcs` function, we take advantage of multiple Roc features. First, the type parameter `a` indicates that this function works with respect to lists of an arbitrary type, as long as that's the type associated with both lists. The constraint `where a implements Eq` signifies that we're making use of the abilities feature. In this case, we refer to the built-in `Eq` ability which requires that the corresponding type implements this ability, in order for us to be able to compare any two associated values for equality. In the function body, we perform pattern matching on both of the input lists, via packing them in a tuple. This allows us to define our stopping condition - we check if either list is empty, and if yes - we return an empty list. This is handy, because it allows us to recursively call the same function to traverse the lists and extract an arbitrary longest common subsequence at any execution step. We also note the employment of the standard library `List.split` function, which takes an arbitrary list and an index, and splits the list at that index, returning a record consisting of two fields, namely `before` and `others` lists. The former contains all the elements preceding the input index, at which we want to split our original list, and the latter - all elements that follow afterwards. Please, note that the function doesn't trim away any elements, and that at least one of the returned record fields may be an empty list. In our case, however, we don't need to check whether or not the `before` list is empty, because that was already taken care of by the base cases in our preceding pattern matching expressions.

Please, note that - as discussed above - as of step _t_, multiple paths may correspond to the longest solution. This is expected, because in this first stage, we are only interested in finding _all_ paths, and not necessarily picking a "best" path just yet.

You'll also notice that each complete path (that is, a solution leading from a source list to a target list) corresponds to a unique diff presentation.

```
## TODO:
- A narrative transition and a couple of equations which briefly introduce how the dynamic programming table is built.
Define a subsequence to be any output string obtained by deleting zero or more symbols from an input string.
The Longest Common Subsequence (LCS) is a subsequence of maximum length common to two or more strings.

S[i, j] = ...
where S[i, j] corresponds to the solution as of current step _t_ being at index _i_ in the first list and index _j_ in the second one, i.e., X_i and Y_j, respectively.

First property:
LCS(X ^ c, Y ^ c) = LCS(X, Y) ^ c, for all symbols c
e.g.,
LCS("ACGGT", "TCGT") = LCS("ACGG", "TCG") ^ "T" = LCS("ACG", "TC") ^ "GT"

Second property:
For all p and q, such that p != q, i.e., they are distinct symbols,
LCS(X ^ p, Y ^ q) is in the set LCS(X ^ p, Y) <set_union> LCS (X, Y ^ q) and not only this but it is also one of the maximal-length strings in that set.

For example,
LCS("ACGGTA", "TCGTC") is the longest common string among the longest common substrings which belong to the set union of LCS("ACGGTA", "TCGT") and LCS("ACGGT", "TCGT").

LCS(X_i, Y_j) =
ε, if i = 0 or j = 0
LCS(X_{i-1}, Y_{j-1})^x_i, if i > 0 and j > 0 and x_i = y_j
LCS(max(X_{i-1}, Y_j)^x_i, LCS(X_{i-1}, Y_j)), if i > 0 and j > 0 and x_i != y_j

Wiki excerpt:
To find the LCS of }} and }}, compare }} and }}. If they are equal, then the sequence }(X_,Y_)}}(X_,Y_)} is extended by that element, }}. If they are not equal, then the longest among the two sequences, }(X_,Y_)}}(X_,Y_)}, and }(X_,Y_)}}(X_,Y_)}, is retained. (If they are the same length, but not identical, then both are retained.) The base case, when either }} or }} is empty, is the empty string, .

TODO: Introduce and discuss the significance of ε.

LCS("ABCDEFGH", "IBCDEFJH") = LCS("ABCDEFG", "IBCDEFJ") ^ "H
LCS("ABCDEFG", "IBCDEFJ") is a maximal-length string in the set LCS("ABCDEFG", "IBCDEF") <set_union> LCS("ABCDEF", "IBCDEFJ")


LCS("ε", c) = 0 for all symbols `c`
LCS(c, "ε") = 0 for all symbols `c`

LCS("ε", "ε") = 0
LCS("εA", "ε" ^ S) = 0 for `S` in {"", "I", "IB", "IBC", "IBCD", "IBCDE", "IBCDEF", "IBCDEFJ", "IBCDEFJH"}
LCS("ε" ^ S, "εI") = 0 for `S` in {"", "A", "AB", "ABC", "ABCD", "ABCDE", "ABCDEF", "ABCDEFG", "ABCDEFGH"}
LCS("εAB", "εIB" ^ S) = 1 for `S` in {"", "C", "CD", "CDE", "CDEF", "CDEFJ", "CDEFJH"} because i, j-1 and i-1, j ...
LCS("εAB" ^ S, "εIB") = 1 for `S` in {"", "C", "CD", "CDE", "CDEF", "CDEFG", "CDEFGH"} ...
LCS("εABC", "εIBC" ^ S) = 2 for `S` in {"", "D", "DE", "DEF", "DEFJ", "DEFJH"} ...
LCS("εABC" ^ S, "εIBC") = 2 for `S` in {"", "D", "DE", "DEF", "DEFG", "DEFGH"} ...
...
LCS("εABCDEFGH", "εIBCDEFJH") = 6

```

Conceptually, we've already built the data structure which will allow us to recover any path or a sub-path, corresponding to a full or partial solution to our problem of identifying differences between two lists of elements.

The conventional way to build the data structure is in a tabular form. We arbitrarily set the row headers to correspond to the elements of the source list and the column headers - to those of the target one.

The complete table is as follows:

|       |   ε   |   I   |   B   |   C   |   D   |   E   |   F   |   J   |   H   |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|   ε   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |
|   A   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |
|   B   |   0   |   0   |   1   |   1   |   1   |   1   |   1   |   1   |   1   |
|   C   |   0   |   0   |   1   |   2   |   2   |   2   |   2   |   2   |   2   |
|   D   |   0   |   0   |   1   |   2   |   3   |   3   |   3   |   3   |   3   |
|   E   |   0   |   0   |   1   |   2   |   3   |   4   |   4   |   4   |   4   |
|   F   |   0   |   0   |   1   |   2   |   3   |   4   |   5   |   5   |   5   |
|   G   |   0   |   0   |   1   |   2   |   3   |   4   |   5   |   5   |   5   |
|   H   |   0   |   0   |   1   |   2   |   3   |   4   |   5   |   5   |   6   |

As you can see, we conventionally take a note of the length of the longest common subsequence found as of a given iteration step. This isn't really fundamental to our difference representation problem, but will come in handy at the stage when we'll need to heuristically decide which path to present as the ultimate solution. The other bit of information that we take a note of is somehow more relevant, namely the operation which we perform at a given iteration step, based on the equality between the current list elements `X`<sub>`i`</sub> and `Y`<sub>`j`</sub> as of that iteration step.

Once we've built the table, it becomes obvious that all solutions correspond to movements along the table cells in one of three possible directions at a time: right, down or diagonally right-down. The complete paths - which are effectively possible solutions to the diff problem - correspond to moves from the top left cell to the bottom right cell.

The most intuitive path and solution discussed before is the following one:

|       |   ε   |   I   |   B   |   C   |   D   |   E   |   F   |   J   |   H   |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|   ε   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |
|   A   |  ↑0   |  ←0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |
|   B   |   0   |   0   |  ↖1   |   1   |   1   |   1   |   1   |   1   |   1   |
|   C   |   0   |   0   |   1   |  ↖2   |   2   |   2   |   2   |   2   |   2   |
|   D   |   0   |   0   |   1   |   2   |  ↖3   |   3   |   3   |   3   |   3   |
|   E   |   0   |   0   |   1   |   2   |   3   |  ↖4   |   4   |   4   |   4   |
|   F   |   0   |   0   |   1   |   2   |   3   |   4   |  ↖5   |   5   |   5   |
|   G   |   0   |   0   |   1   |   2   |   3   |   4   |  ↑5   |  ←5   |   5   |
|   H   |   0   |   0   |   1   |   2   |   3   |   4   |   5   |   5   |  ↖6   |

Correspondingly, the least intuitive solution corresponds to this path:

|       |   ε   |   I   |   B   |   C   |   D   |   E   |   F   |   J   |   H   |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|   ε   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |
|   A   |  ↑0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |   0   |
|   B   |  ↑0   |   0   |   1   |   1   |   1   |   1   |   1   |   1   |   1   |
|   C   |  ↑0   |   0   |   1   |   2   |   2   |   2   |   2   |   2   |   2   |
|   D   |  ↑0   |   0   |   1   |   2   |   3   |   3   |   3   |   3   |   3   |
|   E   |  ↑0   |   0   |   1   |   2   |   3   |   4   |   4   |   4   |   4   |
|   F   |  ↑0   |   0   |   1   |   2   |   3   |   4   |   5   |   5   |   5   |
|   G   |  ↑0   |   0   |   1   |   2   |   3   |   4   |   5   |   5   |   5   |
|   H   |  ↑0   |  ←0   |  ←1   |  ←2   |  ←3   |  ←4   |  ←5   |  ←5   |  ←6   |

This visual representation enables us to build further intuition regarding the desired solution form. Heuristically speaking, we observe that favorable solutions will involve, wherever applicable, long stretches of deletions from the source list and long stretches of insertions from the target list, interspersed with long stretches of matching (i.e., common) subsequences.

Now let's try to build the data structure in Roc.

```roc
Table : Dict (U64, U64) U64

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
```

Our `buildTable` function takes two arbitrary lists of the same type and builds an LCS table, which is returned to the caller. The type itself is guaranteed to implement the built-in `Eq` ability, and the table is of type `Dict (U64, U64) U64`. The latter corresponds to a dictionary whose keys are tuples of `(i, j)` table indices, both of type `U64` and the value corresponds to the length of the longest common subsequence associated with the sublists, of the input lists, ending at indices `i` and `j`. We utilize the standard library `List.walkWithIndex` function to iterate row by row, and element by element, within each row.
`Result.withDefault 0` is logically never expected to become effective, because the indices `i` and `j` are iterated over in order and all previous entries will have been present. Further, the base cases where the boundaries of the table are delineated are already handled via `if i == 0 || j == 0 then 0`. Alternatively, we could've pattern matched for each of the possible previous-step operations - namely, match, insertion or deletion - and `crash`ed with an indicative enough message, if we ever got an error of type `KeyNotFound`, because something fundamental had gone wrong at that stage, and wasn't possible to be caught via our test suite.

Our next step is to actually traverse the data structure we've just built, and find our way through it via what we deem heuristically to be the best path, in order to ultimately arrive at an intuitive solution.

```roc
beginningMark = "ε"

diff : List Str, List Str -> List Str
diff = \x, y ->
    xPrim = List.prepend x beginningMark
    yPrim = List.prepend y beginningMark
```

We begin by prepending the sentinel value `ε` to our lists, so that we can define the base-cases in our dynamic programming solution. We also define a helper function, `diffHelp`, which takes as inputs the already-built table, the updated lists, and the 0-based indices, corresponding to the last element in each list. In other words, we start at the bottom right of our table and proceed to complete our traversal at top left cell. We explicitly pass the current indices to `diffHelp` because we would like to be able to call it recursively, and only stop once we've completed the traversal of our LCS table.

```roc
diff : List Str, List Str -> List Str
diff = \x, y ->
    xPrim = List.prepend x beginningMark
    yPrim = List.prepend y beginningMark
    diffHelp (buildTable xPrim yPrim) xPrim yPrim (List.len x) (List.len y)

diffHelp : Table, List Str, List Str, U64, U64 -> List Str
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
        List.append (diffHelp lcs x y (i - 1) (j - 1)) "  $(xi)"
    else if j > 0 && (i == 0 || left >= up) then
        List.append (diffHelp lcs x y i (j - 1)) "+ $(yj)"
    else if i > 0 && (j == 0 || left < up) then
        List.append (diffHelp lcs x y (i - 1) j) "- $(xi)"
    else
        []
```
We store the current element values of the lists in `xi` and `yj` respectively; `up` and `left` are the LCS lengths associated with the cells above and to tte left of the current cell. If the current elements are equal, we proceed diagonally in a top-left direction, because the reverse operation, i.e., moving in a bottom-right direction corresponds to matching the current elements and effectively "skipping" them, without performing either insertion or deletion. If however, the LCS length in the cell to the left is greater than or equal to the cell above, then we proceed with our traversal to the left. Otherwise, we move up. This is because we've established that intuitively we would like to arrange the diff operations in such way, so that deletion operations from the source list come before the insertion operations from the target list. And when we're traversing the table backwards, we give priority to the latter, when the correponding LCS lengths are equal.

Additionally, upon each conditional branch, we check the boundary condition of whether we're either at the `0`th row or `0`th column.

## Section N.3: Colorized Output

Now, when we think about representation of differences between files, we usually have some expectation regarding color-coding as well, in order to better highlight what the associated operations which constitute the diff are. It is important to note that the GNU `diff` tool doesn't provide color-coding per se, but it instead formats the output in a standardized way, so that the associated representation could optionally undergo subsequent syntax highlighting via other tools, editors or IDEs, as applicable.

In this section we'll briefly introduce some rudimentary color-coding to our diff output, and in the following one we'll generalize our post-processing logic, which will enable us to perform color-coding in a bit more elegant manner. It'll also enable us to perform other post-processing steps, for the purpose of increasing the degree of interpretability of the output.

We'll follow `git`'s diff representation, namely colorizing lines corresponding to insertions in green, and those corresponding to deletions - in red. Please, note that this doesn't take any special consideration of terminal emulator themes, nor any other external context.

Practically speaking, terminal output colorization is achieved via what are referred to as ANSI escape codes. We prepend a sequence of characters to the line to denote that we want a foreground color to be applied to all characters on that line. In order to preserve the formatting on lines where the same diff operation doesn't apply, we append an escape code for resetting the formatting at the end of each colorized line, namely `"\u(001b)[0m"`. The escape codes for green and red foreground colors are `"\u(001b)[6;33;32m"` and `"\u(001b)[6;33;31m"`, respectively.

For further details, please, refer to the "Colors" section of Wikipedia's "ANSI escape code" page[^1]. Now let's implement a simple text colorization function.

[^1]: https://en.wikipedia.org/wiki/ANSI_escape_code#Colors.

```roc
green = "\u(001b)[6;33;32m"
red = "\u(001b)[6;33;31m"
resetFormatting = "\u(001b)[0m"

Color : [GreenFg, RedFg]
colorizeText : Color, Str -> Str
colorizeText = \color, input ->
    when color is
        GreenFg -> "$(green)$(input)$(resetFormatting)"
        RedFg -> "$(red)$(input)$(resetFormatting)"
```

And just like this, we're able to arbitrarily apply colors to text. Our diff operations are color-coded - insertions in green and deletions in red. Please, note that the color choices are arbitrary in this case. It would be equally seamless to colorize the background of each line, i.e., achieve some sort of highlighting, via employing `"\u(001b)[6;33;42m"` and `"\u(001b)[6;33;41m"` for green and red, correspondingly. This is because background colors span over the 40 to 48 escape-code range.

```roc
    else if j > 0 && (i == 0 || left >= up) then
        List.append (diffHelp lcs x y i (j - 1)) (colorizeText GreenFg "+ $(yj)")
    else if i > 0 && (j == 0 || left < up) then
        List.append (diffHelp lcs x y (i - 1) j) (colorizeText RedFg "- $(xi)")
```

By putting our `colorizeText` function to use in our `diffHelp` function, we're now able to associate our colorization preferences to the insertion and deletion operations.

## Section N.4: Diff Context

So far, our diff output serves the job as advertized. However, if we consider real-world examples for file changes, it is not at all unlikely that a change in a file may involve a handful of lines, whilst the total file size in terms of number of lines may be in the hundreds or even thousands.

This is actually a tricky class of cases that our tool, at the current stage of its development, is likely to not be able to handle well at all. We might have to manually scroll through the output or filter by diff marks, in order to identify where _exactly_ the differences are. This suggests that most of the context in such cases isn't really useful, if we would be filtering it out eventually. What could we do to improve our tool, with respect to this? We might want to introduce the notion of context, in terms of line adjacency, and only display up to a certain number of lines away from each contiguous set of lines associated with diff marks. This is essentially how the GNU `diff` tool works as well, in some of its modes.

First, let's adapt our implementation, so that it can carry some metadata alongside the actual content that's being compared. Naturally, the associated number with a given line in a file constitutes a handy bit of metadata that we wouldn't mind having around.

```roc
Line := { lineNumber : U64, content : Str } implements [Eq { isEq: areLinesEqual }]
DiffOp : [Insertion, Deletion, Match]
DiffLine : { op : DiffOp, source : Line, target : Line }
Diff : List DiffLine

areLinesEqual : Line, Line -> Bool
areLinesEqual = \@Line { content: x }, @Line { content: y } -> x == y

beginningMark = @Line { lineNumber: 0, content: "ε" }

toLines : List Str -> List Line
toLines = \list ->
    List.mapWithIndex list \elem, idx -> @Line {
            lineNumber: idx + 1,
            content: elem,
        }
```

We define a `Diff` to be a list of `DiffLines`, with each of the latter being a record consisting of a `DiffOp` and the source and target `Line`s, with respect to which the diff op is applied. These definitions also enable us to generalize our `diffHelp` function to `Line`s instead of just `Str`s:
```roc
diff : List Str, List Str -> Diff
...
diffHelp : Table, List Line, List Line, U64, U64 -> Diff
...
    if i > 0 && j > 0 && xi == yj then
        List.append (diffHelp lcs x y (i - 1) (j - 1)) { op: Match, source: xi, target: yj }
    else if j > 0 && (i == 0 || left >= up) then
        List.append (diffHelp lcs x y i (j - 1)) { op: Insertion, source: xi, target: yj }
    else if i > 0 && (j == 0 || left < up) then
        List.append (diffHelp lcs x y (i - 1) j) { op: Deletion, source: xi, target: yj }

```

Since our `diff` method is a bit more abstract in that it returns a `Diff`, we need a means for actually converting the latter to a list of strings which could then be readily output as necessary.

```roc
diffFormat : List Str, List Str -> List Str
diffFormat = \x, y ->
    diff x y |> formatDiff

formatDiff : Diff -> List Str
```

Thus, we defer text colorizing to the `formatDiff` function where, based on the value of `DiffOp`, colors are applied to the `content` value of a `Line`. Further, `diffFormat` becomes our highest-level function, in terms of abstraction. Basically, it computes the diff and then formats it accordingly, for the purpose of readability. It takes two list of strings as input and returns another list of strings, corresponding to the diff of the former. The distinction between `formatDiff` and `diffFormat` is that the former is an auxiliary function which applies formatting to a diff, and the latter is our end-to-end function which computes a diff and then applies formatting.

The body of the `formatDiff` function is as follows:
```roc
formatDiff = \diffResult ->
    List.map diffResult \elem ->
        (_, source) = unpackLine elem.source
        (_, target) = unpackLine elem.target

        when elem.op is
            Match -> "  $(source)"
            Insertion -> colorizeText GreenFg "+ $(target)"
            Deletion -> colorizeText RedFg "- $(source)"

unpackLine : Line -> (U64, Str)
unpackLine = \@Line { lineNumber, content } -> (lineNumber, content)
```

Going back to the primary direction of this section, we observe that the `toLines` function enables us to annotate an entire file with the corresponding line numbers as metadata. The purpose of the latter will be two-fold - enabling us to maintain a sufficient context size, ideally parametrizable; and also serving as an indicator of where in the corresponding files this context occurs. As you saw in the intro section, it is precisely this type of context which `diff -u` includes in its output.

```bash
$ man diff
DIFF(1)

NAME
       diff - compare files line by line

SYNOPSIS
       diff [OPTION]... FILES

DESCRIPTION
       Compare FILES line by line.
...
       -u, -U NUM, --unified[=NUM]
              output NUM (default 3) lines of unified context
```

A quick reference to the `man` page of GNU `diff` indicates that the unified format comes with an optional argument which denotes the size of the associated context, in terms of number of lines. This is a perfectly reasonable functionality to include into our tool as well. Let's define a record with optional fields to allow as to format our diff accordingly.

```roc
DiffParameters : { colorize ? Bool, contextSize ? U64 }
```

Now, we are ready pass this as the first argument of our `diffFormat` and `formatDiff` functions. For convenience, we'll refactor the latter into a primary function and its auxiliary counterpart, `formatDiffHelp`:
```roc
diffFormat : DiffParameters, List Str, List Str -> List Str
diffFormat = \params, x, y ->
    formatDiff params (diff x y)

formatDiff : DiffParameters, Diff -> List Str
formatDiff = \params, input ->
    formatDiffHelp params input

formatDiffHelp : DiffParameters, Diff -> List Str
formatDiffHelp = \{ colorize ? Bool.false, contextSize ? 3 }, diffResult ->
    List.map diffResult \elem ->
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
```

We weave our parameters record through the chain of calls, which are responsible for formatting the diff, and utilize the parameter values as needed. We've made use of the `colorize` parameter and, thus, enable the user to opt in to a colorized diff representation. We can now proceed to filtering only the lines which correspond to insertion and deletion operations, and all lines up to `contextSize` on either side. This means that we're going to only show as many as `2 * contextSize` matching lines, between any two non-empty, contiguous segments, consisting of zero or more insertion operations, and zero or more deletion ones.

```roc
filterDiff : Diff, U64 -> Diff
filterDiff = \diffResult, contextSize ->
    ranges = filterDiffHelp diffResult contextSize
    List.walk ranges [] \updated, (first, last) ->
        List.concat updated (slice diffResult first last)

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
```

We employ two auxiliary functions in `filterDiffHelp`, and they're defined as follows:
```roc
slice : List elem, U64, U64 -> List elem
slice = \list, fromInclusive, untilInclusive ->
    List.sublist list { start: fromInclusive, len: 1 + untilInclusive - fromInclusive }

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
```

We proceed with utilizing the newly-implemented context-filtering functionality:
```roc
formatDiffHelp = \{ colorize ? Bool.false, contextSize ? 3 }, diffResult ->
    filterDiff diffResult contextSize
    |> List.map \elem ->
...
```

The resulting implementation is almost equivalent to GNU `diff`'s unified format, with the only difference that the absolute line numbers and diff block sizes aren't displayed. The latter are actually referred to as _hunks_.

Let's actually get to completing the implementation of our unified format output in the following section.

## Section N.5: Unified Format
```
TODO: Code and narrative.
```

## Section N.6: Putting It All Together
In order to be able to employ our diff functionality in the real world, we'll need to promote it to an executable, which we'll then run against arbitrary input files.
Let's create a file called `main.roc` and import the exposed `diffFormat` function, which will do all the associated heavy-lifting.

```roc
app "diff"
    packages {
        cli: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br",
    }
    imports [
        cli.Stdout,
        cli.Stderr,
        cli.Arg,
        cli.Task.{ Task, await },
        cli.File,
        cli.Path,
        Lcs.{ diffFormat },
    ]
    provides [main] to cli
```

We're going to base our diff tool on the `basic-cli` platform, which - as its name aptly suggests - provides all key ingredients that we need for our task. Correspondingly, we're importing a few of its features, so that we can write text to standard output and standard error streams, as well as read command-line arguments and perform file reading operations.

```
$ roc build main.roc --output rocdiff
0 errors and 0 warnings found in 522 ms
 while successfully building:

    rocdiff
```

Now that we have the freshly minted `rocdiff` executable in our local directory, it's time for an actual test:
```diff
$ ./rocdiff Hello.roc HelloWorld.roc
- app "hello"
+ app "hello-world"
      packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.9.1/y_Ww7a2_ZGjp0ZTt9Y_pNdSqqMRdMLzHMKfdN8LWidk.tar.br" }
      imports [pf.Stdout]
      provides [main] to pf

  main =
-     Stdout.line "Hello!"
+     Stdout.line "Hello, World!"

```

Nice! We've got the expected output.

Any external tool can be used as a `git diftool`, and so can our own `rocdiff`. You can run the following in any directory, associated with a `git` repository:
```bash
$ git difftool --extcmd=<full_rocdiff_path>

Viewing (1/<total_number_of_changed_files>): '<changed_file_path>'
Launch '<path_to_rocdiff>' [Y/n]?
```

Just as `git diff`, it'll show all unstaged differences. Please, note that `git difftool`, regardless of what the external tool is, behaves slightly differently and asks for confirmation regarding launching the corresponding diff tool, with respect to each changed file.

If you don't have any outstanding unstaged changes, you could, for instance, view the diff between any arbitrary two commits. For example, `HEAD~..HEAD` will show you the most recent commit:
```bash
$ git difftool --extcmd=`realpath ./rocdiff` HEAD~..HEAD
```

The above will only utilize our diff tool on a one-off basis. If we want this to apply to an entire repository, we could add the following to the `.git/config` file of the repository in question:
```ini
[diff]
    tool = rocdiff

[difftool "rocdiff"]
    cmd = <full_rocdiff_path> "$LOCAL" "$REMOTE"
```
The `[difftool "rocdiff"]` section defines our `rocdiff` tool within the context of `git difftool` so that our tool may be referenced from within that context. The `[diff]` section sets the actual `git difftool` to `rocdiff`, based on said definition. Please, ensure that you replace `<full_rocdiff_path>` with the actual full absolute path to the `rocdiff` executable on your local machine.

Further, note that, if you've already got an existing `tool` set in the `[diff]` section, you'll have to either remove the existing section, comment it out, or just add the new `[diff]` section, containing `tool = rocdiff`, after all other pre-existing `[diff]` sections. This is necessary, because `git difftool` will only take only the last one into account.

Please, note that any supported `rocdiff` command-line arguments may be specified as well.

Alternatively, the above could be set from the command line, with respect to the local repository, assuming we've already navigated to it:
```
git config diff.tool rocdiff
git config difftool.rocdiff.cmd "<full_rocdiff_path> \$LOCAL \$REMOTE"
```

Adding the `--global` flag after `git config` applies the equivalent changes globally and, this way, the configured `difftool` can be utilized in any `git` repository on the same host, and the same user, with respect to which the `git config` operation applies; i.e., this is the user whose `${HOME}/.gitconfig` gets edited as a result. Just as in the local repository case discussed above, equivalent edits to the global (with respect to a given user) `.gitconfig` file are going to result in the same behaviour, as the resulting behaviour from `git config --global`.

Now, regardless of whether we've opted to modify the local or global `git` config, our default `difftool` is set to `rocdiff` and can be invoked directly as follows:
```bash
$ git difftool
```

Just as above - and as in the case of `git diff` itself - an arbitrary diff range could be specified. In case there are no unstaged changes in the current `git` repository, the most recent commit, if one exists, could be shown as follows:
```bash
$ git difftool HEAD~..HEAD
```

If at any point, you'd like to switch back to your previous configuration, you can just delete or comment out the `rocdiff` section which sets `tool = rocdiff` from your `git` config, as necessary:
```ini
#[diff]
#    tool = rocdiff
```

The `[difftool "rocdiff"]` definition section does not have to be removed.

Please, note that `git difftool` and `git diff` are completely distinct operations.

```
TODO
Reference:
http://git-scm.com/docs/gitattributes#_defining_an_external_diff_driver
```

```
TODO
GIT_EXTERNAL_DIFF=...
```

```
TODO
$ cat .git/config
...
[diff "rocdiff"]
    command = <full_rocdiff_path> "$LOCAL" "$REMOTE"

$ cat .gitattributes
* diff=rocdiff

$ git diff --ext-diff
```

```TODO
$ man git
...
       GIT_EXTERNAL_DIFF
           When the environment variable GIT_EXTERNAL_DIFF is set, the program named by it is called, instead of the diff invocation described above. For a path that is added, removed, or modified, GIT_EXTERNAL_DIFF is called with 7 parameters:

               path old-file old-hex old-mode new-file new-hex new-mode

           where:

       <old|new>-file
           are files GIT_EXTERNAL_DIFF can use to read the contents of <old|new>,

       <old|new>-hex
           are the 40-hexdigit SHA-1 hashes,

       <old|new>-mode
           are the octal representation of the file modes.

           The file parameters can point at the user’s working file (e.g.  new-file in "git-diff-files"), /dev/null (e.g.  old-file when a new file is added), or a temporary file (e.g.  old-file in the index).  GIT_EXTERNAL_DIFF should not worry about unlinking the temporary file --- it is removed when
           GIT_EXTERNAL_DIFF exits.

           For a path that is unmerged, GIT_EXTERNAL_DIFF is called with 1 parameter, <path>.

           For each path GIT_EXTERNAL_DIFF is called, two environment variables, GIT_DIFF_PATH_COUNTER and GIT_DIFF_PATH_TOTAL are set.
...


$ man git-config
...
       diff.external
           If this config variable is set, diff generation is not performed using the internal diff machinery, but using the given command. Can be overridden with the ‘GIT_EXTERNAL_DIFF’ environment variable. The command is called with parameters as described under "git Diffs" in git(1). Note: if you want to
           use an external diff program only on a subset of your files, you might want to use gitattributes(5) instead.

...
```

```TODO
$ git diff
['diff/index.md', '/tmp/git-blob-pOomA2/index.md', '74124a8f9bb1da280a7b7ba2e3080ed76e04993f', '100644', 'diff/index.md', '0000000000000000000000000000000000000000', '100644']
['diff/src/Lcs.roc', '/tmp/git-blob-DcMCZi/Lcs.roc', 'e2fc3001a10a1390c1cbab7f69d7a699b1117633', '100644', 'diff/src/Lcs.roc', '0000000000000000000000000000000000000000', '100644']
```

## Section N.7: Summary

[Figure N.M](#figure-n-m-summary) summarizes the key ideas introduced in this chapter.

<p align="center">
<a id="figure-n-m-summary"><img src="" alt="TODO: Add image." /></a><br />
Figure N.M: A diff tool concept map.
</p>

## Section N.8: Exercises

### Color Themes

Produce colorized output in correspondence to different pre-set themes, with the theme name of choice specified as an optional command-line argument, and assuming a default value otherwise.

### Diff Formats
Output other diff formats, such as the context format, normal format, `ed` format, RCS format, side-by-side format, line-group format and if-then-else format. Just as the behaviour of the GNU `diff` tool, the desired one could be specified as an optional command-line argument, assuming a default value otherwise.
