# Outline
**Note:** This is only for reference. To be removed upon finalising a first full draft of the content.

- A brief intro to the [longest common subsequence](https://en.wikipedia.org/wiki/Longest_common_subsequence#Print_the_diff) (LCS) algorithm and its applications.
- Building visual intuition about the workings of the algorithm via toy examples (a couple of examples quintessentially using DNA base-pair sequences).
  - Discussing algorithm design choices that make up a visually "good" diff output in practice.
- Implementing a textbook Roc version of the LCS algorithm.
- Incrementally introducing enhancements to the implementation, targeted towards using it more effectively as a `diff` tool.
  - This gives the opportunity to discuss Roc-specific concepts such as:
    - Abilities such as `Eq` and `Hash`.
      - The discussion will touch upon the fact the LCS algorithm can be applied to arbitrary homogeneous sequences of elements of any type, as long as the elements of the underlying type can be compared for equality against each other.
    - Records and associated syntax.
      - This will be useful for customising the tool, for instance:
        - Collapsing long sections of matching sequences (this can be parametrised by length).
        - Colourising the output (different colour schemes may apply).
- Employing the implemented tool as a `git diff` tool.
- Discussing and implementing optimisations such as operating on "compressed" versions of the elements such as hashes and lengths.
- Discussing the connecting points from a `diff` tool to the ability of merging branches in a version-control system context, via the 3-way merge algorithm.

## In scope, if time permits

**Note:** By time, it is meant time from a reader's perspective, in terms of the generally-agreed-upon reader persona and the associated allotted time-per-chapter guideline.

- Improving the implementation, so that the output format - besides basic markers for insertions and deletions - conforms to one of the common `diff` format [specifications](https://www.math.utah.edu/docs/info/diff_3.html).
- An overview and perhaps implementation of algorithms used by `git diff` and/or other industry-standard tools and their juxtaposition with the LCS algorithm.

## Out of scope
- Version-control system concepts beyond the scope of `diff`-ing files and prerequisites for merging and identifying merge conflicts.
