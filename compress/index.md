---
---

# Notes
- I don't forsee this code needing to depend on any other chapters or libraries.
- I have an implementation that mostly works, but there are some bugs that need to be ironed out.

# Outline
## Intro
- Compression is extremely useful.
- It is used in many domains like web servers, file storage, etc.
- One ubiquitous compression tool is GZIP.
- One of the core components of GZIP is the LZ77 compression algorithm.
- LZ77 is simple yet powerful.
- We will implement LZ77 in this chapter.

## LZ77
- LZ77 is a sliding window algorithm.
- There is a search buffer and a lookahead buffer. The search buffer contains the bytes that will be searched for matches and the lookahead buffer is the piece of data currently being compressed.
- When the beginning of the look ahead buffer matches a segment of bytes somewhere in the search buffer, the lookahead buffer will be "slid" to exclude the match.
- The match can then be represented as three values: the offset to locate the match in the search buffer, the length of the match, and the next character following the match.
- This triple will then be appended to the compressed output so far. 
- When the beginning of the look ahead buffer does not match anything in the search buffer, the offset and length will both be 0 and only the next character will be used.
- We will use a direct encoding of the triples into bytes. Note that this is not super space efficient, and is where Huffman Coding comes in.

## Sliding
- The sliding window aspect of this algorithm means that it is possible to do streaming of both encoding and decoding. We will not do this in our implementation however.

## Roc Details
- First we will implement encoding to a list of triples followed by decoding into the original input.
- We can test the algorithm by encoding and decoding the same input and then validating that the result equals the original input.
- We can then implement encoding the list of triples to a list of bytes and the decoding of bytes into triples. (Or maybe this should all be done in one pass in the end for performance?)
