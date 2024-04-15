app "task-usage" packages { 
        cli: "https://github.com/roc-lang/basic-cli/releases/download/0.8.1/x8URkvfyi9I0QhmVG98roKBUs_AZRkLFwFJVJ3942YA.tar.br"
    }
    imports [
        cli.Stdout,
        cli.File,
        cli.Task,
        cli.Path,
        cli.Utc,
    ]
    provides [ main ] to cli

# TODO: write sugary version

log = \msg, val ->
    path = Path.fromStr "logFile"
    Task.await Utc.now \now ->
        millis = Utc.toMillisSinceEpoch now
        seconds = Num.round (Num.toFrac millis / Num.toFrac 1000)
        time = Num.toStr seconds
        appendToFile path "$(time) $(msg): $(Inspect.toStr val)\n"

# TODO: figure out type annotation, and its pertinence for this iteration
# appendToFile : Path, Str -> Task {} [FileReadErr Path.Path InternalFile.ReadErr, FileWriteErr Path.Path InternalFile.WriteErr]
appendToFile = \path, msg ->
    newBytes = Str.toUtf8 msg
    Task.await (File.readBytes path) \existingBytes ->
        File.writeBytes path (List.concat newBytes existingBytes)

main =
    Task.onErr
        (log "This is a value:" 42)
        handleErr

handleErr = \err ->
    Stdout.line "We found an error: $(Inspect.toStr err)"