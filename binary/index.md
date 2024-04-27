---
---

# Binary

Roc provides the ability to encode and decode values, which allows us to transform an arbitrary Roc value into a `List U8` and back. 
This `List U8` can be of any type, including string-based formats such as JSON or XML, or any binary format.
This is beneficial for saving data to disk, sending data over a network, or any other situation where we require the conversion of a value to a sequence of bytes.
This chapter will focus on binary data and the encoding and decoding of such data by inventing our own binary format.

## Binary representation of int
- roc has different int types I64, U8 etc..
- signed represented with two's complement
- Bitwise operations (explanation for all, or just the ones required here?)
- Code `U32 -> (U8, U8, U8, U8)`
- Code `(U8, U8, U8, U8) -> U32`
- Endianness
- We know how long each item is, so we can just put them one after the other.

## Float
- Explain sign, exponent, and fraction
- Roc has `f32ToParts` and `f32FromParts`
- code: `f32Parts -> (U8, U8, U8, U8)`
- code: `(U8, U8, U8, U8) -> f32Parts`

## Dec
- is the default in roc, which is uncommon
- fixed point with 10^18 decimal places
- internal I128
- roc has `withDecimalPoint` and `withoutDecimalPoint`
- De/Encoding for I128 can be reused for Dec

## Strings
- ASCII
- Unicode
- Utf8
- Roc has always utf8 strings
- Zero terminating (How to know when a string ends)

## Lists
- First try: Just encode the items one after the other
- Problem: How to know how many items there are when decoding?
- Solution: Prefix the list with the number of items

## Records
- Like lists we need to know the number of fields
- Also the name of the field has to be encoded


## More detailed Explanation of Encoding & Decoding Abilities (only if chapter is get's not to long)
- 