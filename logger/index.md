---
---

This chapter goes through the building of a simple logging library with the following capabilities:

- Log level filtering
- Multiple channels (stderr, append to file)
- JSON encoding
- Ability to use multiple logging configurations in the same program
- Logger configuration through environment vars

## Chapter structure

The chapter follows a _challenge and response_ pattern. The first iteration builds the simplest logger imaginable (just write to stdout) and each iteration improves on the previous one. After each implementation, its downsides are commented, and the next set of improvements are outlined.

After the final implementation, a recap of the iterations, and the concepts that were explained in each of them, is offered.

_NOTE: On each of the iterations below, I'll list some concepts that could be explained using the iteration code._

_The list is offered as a suggestion: whether we actually flesh out those concepts in this chapter or not will depend on the editorial decisions on chapter ordering and interdependence._

### 0. Minimum viable logger

An extremely simple, single-function "logger" that takes simple arguments (A message and a value) and outputs to Stdout.

This iteration is only pertinent if the chapter introduces the concept of platform. It may be overkill in terms of paring down the first iteration.

``` roc
main =
    log "This is a value:" 42
    
log = \msg, val ->
    Stdout.line "$(msg): $(Inspect.toStr val)"
```

_Concepts_:

- Capabilities defined by platform
- Importing from platform

### 1. Append to file

At the end of this iteration, the logger:

- Is composed by just a couple of functions in the main file (no library)
- Appends to a file
- Includes timestamps
- Has a hardcoded output path
- Needs the log file to be created manually

The idea behind its simplicity is to have the least amount of moving parts possible, so we can explore tasks, error handling, and the syntax around them in detail, without the burden of a larger program.

I would like to present the code for this iteration with / without syntax sugar, and take steps to guide the reader to make the connection between type annotations in the documentation, the function calls without syntactic sugar, and the code with sugar.


_Concepts_:

- Task
- Error handling
- Using Inspect
- Backpassing syntax
- Pipe syntax (first pass, simplest case, `f |> a`)
- Reading type annotations

### 2. A usable library

This iteration is a small step from the previous one in terms of complexity of the logger. It mostly expands on the previous one as a reinforcement.

An important step is that the logger becomes a module, and a more realistic use case is presented.

At the end of this iteration, the logger:

- Becomes a module
- Handles log file creation
- Handles permission errors
- Takes a configuration record as argument (which makes it possible to have multiple channels)
- Reads configuration overrides from environment variables

_Concepts_:

- Modules
- Types (configuration record)

### 3. Log level

This iteration adds JSON encoding and log level configuration.

_NOTE_: JSON encoding would depend on [roc-json](https://github.com/lukewilliamboswell/roc-json). If the library is too much, we can do something like rudimentary CSV without escaping or headers: just join a list with commas.

_Concepts_:

- Tags and payloads
- Pattern matching