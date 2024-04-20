---
---

This chapter builds a small suite of random generation tools on top of
32-bit pseudo-random number generators. It covers passing state in
immutable programs, detailed integer arithmetic, and opaque types.

Except where otherwise noted, I've got working code for all of these sections.

## Outline

* RNGs in Roc
  * What RNGs are used for; PRNs vs. CSRNGs
  * How RNGs are commonly implemented (e.g. in Python or JavaScript)
  * Why that doesn't work in Roc, and what to do instead
  * [PRNG.roc][PRNG.roc]: Defining an interface for a PRNG
* Building on top of `PRNG`
  * [TestGenerators.roc][TestGenerators.roc]: Not actually random, but let us test these tools generically
  * [RandomTools.roc][RandomTools.roc]: Building on top of a U32 generator
  * These are implemented:
    * Generating lists
    * Generating `U64`s
    * Generating numbers in a range; modulo bias
    * Shuffling
  * And I could add and talk about as many of these as we have time/space for
    * Sampling from a list with and without replacement
    * Generating floating point numbers
    * Rejection sampling (generating values that follow an arbitrary distribution)
  * This chapter is/would be mostly implemented in terms of
    quite concrete recursive functions and `List.walk`
* RANDU: a bad PRNG
  * Disclaimer: this RNG is deeply flawed, but we're going to implement it anyways
  * Formula
  * [RANDU.roc][RANDU.roc]: a bad PRNG
    * RNG state as an opaque type
    * Checked vs. Saturating vs. Wrapping arithmetic
* Demonstrating RANDU's badness:
  * [generatePointsRANDU.roc][generatePointsRANDU.roc]: A program to generate points in 3d space
  * Visualization of these points: they're organized, and not very random!
* PCG: A better PRNG
  * Point to [roc-random](https://github.com/JanCVanB/roc-random), a more
    robust (but more complicated) implementation of PCG
  * PCG.roc: a simple implementation of PCG
    * Bit-shifting, Xor
* Demonstrating PCG's superiority and the utility of shared types
  * [generatePointsPCG.roc][generatePointsPCG.roc]: A program to generate points in 3d space
    * Because we have a shared interface for RNGs, this is basically
      the same as [generatePointsRANDU.roc][generatePointsRANDU.roc]
  * Visualization these points; they're very random
  * Note that we don't actually _need_ [PRNG.roc][PRNG.roc] as long as our RNGs have have
    the same type signature (though it's helpful to have it written down;
    deleting PRNG.roc and making the code run is left as an exercise to the
    reader)

[PRNG.roc]: ./PRNG.roc
[TestGenerators.roc]: ./TestGenerators.roc
[RandomTools.roc]: ./RandomTools.roc
[RANDU.roc]: ./RANDU.roc
[generatePointsRANDU.roc]: ./generatePointsRANDU.roc
[generatePointsPCG.roc]: ./generatePointsPCG.roc
